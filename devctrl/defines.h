// 下列 ifdef 块是创建使从 DLL 导出更简单的
// 宏的标准方法。此 DLL 中的所有文件都是用命令行上定义的 DEVCTRL_EXPORTS
// 符号编译的。在使用此 DLL 的
// 任何其他项目上不应定义此符号。这样，源文件中包含此文件的任何其他项目都会将
// DEVCTRL_API 函数视为是从 DLL 导入的，而此 DLL 则将用此宏定义的
// 符号视为是被导出的。
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
    U32     devID;              //设备ID，标识连接到上位机的设备
    U32     protType;           //通信协议类型，比如USB或者以太网
    U32     devIP;              //设备IP地址，仅以太协议有效

    UFD_USBDevInfo  usbDev;     //USB设备信息，仅USB设备有效
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

    int     m_waveRawSize;       //单次触发采集波形的点数
    int     m_waveSize;          //单次触发采集波形经压缩后实际的点数
    int     m_compressRate;      //该成员的值 = uWaveRawSize / uWaveSize
    int     m_bufferWaveCount;   //一个缓冲区中波形的数量
    int     m_bufferCount;       //缓冲区数量

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