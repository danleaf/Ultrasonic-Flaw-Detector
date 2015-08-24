#pragma once

#include "../inclib/CyAPI.h"

enum UFD_PROTTYPE
{
    UFD_ETH,
    UFD_USB
};

typedef struct ufdUSBDevInfo
{
    CCyUSBDevice*   dev;
    CCyUSBEndPoint* inEndPoint;
    CCyUSBEndPoint* outEndPoint;

    ufdUSBDevInfo()
    {
        dev = NULL;
        inEndPoint = NULL;
        outEndPoint = NULL;
    }
}UFD_USBDevInfo, *PUFD_USBDevInfo;

typedef struct ufdETHDevInfo
{
    SOCKADDR_IN addr;

    ufdETHDevInfo()
    {
        memset(&addr, 0, sizeof(addr));
    }
}UFD_ETHDevInfo, *PUFD_ETHDevInfo;

typedef struct ufdDevInfo
{
    int     devID;              //设备ID，标识连接到上位机的设备
    int     protType;           //通信协议类型，比如USB或者以太网
             
    UFD_ETHDevInfo  ethDev;     //以太设备信息，仅以太设备有效
    UFD_USBDevInfo  usbDev;     //USB设备信息，仅USB设备有效
}UFD_DEVINFO, *PUFD_DEVINFO;


typedef struct ufdBuffer
{
    unsigned char* buffer;
    int length;
    int current;
    volatile long busy;

    struct ufdBuffer* next;

    ufdBuffer()
    {
        buffer = NULL;
        length = 0;
        current = 0;
        busy = 0;
        next = NULL;
    }

    ufdBuffer(unsigned char* buffer, int length)
    {
        this->buffer = buffer;
        this->length = length;
        current = 0;
        busy = 0;
        next = NULL;
    }

}UFD_BUFFER, *PUFD_BUFFER;

