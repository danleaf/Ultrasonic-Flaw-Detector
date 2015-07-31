// devctrl.cpp : 定义 DLL 应用程序的导出函数。
//

#include "stdafx.h"
#include "devctrl.h"
#include "types.h"
#include "devmgr.h"

#define GET_DEVICE_MANAGER(devid) CDeviceManager* mgr = NULL; do { mgr = CDeviceManager::GetManagerByDeviceID(devid); if(!mgr) return -1;} while(0)


int __stdcall EnumerateDevices(int *devIDs, int* devCount)
{
    list<int> devIDList;

    CDeviceManager::EnumerateDevices(devIDList);

    if (devIDList.size() == 0)
        return -1;
    
    int i = 0;
    for (list<int>::iterator it = devIDList.begin(); it != devIDList.end(); ++it)
    {
        if (i >= *devCount)
            break;

        devIDs[i] = *it;
        i++;
    }

    *devCount = i;

    return 0;
}


int __stdcall SetWaveParam(int devID, int waveRawSize, int waveRate)
{
    GET_DEVICE_MANAGER(devID);
    return mgr->SetWaveParam(waveRawSize, waveRate);
}

int __stdcall StartDevice(int devID)
{
    GET_DEVICE_MANAGER(devID);
    return mgr->StartDevice();
}

int __stdcall StopDevice(int devID)
{
    GET_DEVICE_MANAGER(devID);
    return mgr->StopDevice();
}

int __stdcall WaitWavePacket(int devID, unsigned char** pBuffer, unsigned int timeout)
{
    GET_DEVICE_MANAGER(devID);

    int ret = mgr->WaitWavePacket(pBuffer, timeout);

    return ret;
}

int __stdcall SendData(int devID, unsigned char* buffer, int len)
{
    GET_DEVICE_MANAGER(devID);
    return mgr->SendData(buffer, len);
}

int __stdcall SendCommand(int devID, unsigned short cmd, unsigned int param)
{
    GET_DEVICE_MANAGER(devID);
    return mgr->SendCommand(cmd, param);
}

int __stdcall AddBuffer(int uDevID, unsigned char* buffer, int length)
{
    GET_DEVICE_MANAGER(uDevID);
    mgr->AddBuffer(buffer, length);

    return 0;
}

int __stdcall DeleteAllBuffer(int devID)
{
    GET_DEVICE_MANAGER(devID);
    mgr->DeleteAllBuffer();

    return 0;
}

int  __stdcall StartCapture(int devID)
{
    GET_DEVICE_MANAGER(devID);
    mgr->StartCapture();

    return 0;
}

int  __stdcall StopCapture(int devID)
{
    GET_DEVICE_MANAGER(devID);
    mgr->StopCapture();

    return 0;
}