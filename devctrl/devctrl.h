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

#define DEVCTRL_SUCCESS 0
#define CMD_START_RUN 1
#define CMD_STOP_RUN 2
#define CMD_SET_TRIG_MODE 3         //����0��ʾ�ڲ�������1��ʾ�ⲿ����
#define CMD_SET_TRIG_EDGE 4         //����0��ʾ�����أ�1��ʾ�½���
#define CMD_SET_TRIG_FREQU 5        //������16λ��ʾƵ�ʣ���λHZ����16λ��ʾ��������λns,����ȡ0��ʾ���ı�����Ĭ��ֵ��1us
#define CMD_SET_WAVE_SIZE 6         //������16λ��ʾԭʼ�ɼ���С����16λ��ʾѹ����

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