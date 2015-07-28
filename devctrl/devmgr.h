#pragma once

#define CMDRSP_LENGTH 8
#define CMDRSP_LENGTH 8

class CDeviceManager
{
    UFD_DEVINFO m_device;

    PUFD_BUFFER m_buffer;
    PUFD_BUFFER m_tailBuffer;
    HANDLE      m_mtxBufferList;
    volatile long m_bufferUsed;

    OVERLAPPED inOvLap;

    HANDLE          m_hPacketEvent;
    unsigned char*  m_pktBuffer;

    unsigned char* m_cache;

    HANDLE  m_hThread;
    DWORD   m_dwThreadID;

    int     m_waveRawSize;       //���δ����ɼ����εĵ���
    int     m_waveSize;          //���δ����ɼ����ξ�ѹ����ʵ�ʵĵ���
    int     m_compressRate;      //�ó�Ա��ֵ = uWaveRawSize / uWaveSize
    int     m_bufferWaveCount;   //һ���������в��ε�����
    int     m_bufferCount;       //����������


    static map<int, CDeviceManager*> devmgrs;

public:
    static void EnumerateDevices();
    static void EnumerateDevices(list<int>& devIDs);
    static CDeviceManager* GetManagerByDeviceID(int devID);

public:
    int GetDeviceID();
    void AddBuffer(unsigned char* buffer, int length);
    void DeleteAllBuffer();

protected:
    PUFD_BUFFER PostBuffer();
    PUFD_BUFFER GetUsedBuffer();
    void ReturnUsedBuffer();
    void ResetBuffer();


public:
    CDeviceManager(const UFD_DEVINFO& dev);
    ~CDeviceManager();

    int    StartDevice();
    int    StopDevice();
    int    WaitWavePacket(unsigned char** pBuffer, DWORD timeout);
    int    SetWaveParam(int rawSize, int rate);
    int    SetBuffer(int bufCount, int waveCount);
    int    SendData(unsigned char* buffer, int len);
    int    SendCommand(unsigned short cmd, unsigned int param);
    DWORD  ReceiveDataProc();

protected:
    int     ReceiveDataUSB();
    int     ReceiveDataEth();
    int     SendDataUSB(unsigned char* buffer, int len);
    int     SendDataEth(unsigned char* buffer, int len);
};