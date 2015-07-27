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