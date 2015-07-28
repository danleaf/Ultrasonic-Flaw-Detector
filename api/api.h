// 下列 ifdef 块是创建使从 DLL 导出更简单的
// 宏的标准方法。此 DLL 中的所有文件都是用命令行上定义的 API_EXPORTS
// 符号编译的。在使用此 DLL 的
// 任何其他项目上不应定义此符号。这样，源文件中包含此文件的任何其他项目都会将
// API_API 函数视为是从 DLL 导入的，而此 DLL 则将用此宏定义的
// 符号视为是被导出的。
#ifdef API_EXPORTS
#define API_API __declspec(dllexport)
#else
#define API_API __declspec(dllimport)
#endif

#define IPSCAN_SUCCESS 0


API_API HANDLE  __stdcall IPScanGetDeviceBySystemID(U32 systemId, U32 deviceId);
API_API RETCODE __stdcall IPScanEnumerateDevices(HANDLE* hDevices, U32* uDeviceCount);
API_API RETCODE __stdcall IPScanSendData(HANDLE hDevice, void* pBuffer, U32 uLength);
API_API RETCODE __stdcall IPScanSendCommand(HANDLE  hDevice, U16 cmd, U32 param);
API_API RETCODE __stdcall IPScanAlazarPostAsyncBuffer(HANDLE hDevice, void* buffer, U32 uBufferLength);
API_API RETCODE __stdcall IPScanAlazarWaitAsyncBufferComplete(HANDLE hDevice, void** pBuffer, U32 uTimeout);
API_API RETCODE __stdcall IPScanStartCapture(HANDLE  hDevice);
API_API RETCODE __stdcall IPScanAbortAsyncRead(HANDLE  hDevice);