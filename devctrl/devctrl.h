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

#define CACHE_SIZE  10000
#define Ezusb_IOCTL_INDEX  0x0800
#define IOCTL_EZUSB_BULK_READ             CTL_CODE(FILE_DEVICE_UNKNOWN,  \
    Ezusb_IOCTL_INDEX + 19, \
    METHOD_OUT_DIRECT, \
    FILE_ANY_ACCESS)

typedef struct _BULK_TRANSFER_CONTROL
{
    ULONG pipeNum;
}BULK_TRANSFER_CONTROL, *PBULK_TRANSFER_CONTROL;

enum UDF_PROTTYPE
{
    UDF_ETH,
    UDF_USB
};

typedef struct udfDevInfo
{
    U32     devID;          //设备ID，标识连接到上位机的设备
    U32     protType;          //通信协议类型，比如USB或者以太网
    U32     devIP;              //设备IP地址，仅以太协议有效
    HANDLE  hDevice;            //设备句柄
}UDF_DEVINFO, *PUDF_DEVINFO;

class CDeviceManager
{
    UDF_DEVINFO m_device;    
    PUDF_BUFFER m_buffer;

    PUDF_BUFFER m_currBuffer;
    PUDF_BUFFER m_readyBuffer;
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
    CDeviceManager(const UDF_DEVINFO& dev);
    ~CDeviceManager();

    BOOL    StartDevice();
    BOOL    StopDevice();
    BOOL    SetWaveAndBufferParam(int waveRawSize, int waveRate, int bufCount, int waveCount);
    BOOL    WaitWavePacket(PUDF_BUFFER* pBuffer, DWORD timeout);
    DWORD    ReceiveDataProc();

protected:
    void    DeleteBuffer();
    BOOL    SetWaveParam(int rawSize, int rate);
    BOOL    SetBuffer(int bufCount, int waveCount);
    int     ReceiveDataUSB();
    int     ReceiveDataEth();
};

BOOL EnumerateDevices(PUDF_DEVINFO *devs, int *devCount);
BOOL SetBuffer(int uDevID, int bufCount, int waveCount);
BOOL SetWaveParam(int uDevID, int rawSize, int rate);
BOOL SetWaveAndBufferParam(int uDevID, int waveRawSize, int waveRate, int bufCount, int waveCount);
BOOL StartDevice(int uDevID);
BOOL StopDevice(int uDevID);
BOOL WaitWavePacket(int uDevID, PUDF_BUFFER* pBuffer, DWORD timeout);