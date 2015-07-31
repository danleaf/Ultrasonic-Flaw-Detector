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
#define INTERNAL_CLOCK 0
#define EXTERNAL_CLOCK 1
#define CLOCK_POSEDGE 0
#define CLOCK_NEGEDGE 1


API_API HANDLE  __stdcall IPScanGetDeviceBySystemID(U32 systemId, U32 deviceId);
API_API RETURN_CODE __stdcall IPScanEnumerateDevices(HANDLE* hDevices, U32* uDeviceCount);
API_API RETURN_CODE __stdcall IPScanSendData(HANDLE hDevice, void* pBuffer, U32 uLength);
API_API RETURN_CODE __stdcall IPScanSendCommand(HANDLE  hDevice, U16 cmd, U32 param);
API_API RETURN_CODE __stdcall IPScanPostBuffer(HANDLE hDevice, void* buffer, U32 uBufferLength);
API_API RETURN_CODE __stdcall IPScanWaitBufferComplete(HANDLE hDevice, void** pBuffer, U32 uTimeout);
API_API RETURN_CODE __stdcall IPScanStartDevice(HANDLE hDevice);
API_API RETURN_CODE __stdcall IPScanStopDevice(HANDLE hDevice);
API_API RETURN_CODE __stdcall IPScanStartCapture(HANDLE hDevice);
API_API RETURN_CODE __stdcall IPScanAbortAsyncRead(HANDLE hDevice);
API_API RETURN_CODE __stdcall IPScanSetCaptureClock(HANDLE hDevice, U32 Source, U32 Rate, U32 Edge);      //Rate��λΪHZ,���100HZ
API_API RETURN_CODE __stdcall IPScanSetTriggerDelay(HANDLE hDevice, U32 Delay);

API_API RETURN_CODE __stdcall
IPScanBeforeRead(
    HANDLE  hDevice, 
    U32     uChannelSelect, 
    long    lTransferOffset,
    U32		uSamplesPerRecord,
    U32		uRecordsPerBuffer,
    U32		uRecordsPerAcquisition,
    U32		uFlags);