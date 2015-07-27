// ���� ifdef ���Ǵ���ʹ�� DLL �������򵥵�
// ��ı�׼�������� DLL �е������ļ��������������϶���� DEVCTRL_EXPORTS
// ���ű���ġ���ʹ�ô� DLL ��
// �κ�������Ŀ�ϲ�Ӧ����˷��š�������Դ�ļ��а������ļ����κ�������Ŀ���Ὣ
// DEVCTRL_API ������Ϊ�Ǵ� DLL ����ģ����� DLL ���ô˺궨���
// ������Ϊ�Ǳ������ġ�
#ifdef DEVCTRL_EXPORTS
#define DEVCTRL_API __declspec(dllexport)
#else
#define DEVCTRL_API __declspec(dllimport)
#endif

#ifndef __DEVCTRL_H__
#define __DEVCTRL_H__

#include "../inclib/CyAPI.h"

#define CACHE_SIZE  0x6000
#define Ezusb_IOCTL_INDEX  0x0800
#define IOCTL_EZUSB_BULK_READ             CTL_CODE(FILE_DEVICE_UNKNOWN,  \
    Ezusb_IOCTL_INDEX + 19, \
    METHOD_OUT_DIRECT, \
    FILE_ANY_ACCESS)

#define IOCTL_EZUSB_BULK_WRITE            CTL_CODE(FILE_DEVICE_UNKNOWN,  \
    Ezusb_IOCTL_INDEX + 20, \
    METHOD_IN_DIRECT, \
    FILE_ANY_ACCESS)

typedef struct _BULK_TRANSFER_CONTROL
{
    ULONG pipeNum;
}BULK_TRANSFER_CONTROL, *PBULK_TRANSFER_CONTROL;

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
    U32     devID;              //�豸ID����ʶ���ӵ���λ�����豸
    U32     protType;           //ͨ��Э�����ͣ�����USB������̫��
    U32     devIP;              //�豸IP��ַ������̫Э����Ч

    UFD_USBDevInfo  usbDev;     //USB�豸��Ϣ����USB�豸��Ч
}UFD_DEVINFO, *PUFD_DEVINFO;


typedef struct ufdBuffer
{
    WAVBUFFER buffer;

    volatile long reading;
    struct ufdBuffer* next;

    void InterlockedSetReading()
    {
        InterlockedCompareExchange(&reading, TRUE, FALSE);
    }

    void InterlockedUnSetReading()
    {
        InterlockedCompareExchange(&reading, FALSE, TRUE);
    }
}UFD_BUFFER, *PUFD_BUFFER;

class CDeviceManager
{
    UFD_DEVINFO m_device;
    PUFD_BUFFER m_buffer;

    PUFD_BUFFER m_currBuffer;
    PUFD_BUFFER m_readyBuffer;
    int         m_currWaveInBuffer;

    unsigned char* m_cache;

    HANDLE  m_hThread;
    HANDLE  m_hPacketEvent;
    DWORD   m_dwThreadID;

    int     m_waveRawSize;       //���δ����ɼ����εĵ���
    int     m_waveSize;          //���δ����ɼ����ξ�ѹ����ʵ�ʵĵ���
    int     m_compressRate;      //�ó�Ա��ֵ = uWaveRawSize / uWaveSize
    int     m_bufferWaveCount;   //һ���������в��ε�����
    int     m_bufferCount;       //����������

public:
    CDeviceManager(const UFD_DEVINFO& dev);
    ~CDeviceManager();

    int    StartDevice();
    int    StopDevice();
    int    SetWaveAndBufferParam(int waveRawSize, int waveRate, int bufCount, int waveCount);
    int    WaitWavePacket(PUFD_BUFFER* pBuffer, DWORD timeout);
    int    SendData(unsigned char* buffer, int len);
    DWORD  ReceiveDataProc();

protected:
    void    DeleteBuffer();
    int     SetWaveParam(int rawSize, int rate);
    int     SetBuffer(int bufCount, int waveCount);
    int     ReceiveDataUSB();
    int     ReceiveDataEth();
    int     SendDataUSB(unsigned char* buffer, int len);
    int     SendDataEth(unsigned char* buffer, int len);
};

#endif