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

enum UFD_PROTTYPE
{
    UFD_ETH,
    UFD_USB
};

typedef struct ufdDevInfo
{
    U32     devID;          //�豸ID����ʶ���ӵ���λ�����豸
    U32     protType;          //ͨ��Э�����ͣ�����USB������̫��
    U32     devIP;              //�豸IP��ַ������̫Э����Ч
    HANDLE  hDevice;            //�豸���
}UFD_DEVINFO, *PUFD_DEVINFO;

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

    BOOL    StartDevice();
    BOOL    StopDevice();
    BOOL    SetWaveAndBufferParam(int waveRawSize, int waveRate, int bufCount, int waveCount);
    BOOL    WaitWavePacket(PUFD_BUFFER* pBuffer, DWORD timeout);
    DWORD    ReceiveDataProc();

protected:
    void    DeleteBuffer();
    BOOL    SetWaveParam(int rawSize, int rate);
    BOOL    SetBuffer(int bufCount, int waveCount);
    int     ReceiveDataUSB();
    int     ReceiveDataEth();
};

BOOL EnumerateDevices(PUFD_DEVINFO *devs, int *devCount);
BOOL SetBuffer(int uDevID, int bufCount, int waveCount);
BOOL SetWaveParam(int uDevID, int rawSize, int rate);
BOOL SetWaveAndBufferParam(int uDevID, int waveRawSize, int waveRate, int bufCount, int waveCount);
BOOL StartDevice(int uDevID);
BOOL StopDevice(int uDevID);
BOOL WaitWavePacket(int uDevID, PUFD_BUFFER* pBuffer, DWORD timeout);