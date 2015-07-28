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

#define DEVCTRL_SUCCESS 0
#define CMD_START_RUN 1
#define CMD_STOP_RUN 2
#define CMD_SET_TRIG_MODE 3         //参数0表示内部触发，1表示外部触发
#define CMD_SET_TRIG_EDGE 4         //参数0表示上升沿，1表示下降沿
#define CMD_SET_TRIG_FREQU 5        //参数低16位表示频率，单位HZ，高16位表示正脉宽，单位ns,脉宽取0表示不改变脉宽，默认值是1us
#define CMD_SET_WAVE_SIZE 6         //参数低16位表示原始采集大小，高16位表示压缩比

DEVCTRL_API int  __stdcall EnumerateDevices(int *devIDs, int* devCount);
DEVCTRL_API int  __stdcall SetWaveParam(int devID, int waveRawSize, int waveRate);
DEVCTRL_API int  __stdcall StartDevice(int devID);
DEVCTRL_API int  __stdcall StopDevice(int devID);
DEVCTRL_API int  __stdcall WaitWavePacket(int devID, unsigned char** pBuffer, unsigned int timeout);
DEVCTRL_API int  __stdcall SendData(int devID, unsigned char* buffer, int len);
DEVCTRL_API int  __stdcall AddBuffer(int devID, unsigned char* buffer, int length);
DEVCTRL_API int  __stdcall SendCommand(int devID, unsigned short cmd, unsigned int param);
DEVCTRL_API int  __stdcall DeleteAllBuffer(int devID);


#endif