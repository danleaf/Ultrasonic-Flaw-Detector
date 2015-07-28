// ���� ifdef ���Ǵ���ʹ�� DLL �������򵥵�
// ��ı�׼�������� DLL �е������ļ��������������϶���� API_EXPORTS
// ���ű���ġ���ʹ�ô� DLL ��
// �κ�������Ŀ�ϲ�Ӧ����˷��š�������Դ�ļ��а������ļ����κ�������Ŀ���Ὣ
// API_API ������Ϊ�Ǵ� DLL ����ģ����� DLL ���ô˺궨���
// ������Ϊ�Ǳ������ġ�
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