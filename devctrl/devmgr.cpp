#include "stdafx.h"
#include "devctrl.h"
#include "devmgr.h"

#define CACHE_SIZE 10240

map<int, CDeviceManager*> CDeviceManager::devmgrs;


DWORD WINAPI ReceivDataProc(void* param)
{
    CDeviceManager* pMgr = (CDeviceManager*)param;

    return pMgr->ReceiveDataProc();
}

CDeviceManager::CDeviceManager(const UFD_DEVINFO& dev)
{
    m_device = dev;
    m_waveRawSize = 0;
    m_waveSize = 0;
    m_compressRate = 1;
    m_bufferWaveCount = 0;
    m_bufferCount = 0;
    m_buffer = NULL;
    m_tailBuffer = NULL;
    m_bufferUsed = FALSE;
    m_cache = new unsigned char[CACHE_SIZE];
    m_hPacketEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
    m_mtxBufferList = CreateMutex(NULL, FALSE, NULL);
    m_mtxSendCommand = CreateMutex(NULL, FALSE, NULL);
    m_evtCommandRsp = CreateEvent(NULL, FALSE, FALSE, NULL);
    m_curCmd = 0;
    m_curCmdRsp = 0;
    m_aboradCapture = FALSE;

    m_hThread = CreateThread(NULL, 0, ::ReceivDataProc, this, CREATE_SUSPENDED, &m_dwThreadID);
    SetThreadPriority(m_hThread, THREAD_PRIORITY_TIME_CRITICAL);
    ResumeThread(m_hThread);
}

CDeviceManager::~CDeviceManager()
{
    delete m_cache;
}

void CDeviceManager::EnumerateDevices(list<int>& devIDs)
{
    for (map<int, CDeviceManager*>::iterator it = devmgrs.begin(); it != devmgrs.end(); ++it)
    {
        devIDs.push_back(it->second->GetDeviceID());
    }
}

void CDeviceManager::EnumerateDevices()
{
    if (devmgrs.size() > 0)
        return;

    int devID = 1;

    CCyUSBDevice* usbdev = new CCyUSBDevice(NULL, CYUSBDRV_GUID, true);
    CCyUSBEndPoint* inEndPoint = usbdev->BulkInEndPt;
    CCyUSBEndPoint* outEndPoint = usbdev->BulkOutEndPt;

    usbdev->Reset();

    if (outEndPoint != NULL && inEndPoint != NULL)
    {
        UFD_DEVINFO dev;
        dev.devID = devID;
        dev.protType = UFD_USB;
        dev.devIP = 0;
        dev.usbDev.dev = usbdev;
        dev.usbDev.inEndPoint = inEndPoint;
        dev.usbDev.outEndPoint = outEndPoint;

        inEndPoint->TimeOut = 100;
        outEndPoint->TimeOut = 100;

        CDeviceManager* mgr = new CDeviceManager(dev);
        devmgrs[devID] = mgr;

        devID = devID + 1;
    }
}

CDeviceManager* CDeviceManager::GetManagerByDeviceID(int devID)
{
    map<int, CDeviceManager*>::iterator itFind = devmgrs.find(devID);

    if (itFind == devmgrs.end())
        return NULL;

    return itFind->second;
}

int CDeviceManager::GetDeviceID()
{
    return m_device.devID;
}

int CDeviceManager::StartDevice()
{
    ResetBuffer();
    return SendCommand(1, 0);
}

int CDeviceManager::StopDevice()
{
    return SendCommand(2, 0);
}

int CDeviceManager::SetWaveParam(int rawSize, int rate)
{
    m_waveRawSize = rawSize;
    m_waveSize = rawSize / rate;
    m_compressRate = rate;

    unsigned int param = (rawSize & 0xFFFF) | ((rate & 0xFFFF) << 16);

    SendCommand(CMD_SET_WAVE_SIZE, param);

    return 0;
}

int CDeviceManager::WaitWavePacket(unsigned char** pBuffer, DWORD timeout)
{
    DWORD ret = WaitForSingleObject(m_hPacketEvent, timeout);

    if (WAIT_TIMEOUT == ret)
        return ApiWaitTimeout;

    *pBuffer = m_pktBuffer;
    return 0;
}

DWORD CDeviceManager::ReceiveDataProc()
{
    int len;
    PUFD_BUFFER buffer;

    while (true)
    {
        if (UFD_USB == m_device.protType)
            len = ReceiveDataUSB();
        else
            len = ReceiveDataEth();

        if (len < 6)
        {
            continue;
        }

        if (len < 10)
        {
            unsigned short cmd = ((unsigned short*)m_cache)[0];
            unsigned short cmd_ = ~((unsigned short*)m_cache)[1];
            unsigned short rsp = ((unsigned short*)m_cache)[2];

            if (cmd == cmd_)
            {
                if (cmd == m_curCmd)
                {
                    m_curCmdRsp = rsp;
                    SetEvent(m_evtCommandRsp);
                }
            }

            continue;
        }

        if (NULL != (buffer = GetUsedBuffer()))
        //if (m_waveSize==len)
        {
            int cacheleft = len;

            while (true)
            {
                int bufleft = buffer->length - buffer->current;
                int cpylen = cacheleft > bufleft ? bufleft : cacheleft;
                unsigned char* start = &buffer->buffer[buffer->current];

                memcpy(start, m_cache, cpylen);
                cacheleft -= cpylen;
                buffer->current += cpylen;

                if (cacheleft > 0)
                {
                    buffer = PostBuffer();
                    if (!buffer)
                        break;
                }
                else if (buffer->current == buffer->length)
                {
                    PostBuffer();
                    break;
                }
                else
                {
                    break;
                }
            }
        }

        ReturnUsedBuffer();
    }

    return 0;
}

