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

typedef struct ufdDevInfo
{
    int     devID;              //�豸ID����ʶ���ӵ���λ�����豸
    int     protType;           //ͨ��Э�����ͣ�����USB������̫��
    unsigned int     devIP;              //�豸IP��ַ������̫Э����Ч

    UFD_USBDevInfo  usbDev;     //USB�豸��Ϣ����USB�豸��Ч
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

