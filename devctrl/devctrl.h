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

#define DEVCTRL_SUCCESS 0

typedef struct __WaveBuffer
{
    unsigned char* address;
    unsigned int waveSize;
    unsigned int waveCount;
}WAVBUFFER,*PWAVBUFFER;

DEVCTRL_API int  __stdcall EnumerateDevices(int *devIDs, int *devCount);
DEVCTRL_API int  __stdcall SetWaveAndBufferParam(int uDevID, int waveRawSize, int waveRate, int bufCount, int waveCount);
DEVCTRL_API int  __stdcall StartDevice(int uDevID);
DEVCTRL_API int  __stdcall StopDevice(int uDevID);
DEVCTRL_API int  __stdcall WaitWavePacket(int uDevID, PWAVBUFFER* pBuffer, unsigned int timeout);
DEVCTRL_API int  __stdcall SendPacket(int uDevID, unsigned char* buffer, int len);
DEVCTRL_API int  __stdcall ReleasePacket(int uDevID, PWAVBUFFER pBuffer);