int CDeviceManager::ReceiveDataUSB()
{
    LONG lenBytes = CACHE_SIZE;
    bool ret = m_device.usbDev.inEndPoint->XferData(m_cache, lenBytes);

    if (!ret)
        return ApiRecveUSBDataFailed;

    return lenBytes;
}

int CDeviceManager::ReceiveDataEth()
{
    return 0;
}

int CDeviceManager::SendCommand(unsigned short cmd, unsigned int param)
{
    WaitForSingleObject(m_mtxSendCommand, INFINITE);

    m_curCmd = cmd;

    unsigned short cmdl[] = { cmd, ~cmd, LOWORD(param), HIWORD(param) };

    int ret = SendData((unsigned char*)cmdl, 8);

    if (ret > 0)
    {
        DWORD rsp = WaitForSingleObject(m_evtCommandRsp, 1000);
        if (WAIT_TIMEOUT == rsp)
            ret = ApiWaitDeviceRspTimeOut;
        else
        {
            ret = m_curCmdRsp;
        }
    }

    ReleaseMutex(m_mtxSendCommand);

    return ret;
}

int CDeviceManager::SendData(unsigned char* buffer, int len)
{
    if (UFD_USB == m_device.protType)
        return SendDataUSB(buffer, len);
    else
        return SendDataEth(buffer, len);
}

int CDeviceManager::SendDataUSB(unsigned char* buffer, int len)
{
    LONG lenBytes = len;

    bool ret = m_device.usbDev.outEndPoint->XferData(buffer, lenBytes);

    if (!ret)
        return ApiSendUSBDataFailed;

    return lenBytes;
}

int CDeviceManager::SendDataEth(unsigned char* buffer, int len)
{
    return 0;
}

void CDeviceManager::AddBuffer(unsigned char* buffer, int length)
{
    if (!buffer)
        return;

    PUFD_BUFFER ubuf = new UFD_BUFFER(buffer, length);

    WaitForSingleObject(m_mtxBufferList, INFINITE);

    if (NULL == m_buffer)
    {
        m_buffer = ubuf;
        m_tailBuffer = ubuf;
        m_buffer->next = NULL;
    }
    else
    {
        m_tailBuffer->next = ubuf;
        m_tailBuffer = ubuf;
    }

    ReleaseMutex(m_mtxBufferList);
}

PUFD_BUFFER CDeviceManager::PostBuffer()
{
    if (m_aboradCapture)
        return NULL;

    WaitForSingleObject(m_mtxBufferList, INFINITE);

    if (NULL != m_buffer)
    {
        m_pktBuffer = m_buffer->buffer;
        SetEvent(m_hPacketEvent);

        PUFD_BUFFER tmp = m_buffer;
        m_buffer = m_buffer->next;
        if (NULL == m_buffer)
            m_tailBuffer = NULL;

        delete tmp;
    }

    ReleaseMutex(m_mtxBufferList);

    return m_buffer;
}

void CDeviceManager::ResetBuffer()
{
    if (NULL != m_buffer)
    {
        m_buffer->current = 0;
    }
}

void CDeviceManager::DeleteAllBuffer()
{
    long used = TRUE;

    do {
        Sleep(1);
        used = InterlockedCompareExchange(&m_bufferUsed, TRUE, FALSE);
    } while (used);


    WaitForSingleObject(m_mtxBufferList, INFINITE);

    if (NULL != m_buffer)
    {
        PUFD_BUFFER cur = m_buffer;

        while (cur)
        {
            PUFD_BUFFER tmp = cur;
            cur = cur->next;
            delete tmp;
        }

        m_buffer = NULL;
        m_tailBuffer = NULL;
    }

    ReleaseMutex(m_mtxBufferList);


    InterlockedExchange(&m_bufferUsed, FALSE);
}

int CDeviceManager::StartCapture()
{
    InterlockedExchange(&m_aboradCapture, FALSE);

    return 0;
}

int CDeviceManager::StopCapture()
{
    InterlockedExchange(&m_aboradCapture, TRUE);
    ResetBuffer();
    return 0;
}

PUFD_BUFFER CDeviceManager::GetUsedBuffer()
{
    if (m_aboradCapture)
        return NULL;

    long used = InterlockedCompareExchange(&m_bufferUsed, TRUE, FALSE);
    
    if (!used)
        return m_buffer;

    return NULL;
}

void CDeviceManager::ReturnUsedBuffer()
{
    InterlockedExchange(&m_bufferUsed, FALSE);
}
