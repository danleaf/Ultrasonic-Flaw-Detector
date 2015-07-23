// devctrl.cpp : 定义 DLL 应用程序的导出函数。
//

#include "stdafx.h"
#include "devctrl.h"
#include <assert.h>

map<U32, CDeviceManager*> devmgrs;

DWORD WINAPI ReceivDataProc(void* param)
{
    CDeviceManager* pMgr = (CDeviceManager*)param;

    return pMgr->ReceiveDataProc();
}

BOOL EnumerateDevices(PUDF_DEVINFO *devs, int *devCount)
{
    int devID = 1;
    char pcDriverName[256] = "";
    int i;
    for (i = 0; i<32; i++)
    {
        sprintf_s(pcDriverName, 256, "Ezusb-%d", i);

        char completeDeviceName[64] = "";
        char pcMsg[64] = "";

        strcat_s(completeDeviceName, 64, "\\\\.\\");
        strcat_s(completeDeviceName, 64, pcDriverName);

        HANDLE hDevice = CreateFileA(completeDeviceName,
            GENERIC_WRITE | GENERIC_READ,
            FILE_SHARE_WRITE | FILE_SHARE_READ,
            NULL,
            OPEN_EXISTING,
            0,
            NULL);

        if (hDevice == INVALID_HANDLE_VALUE)
            hDevice = NULL;
        else
        {
            UDF_DEVINFO dev;
            dev.devID = devID++;
            dev.hDevice = hDevice;
            dev.protType = UDF_USB;
            dev.devIP = 0;

            CDeviceManager* mgr = new CDeviceManager(dev);
            devmgrs[dev.devID] = mgr;
        }
    }

    if (i == 32)
    {
        return FALSE;
    }

    return TRUE;
}

CDeviceManager::CDeviceManager(const UDF_DEVINFO& dev)
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

    m_hThread = CreateThread(NULL, 0, ::ReceivDataProc, this, 0, &m_dwThreadID);
}

CDeviceManager::~CDeviceManager()
{
    DeleteBuffer();

    delete m_cache;
}

BOOL CDeviceManager::StartDevice()
{
    return TRUE;
}

BOOL CDeviceManager::StopDevice()
{
    return TRUE;
}

BOOL CDeviceManager::SetWaveParam(int rawSize, int rate)
{
    m_waveRawSize = rawSize;
    m_waveSize = rawSize / rate;
    m_compressRate = rate;

    return TRUE;
}

BOOL CDeviceManager::SetBuffer(int bufCount, int waveCount)
{
    assert(bufCount > 0);

    DeleteBuffer();

    m_buffer = new UDF_BUFFER;
    m_buffer->address = new unsigned char[m_waveSize * waveCount];
    m_buffer->reading = FALSE;
    m_buffer->waveCount = waveCount;
    m_buffer->waveSize = m_waveSize;

    PUDF_BUFFER old = m_buffer;
    for (int i = 1; i < bufCount; i++)
    {
        PUDF_BUFFER curr = new UDF_BUFFER;
        curr->address = new unsigned char[m_waveSize * waveCount];
        curr->reading = FALSE;
        curr->waveCount = waveCount;
        curr->waveSize = m_waveSize;

        old->next = curr;
        old = curr;
    }

    old->next = m_buffer;

    m_bufferWaveCount = waveCount;
    m_bufferCount = bufCount;
    m_currBuffer = m_buffer;
    m_currWaveInBuffer = 0;

    return TRUE;
}

BOOL CDeviceManager::SetWaveAndBufferParam(int waveRawSize, int waveRate, int bufCount, int waveCount)
{
    StopDevice();
    Sleep(100);
    SetWaveParam(waveRawSize, waveRate);
    SetBuffer(bufCount, waveCount);
    StartDevice();

    return TRUE;
}

void CDeviceManager::DeleteBuffer()
{
    m_bufferWaveCount = 0;
    m_bufferCount = 0;
    m_currBuffer = NULL;
    m_currWaveInBuffer = 0;

    PUDF_BUFFER curr = m_buffer;

    while (curr)
    {
        PUDF_BUFFER next = curr->next;

        while (curr->reading)
            Sleep(0);

        delete curr->address;
        delete curr;

        if (next == m_buffer)
            break;

        curr = next;
    }

    m_buffer = NULL;
}

BOOL CDeviceManager::WaitWavePacket(PUDF_BUFFER* pBuffer, DWORD timeout)
{
    WaitForSingleObject(m_hPacketEvent, timeout);

    if (m_readyBuffer->reading)
        return FALSE;

    m_readyBuffer->InterlockedSetReading();
    return TRUE;
}

DWORD CDeviceManager::ReceiveDataProc()
{
    int len;

    while (true)
    {
        if (UDF_USB == m_device.protType)
            len = ReceiveDataUSB();
        else
            len = ReceiveDataEth();

        if (len < 0)
        {
            Sleep(0);
            continue;
        }

        if (len == m_waveSize)
        {
            memcpy(&m_currBuffer->address[m_currBuffer->waveSize*m_currWaveInBuffer],
                m_cache, len);

            m_currWaveInBuffer++;
            if (m_currWaveInBuffer == m_bufferWaveCount)
            {
                m_readyBuffer = m_currBuffer;
                m_currBuffer = m_currBuffer->next;
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
    BULK_TRANSFER_CONTROL myrequest;
    DWORD lenBytes = 0;

    myrequest.pipeNum = 1;

    BOOL bResult = DeviceIoControl(m_device.hDevice,
        IOCTL_EZUSB_BULK_READ,
        &myrequest,
        sizeof(BULK_TRANSFER_CONTROL),
        m_cache,
        CACHE_SIZE,
        (unsigned long *)&lenBytes,
        NULL);

    if (!bResult)
        return -1;

    return lenBytes;
}

int CDeviceManager::ReceiveDataEth()
{
    return 0;
}