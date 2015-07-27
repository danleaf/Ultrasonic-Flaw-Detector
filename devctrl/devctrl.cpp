// devctrl.cpp : 定义 DLL 应用程序的导出函数。
//

#include "stdafx.h"
#include "devctrl.h"
#include "defines.h"
#include <assert.h>

map<U32, CDeviceManager*> devmgrs;

DWORD WINAPI ReceivDataProc(void* param)
{
    CDeviceManager* pMgr = (CDeviceManager*)param;

    return pMgr->ReceiveDataProc();
}

BOOL __stdcall EnumerateDevices(int *devIDs, int *devCount)
{
    if (devCount == 0)
        return TRUE;

    int devID = 0;

    CCyUSBDevice* usbdev = new CCyUSBDevice(NULL, CYUSBDRV_GUID, true);
    CCyUSBEndPoint* inEndPoint = usbdev->BulkInEndPt;
    CCyUSBEndPoint* outEndPoint = usbdev->BulkOutEndPt;
   
    usbdev->Reset();
    /*CCyUSBEndPoint* inEndPoint = NULL;
    CCyUSBEndPoint* outEndPoint = NULL;

    usbdev->SetAltIntfc(0);


    int eptCnt = usbdev->EndPointCount();

    for (int e = 1; e < eptCnt; e++)
    {
        CCyUSBEndPoint *ept = usbdev->EndPoints[e];
        if (ept->Address == 0x2)
            outEndPoint = ept;
        if (ept->Address == 0x86)
            inEndPoint = ept;
    }*/


    if (outEndPoint != NULL && inEndPoint != NULL)
    {
        UFD_DEVINFO dev;
        dev.devID = devID;
        dev.protType = UFD_USB;
        dev.devIP = 0;
        dev.usbDev.dev = usbdev;
        dev.usbDev.inEndPoint = inEndPoint;
        dev.usbDev.outEndPoint = outEndPoint;

        devIDs[devID] = devID;
        CDeviceManager* mgr = new CDeviceManager(dev);
        devmgrs[devID] = mgr;


        devID = devID + 1;
    }

    if (devID == 0)
        return FALSE;

    *devCount = devID;

    return TRUE;
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
    m_currBuffer = NULL;
    m_currWaveInBuffer = 0;
    m_cache = new unsigned char[CACHE_SIZE];
    m_hPacketEvent = CreateEvent(NULL, FALSE, FALSE, NULL);

    m_hThread = CreateThread(NULL, 0, ::ReceivDataProc, this, CREATE_SUSPENDED, &m_dwThreadID);
    SetThreadPriority(m_hThread, 31);
    ResumeThread(m_hThread);
}

CDeviceManager::~CDeviceManager()
{
    DeleteBuffer();

    delete m_cache;
}

int CDeviceManager::StartDevice()
{
    return 0;
}

int CDeviceManager::StopDevice()
{
    return 0;
}

int CDeviceManager::SetWaveParam(int rawSize, int rate)
{
    m_waveRawSize = rawSize;
    m_waveSize = rawSize / rate;
    m_compressRate = rate;

    return 0;
}

int CDeviceManager::SetBuffer(int bufCount, int waveCount)
{
    assert(bufCount > 0);

    DeleteBuffer();

    m_buffer = new UFD_BUFFER;
    m_buffer->buffer.address = new unsigned char[m_waveSize * waveCount];
    m_buffer->reading = FALSE;
    m_buffer->buffer.waveCount = waveCount;
    m_buffer->buffer.waveSize = m_waveSize;

    PUFD_BUFFER old = m_buffer;
    for (int i = 1; i < bufCount; i++)
    {
        PUFD_BUFFER curr = new UFD_BUFFER;
        curr->buffer.address = new unsigned char[m_waveSize * waveCount];
        curr->reading = FALSE;
        curr->buffer.waveCount = waveCount;
        curr->buffer.waveSize = m_waveSize;

        old->next = curr;
        old = curr;
    }

    old->next = m_buffer;

    m_bufferWaveCount = waveCount;
    m_bufferCount = bufCount;
    m_currBuffer = m_buffer;
    m_currWaveInBuffer = 0;

    return 0;
}

int CDeviceManager::SetWaveAndBufferParam(int waveRawSize, int waveRate, int bufCount, int waveCount)
{
    StopDevice();
    //Sleep(100);
    SetWaveParam(waveRawSize, waveRate);
    SetBuffer(bufCount, waveCount);
    StartDevice();

    return 0;
}

