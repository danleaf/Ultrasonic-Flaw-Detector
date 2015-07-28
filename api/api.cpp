// api.cpp : 定义 DLL 应用程序的导出函数。
//

#include "stdafx.h"
#include "../devctrl/devctrl.h"
#include "api.h"

RETCODE __stdcall IPScanEnumerateDevices(HANDLE* hDevices, U32* uDeviceCount)
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

RETCODE __stdcall AlazarPostAsyncBuffer(HANDLE hDevice, void *buffer, U32 uBufferLength)
{
    return AddBuffer((int)hDevice, (unsigned char*)buffer, uBufferLength);
}

RETCODE __stdcall IPScanSendData(HANDLE hDevice, void* buffer, U32 uLength)
{
    return SendData((int)hDevice, (unsigned char*)buffer, uLength);
}

RETCODE __stdcall IPScanSendCommand(HANDLE hDevice, U16 cmd, U32 param)
{
    return SendCommand((int)hDevice, cmd, param);
}

RETCODE __stdcall IPScanAlazarWaitAsyncBufferComplete(HANDLE hDevice, void** pBuffer, U32 uTimeout)
{
    return WaitWavePacket((int)hDevice, (unsigned char**)pBuffer, uTimeout);
}

RETCODE __stdcall IPScanStartCapture(HANDLE  hDevice)
{
    return StartDevice((int)hDevice);
}

RETCODE __stdcall IPScanAbortAsyncRead(HANDLE  hDevice)
{
    return StopDevice((int)hDevice);
}
