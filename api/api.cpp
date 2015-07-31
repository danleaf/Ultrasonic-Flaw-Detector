// api.cpp : 定义 DLL 应用程序的导出函数。
//

#include "stdafx.h"
#include "../devctrl/devctrl.h"
#include "api.h"

RETURN_CODE __stdcall IPScanEnumerateDevices(HANDLE* hDevices, U32* uDeviceCount)
{
    int* devIDs = new int[*uDeviceCount];
    int devCOunt = *uDeviceCount;
    int ret = EnumerateDevices(devIDs, &devCOunt);

    if (IPSCAN_SUCCESS == ret)
    {
        for (int i = 0; i < devCOunt; i++)
            hDevices[i] = (HANDLE)devIDs[i];
    }
    
    *uDeviceCount = devCOunt;
    delete devIDs;
	return ret;
}

HANDLE __stdcall IPScanGetDeviceBySystemID(U32 systemId, U32 deviceId)
{
    HANDLE handle = NULL;
    U32 count = 1;

    RETCODE ret = IPScanEnumerateDevices(&handle, &count);
    if (IPSCAN_SUCCESS != ret)
        return NULL;

    return handle;
}

RETURN_CODE __stdcall IPScanPostBuffer(HANDLE hDevice, void *buffer, U32 uBufferLength)
{
    return AddBuffer((int)hDevice, (unsigned char*)buffer, uBufferLength);
}

RETURN_CODE __stdcall IPScanSendData(HANDLE hDevice, void* buffer, U32 uLength)
{
    return SendData((int)hDevice, (unsigned char*)buffer, uLength);
}

RETURN_CODE __stdcall IPScanSendCommand(HANDLE hDevice, U16 cmd, U32 param)
{
    return SendCommand((int)hDevice, cmd, param);
}

RETURN_CODE __stdcall IPScanWaitBufferComplete(HANDLE hDevice, void** pBuffer, U32 uTimeout)
{
    return WaitWavePacket((int)hDevice, (unsigned char**)pBuffer, uTimeout);
}

RETURN_CODE __stdcall IPScanStartCapture(HANDLE  hDevice)
{
    return StartCapture((int)hDevice);
}

RETURN_CODE __stdcall IPScanAbortAsyncRead(HANDLE  hDevice)
{
    return StopCapture((int)hDevice);
}

RETURN_CODE __stdcall IPScanStartDevice(HANDLE hDevice)
{
    return StartDevice((int)hDevice);
}

RETURN_CODE __stdcall IPScanStopDevice(HANDLE hDevice)
{
    return StopDevice((int)hDevice);
}

//Rate单位为HZ,最低100HZ
RETURN_CODE __stdcall IPScanSetCaptureClock(HANDLE hDevice, U32 Source, U32 Rate, U32 Edge)
{
    int ret = SendCommand((int)hDevice, CMD_SET_TRIG_MODE, Source);
    if (ret != IPSCAN_SUCCESS)
        return ret;

    ret = SendCommand((int)hDevice, CMD_SET_TRIG_EDGE, Edge);
    if (ret != IPSCAN_SUCCESS)
        return ret;

    return IPSCAN_SUCCESS;
}

RETURN_CODE __stdcall IPScanSetTriggerDelay(HANDLE hDevice, U32 Delay)
{
    return SendCommand((int)hDevice, CMD_SET_OUTTRIG_DELAY, Delay);
}

RETURN_CODE __stdcall
IPScanBeforeRead(
    HANDLE  hDevice,
    U32     uChannelSelect,
    long    lTransferOffset,
    U32		uSamplesPerRecord,
    U32		uRecordsPerBuffer,
    U32		uRecordsPerAcquisition,
    U32		uFlags)
{
    return SetWaveParam((int)hDevice, uSamplesPerRecord, 1);
}