void CDeviceManager::DeleteBuffer()
{
    m_bufferWaveCount = 0;
    m_bufferCount = 0;
    m_currBuffer = NULL;
    m_currWaveInBuffer = 0;

    //Sleep(100);

    PUFD_BUFFER curr = m_buffer;

    while (curr)
    {
        PUFD_BUFFER next = curr->next;

        while (curr->reading)
            Sleep(0);

        delete curr->buffer.address;
        delete curr;

        if (next == m_buffer)
            break;

        curr = next;
    }

    m_buffer = NULL;
}

int CDeviceManager::WaitWavePacket(PUFD_BUFFER* pBuffer, DWORD timeout)
{
    DWORD ret = WaitForSingleObject(m_hPacketEvent, timeout);

    if (WAIT_TIMEOUT == ret)
        return -1;

    if (m_readyBuffer->reading)
        return -1;

    m_readyBuffer->InterlockedSetReading();

    *pBuffer = m_readyBuffer;

    return 0;
}

DWORD CDeviceManager::ReceiveDataProc()
{
    int len;

    while (true)
    {
        if (UFD_USB == m_device.protType)
            len = ReceiveDataUSB();
        else
            len = ReceiveDataEth();

        //continue;

        if (len <= 0)
        {
            Sleep(0);
            continue;
        }

        if (NULL != m_currBuffer)
        {
            memcpy(&m_currBuffer->buffer.address[m_currBuffer->buffer.waveSize*m_currWaveInBuffer], \
                m_cache, m_currBuffer->buffer.waveSize);

            m_currWaveInBuffer++;
            if (m_currWaveInBuffer == m_bufferWaveCount)
            {
                m_readyBuffer = m_currBuffer;
                m_currBuffer = m_currBuffer->next;
                m_currWaveInBuffer = 0;
                SetEvent(m_hPacketEvent);
            }
        }
        else
        {
        }
    }

    return len;
}

int CDeviceManager::ReceiveDataUSB()
{
    LONG lenBytes = CACHE_SIZE;

    bool ret = m_device.usbDev.inEndPoint->XferData(m_cache, lenBytes);
        
    if (!ret)
        return -1;

    return lenBytes;
}

int CDeviceManager::ReceiveDataEth()
{
    return 0;
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
        return -1;

    return lenBytes;
}

int CDeviceManager::SendDataEth(unsigned char* buffer, int len)
{
    return 0;
}

int __stdcall SetWaveAndBufferParam(int uDevID, int waveRawSize, int waveRate, int bufCount, int waveCount)
{
    map<U32, CDeviceManager*>::iterator itFind = devmgrs.find(uDevID);

    if (itFind == devmgrs.end())
        return -1;

    itFind->second->SetWaveAndBufferParam(waveRawSize, waveRate, bufCount, waveCount);
    return 0;
}

int __stdcall StartDevice(int uDevID)
{
    map<U32, CDeviceManager*>::iterator itFind = devmgrs.find(uDevID);

    if (itFind == devmgrs.end())
        return -1;

    itFind->second->StartDevice();
    return 0;
}

int __stdcall StopDevice(int uDevID)
{
    map<U32, CDeviceManager*>::iterator itFind = devmgrs.find(uDevID);

    if (itFind == devmgrs.end())
        return -1;

    itFind->second->StopDevice();
    return 0;
}

int __stdcall WaitWavePacket(int uDevID, PWAVBUFFER* pBuffer, unsigned int timeout)
{
    *pBuffer = NULL;

    map<U32, CDeviceManager*>::iterator itFind = devmgrs.find(uDevID);

    if (itFind == devmgrs.end())
        return -1;

    PUFD_BUFFER pUfdBuffer;

    int ret = itFind->second->WaitWavePacket(&pUfdBuffer, timeout);
    if (DEVCTRL_SUCCESS == ret)
    {
        *pBuffer = (PWAVBUFFER)pUfdBuffer;
    }

    return ret;
}

int __stdcall ReleasePacket(int uDevID, PWAVBUFFER pBuffer)
{
    if (pBuffer)
        ((PUFD_BUFFER)pBuffer)->InterlockedUnSetReading();

    return DEVCTRL_SUCCESS;
}

int __stdcall SendPacket(int uDevID, unsigned char* buffer, int len)
{
    map<U32, CDeviceManager*>::iterator itFind = devmgrs.find(uDevID);

    if (itFind == devmgrs.end())
        return -1;

    return itFind->second->SendData(buffer,len);
}