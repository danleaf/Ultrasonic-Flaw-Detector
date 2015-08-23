#include "stdafx.h"
#include "devctrl.h"
#include "devmgr.h"

#define CACHE_SIZE 10240

map<int, CDeviceManager*> CDeviceManager::devmgrs;
SOCKET CDeviceManager::sock = NULL;


DWORD WINAPI ReceivDataProc(void* param)
{
    CDeviceManager* pMgr = (CDeviceManager*)param;

    return pMgr->ReceiveDataProc();
}

CDeviceManager::CDeviceManager(const UFD_DEVINFO& dev)
{
    m_device = dev;
    m_waveRawSize = 0;
    m_waveSize = 0;
    m_compressRate = 1;
    m_bufferWaveCount = 0;
    m_bufferCount = 0;
    m_buffer = NULL;
    m_tailBuffer = NULL;
    m_bufferUsed = FALSE;
    m_cache = new unsigned char[CACHE_SIZE];
    m_hPacketEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
    m_mtxBufferList = CreateMutex(NULL, FALSE, NULL);
    m_mtxSendCommand = CreateMutex(NULL, FALSE, NULL);
    m_evtCommandRsp = CreateEvent(NULL, FALSE, FALSE, NULL);
    m_curCmd = 0;
    m_curCmdRsp = 0;
    m_aboradCapture = FALSE;

    m_hThread = CreateThread(NULL, 0, ::ReceivDataProc, this, CREATE_SUSPENDED, &m_dwThreadID);
    SetThreadPriority(m_hThread, THREAD_PRIORITY_TIME_CRITICAL);
    ResumeThread(m_hThread);
}

CDeviceManager::~CDeviceManager()
{
    delete m_cache;
}

void CDeviceManager::Initialize()
{
    if (NULL != sock)
        return;

    WSADATA wsa;

    if (WSAStartup(MAKEWORD(2, 0), &wsa) != 0)
        return;

    sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sock == INVALID_SOCKET)
    {
        sock = NULL;
        WSACleanup();
        return;
    }
    
    SOCKADDR_IN addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(0xFEEF);
    addr.sin_addr.s_addr = inet_addr("192.168.1.5");

    bool opt = true;
    if (0 > setsockopt(sock, SOL_SOCKET, SO_BROADCAST, (char*)&opt, sizeof(opt)))
    {
        sock = NULL;
        closesocket(sock);
        WSACleanup();
        return;
    }

    if (0 > bind(sock, (sockaddr*)&addr, sizeof(addr)))
    {
        sock = NULL;
        closesocket(sock);
        WSACleanup();
        return;
    }
}

void CDeviceManager::EnumerateDevices(list<int>& devIDs)
{
    EnumerateDevices();

    for (map<int, CDeviceManager*>::iterator it = devmgrs.begin(); it != devmgrs.end(); ++it)
    {
        devIDs.push_back(it->second->GetDeviceID());
    }
}

void CDeviceManager::EnumerateDevices()
{
    Initialize();

    if (devmgrs.size() > 0)
        return;

    int devID = 1;

    CCyUSBDevice* usbdev = new CCyUSBDevice(NULL, CYUSBDRV_GUID, true);

    if (usbdev->ControlEndPt != NULL)
    {
        CCyUSBEndPoint* inEndPoint = usbdev->BulkInEndPt;
        CCyUSBEndPoint* outEndPoint = usbdev->BulkOutEndPt;

        if (outEndPoint == NULL || inEndPoint == NULL)
        {
            LoadHexToRam(usbdev);
        }

        int time = 0;
        while (outEndPoint == NULL || inEndPoint == NULL)
        {
            if (time > 5000)
                break;
            Sleep(1);
            delete usbdev;
            usbdev = new CCyUSBDevice(NULL, CYUSBDRV_GUID, true);
            inEndPoint = usbdev->BulkInEndPt;
            outEndPoint = usbdev->BulkOutEndPt;
            time++;
        }

        if (outEndPoint != NULL && inEndPoint != NULL)
        {
            usbdev->Reset();

            UFD_DEVINFO dev;
            dev.devID = devID;
            dev.protType = UFD_USB;
            dev.devIP = 0;
            dev.usbDev.dev = usbdev;
            dev.usbDev.inEndPoint = inEndPoint;
            dev.usbDev.outEndPoint = outEndPoint;

            inEndPoint->TimeOut = 100;
            outEndPoint->TimeOut = 100;

            CDeviceManager* mgr = new CDeviceManager(dev);
            devmgrs[devID] = mgr;

            devID = devID + 1;
        }
    }
}

void CDeviceManager::SearchEthDevices()
{
    if (NULL == sock)
        return;


}

CDeviceManager* CDeviceManager::GetManagerByDeviceID(int devID)
{
    map<int, CDeviceManager*>::iterator itFind = devmgrs.find(devID);

    if (itFind == devmgrs.end())
        return NULL;

    return itFind->second;
}

int CDeviceManager::GetDeviceID()
{
    return m_device.devID;
}

int CDeviceManager::StartDevice()
{
    ResetBuffer();
    return SendCommand(1, 0);
}

int CDeviceManager::StopDevice()
{
    return SendCommand(2, 0);
}

int CDeviceManager::SetWaveParam(int rawSize, int rate)
{
    m_waveRawSize = rawSize;
    m_waveSize = rawSize / rate;
    m_compressRate = rate;

    unsigned int param = (rawSize & 0xFFFF) | ((rate & 0xFFFF) << 16);

    SendCommand(CMD_SET_WAVE_SIZE, param);

    return 0;
}

int CDeviceManager::WaitWavePacket(unsigned char** pBuffer, DWORD timeout)
{
    DWORD ret = WaitForSingleObject(m_hPacketEvent, timeout);

    if (WAIT_TIMEOUT == ret)
        return ApiWaitTimeout;

    *pBuffer = m_pktBuffer;
    return 0;
}

DWORD CDeviceManager::ReceiveDataProc()
{
    int len;
    PUFD_BUFFER buffer;

    while (true)
    {
        if (UFD_USB == m_device.protType)
            len = ReceiveDataUSB();
        else
            len = ReceiveDataEth();

        if (len < 6)
        {
            continue;
        }

        if (len < 10)
        {
            unsigned short cmd = ((unsigned short*)m_cache)[0];
            unsigned short cmd_ = ~((unsigned short*)m_cache)[1];
            unsigned short rsp = ((unsigned short*)m_cache)[2];

            if (cmd == cmd_)
            {
                if (cmd == m_curCmd)
                {
                    m_curCmdRsp = rsp;
                    SetEvent(m_evtCommandRsp);
                }
            }

            continue;
        }

        if (NULL != (buffer = GetUsedBuffer()))
        //if (m_waveSize==len)
        {
            int cacheleft = len;

            while (true)
            {
                int bufleft = buffer->length - buffer->current;
                int cpylen = cacheleft > bufleft ? bufleft : cacheleft;
                unsigned char* start = &buffer->buffer[buffer->current];

                memcpy(start, m_cache, cpylen);
                cacheleft -= cpylen;
                buffer->current += cpylen;

                if (cacheleft > 0)
                {
                    buffer = PostBuffer();
                    if (!buffer)
                        break;
                }
                else if (buffer->current == buffer->length)
                {
                    PostBuffer();
                    break;
                }
                else
                {
                    break;
                }
            }
        }

        ReturnUsedBuffer();
    }

    return 0;
}

int CDeviceManager::ReceiveDataUSB()
{
    LONG lenBytes = CACHE_SIZE;
    bool ret = m_device.usbDev.inEndPoint->XferData(m_cache, lenBytes);

    if (!ret)
        return ApiRecveUSBDataFailed;

    return lenBytes;
}

int CDeviceManager::ReceiveDataEth()
{
    return 0;
}

int CDeviceManager::SendCommand(unsigned short cmd, unsigned int param)
{
    WaitForSingleObject(m_mtxSendCommand, INFINITE);

    m_curCmd = cmd;

    unsigned short cmdl[] = { cmd, ~cmd, LOWORD(param), HIWORD(param) };

    int ret = SendData((unsigned char*)cmdl, 8);

    if (ret > 0)
    {
        DWORD rsp = WaitForSingleObject(m_evtCommandRsp, 1000);
        if (WAIT_TIMEOUT == rsp)
            ret = ApiWaitDeviceRspTimeOut;
        else
        {
            ret = m_curCmdRsp;
        }
    }

    ReleaseMutex(m_mtxSendCommand);

    return ret;
}

int CDeviceManager::SendData(unsigned char* buffer, int len)
{
    if (UFD_USB == m_device.protType)
        return SendDataUSB(buffer, len);
    else
        return SendDataEth(buffer, len);
}

int CDeviceManager::SendDataUSB(unsigned char* buffer, int len)
{
    LONG lenBytes = len;

    bool ret = m_device.usbDev.outEndPoint->XferData(buffer, lenBytes);

    if (!ret)
        return ApiSendUSBDataFailed;

    return lenBytes;
}

int CDeviceManager::SendDataEth(unsigned char* buffer, int len)
{
    return 0;
}

void CDeviceManager::AddBuffer(unsigned char* buffer, int length)
{
    if (!buffer)
        return;

    PUFD_BUFFER ubuf = new UFD_BUFFER(buffer, length);

    WaitForSingleObject(m_mtxBufferList, INFINITE);

    if (NULL == m_buffer)
    {
        m_buffer = ubuf;
        m_tailBuffer = ubuf;
        m_buffer->next = NULL;
    }
    else
    {
        m_tailBuffer->next = ubuf;
        m_tailBuffer = ubuf;
    }

    ReleaseMutex(m_mtxBufferList);
}

PUFD_BUFFER CDeviceManager::PostBuffer()
{
    if (m_aboradCapture)
        return NULL;

    WaitForSingleObject(m_mtxBufferList, INFINITE);

    if (NULL != m_buffer)
    {
        m_pktBuffer = m_buffer->buffer;
        SetEvent(m_hPacketEvent);

        PUFD_BUFFER tmp = m_buffer;
        m_buffer = m_buffer->next;
        if (NULL == m_buffer)
            m_tailBuffer = NULL;

        delete tmp;
    }

    ReleaseMutex(m_mtxBufferList);

    return m_buffer;
}

void CDeviceManager::ResetBuffer()
{
    if (NULL != m_buffer)
    {
        m_buffer->current = 0;
    }
}

void CDeviceManager::DeleteAllBuffer()
{
    long used = TRUE;

    do {
        Sleep(1);
        used = InterlockedCompareExchange(&m_bufferUsed, TRUE, FALSE);
    } while (used);


    WaitForSingleObject(m_mtxBufferList, INFINITE);

    if (NULL != m_buffer)
    {
        PUFD_BUFFER cur = m_buffer;

        while (cur)
        {
            PUFD_BUFFER tmp = cur;
            cur = cur->next;
            delete tmp;
        }

        m_buffer = NULL;
        m_tailBuffer = NULL;
    }

    ReleaseMutex(m_mtxBufferList);


    InterlockedExchange(&m_bufferUsed, FALSE);
}

int CDeviceManager::StartCapture()
{
    InterlockedExchange(&m_aboradCapture, FALSE);

    return 0;
}

int CDeviceManager::StopCapture()
{
    InterlockedExchange(&m_aboradCapture, TRUE);
    ResetBuffer();
    return 0;
}

PUFD_BUFFER CDeviceManager::GetUsedBuffer()
{
    if (m_aboradCapture)
        return NULL;

    long used = InterlockedCompareExchange(&m_bufferUsed, TRUE, FALSE);
    
    if (!used)
        return m_buffer;

    return NULL;
}

void CDeviceManager::ReturnUsedBuffer()
{
    InterlockedExchange(&m_bufferUsed, FALSE);
}

unsigned char h2i(char ch)
{
    if (ch >= 'A'&&ch <= 'F')
        return ch - 'A' + 10;
    else
        return ch - '0';
}

void HexToBin(const char* str, unsigned char* v, int n)
{
    for (int i = 0; i < n; i++)
    {
        v[i] = (h2i(str[i * 2]) << 4) |
            h2i(str[i * 2 + 1]);
    }
}

int Hex2Bytes(string& byteChars, PUCHAR buf) 
{

    // Remove non-hex chars
    int bytes = byteChars.length() / 2;

    // Stuff the output buffer with the byte values
    if (bytes)
    for (int i = 0; i<bytes; i++) 
    {
        string s = byteChars.substr(i * 2, 2);
        HexToBin(s.c_str(), &buf[i], 1);
    }

    return bytes;
}

void ResetFX2(CCyUSBDevice* dev, UCHAR ucStop)
{
    dev->ControlEndPt->ReqCode = 0xA0;
    dev->ControlEndPt->Value = 0xE600;
    dev->ControlEndPt->Index = 0;

    long len = 1;
    dev->ControlEndPt->Write(&ucStop, len);

}


void CDeviceManager::LoadHexToRam(CCyUSBDevice* dev, bool bLow)
{
    list<string> hexstrList;
    
    {
        hexstrList.push_back(":10069C0090E6007412F090E6017443F000000090B4");
        hexstrList.push_back(":1006AC00E61274A0F0000000E490E613F0000000E5");
        hexstrList.push_back(":1006BC0090E61474E0F0000000E490E615F0000001");
        hexstrList.push_back(":1006CC000090E6047480F00000007402F00000005A");
        hexstrList.push_back(":1006DC007406F0000000E4F000000090E60274E6FE");
        hexstrList.push_back(":1006EC00F000000090E60374F8F000000090E67053");
        hexstrList.push_back(":1006FC00E0F0000000E490E609F000000043B20FC7");
        hexstrList.push_back(":10070C0090E61804F00000007411F000000090E670");
        hexstrList.push_back(":10071C001A7409F0000000E490E671F090E672F0B3");
        hexstrList.push_back(":0A072C00F5B475B6FFD280C20422B6");
        hexstrList.push_back(":0100320022AB");
        hexstrList.push_back(":02005100D322B8");
        hexstrList.push_back(":0208B600D3224B");
        hexstrList.push_back(":0208B800D32249");
        hexstrList.push_back(":1005B80090E680E030E71590E6247402F000000031");
        hexstrList.push_back(":1005C800E490E625F0000000D2048013E490E624CD");
        hexstrList.push_back(":1005D800F000000090E6257440F0000000C204908E");
        hexstrList.push_back(":0705E800E6BAE0F51CD32286");
        hexstrList.push_back(":10087C0090E740E51CF0E490E68AF090E68B04F0FB");
        hexstrList.push_back(":02088C00D32275");
        hexstrList.push_back(":0808AA0090E6BAE0F51BD32231");
        hexstrList.push_back(":10088E0090E740E51BF0E490E68AF090E68B04F0EA");
        hexstrList.push_back(":02089E00D32263");
        hexstrList.push_back(":0208BA00D32247");
        hexstrList.push_back(":0208BC00D32245");
        hexstrList.push_back(":0208BE00D32243");
        hexstrList.push_back(":1003F40090E6B9E0244D601914605014605F1460F5");
        hexstrList.push_back(":1004040074240460030204B5A204E43390E740803A");
        hexstrList.push_back(":100414003FE490E68AF090E68BF090E6A0E020E1DD");
        hexstrList.push_back(":10042400F990E68BE0F51800000090E6047480F083");
        hexstrList.push_back(":10043400000000C2807406F0000000E4F090E74081");
        hexstrList.push_back(":10044400E0FF7E001204B9D280805D90E740E5A011");
        hexstrList.push_back(":10045400F0E490E68AF090E68B04F0804BE490E6BA");
        hexstrList.push_back(":100464008AF090E68BF090E6A0E020E1F990E74076");
        hexstrList.push_back(":10047400E0F5B18033E490E68AF090E68BF090E604");
        hexstrList.push_back(":10048400A0E020E1F990E68BE0F518E4FFEFC395D6");
        hexstrList.push_back(":100494001850153099FDC29974402FF582E434E761");
        hexstrList.push_back(":1004A400F583E0F5990F80E590E6A0E04480F080C4");
        hexstrList.push_back(":0404B40002D322C38A");
        hexstrList.push_back(":0104B8002221");
        hexstrList.push_back(":10082000C0E0C083C082D2015391EF90E65D7401B5");
        hexstrList.push_back(":08083000F0D082D083D0E03249");
        hexstrList.push_back(":10085000C0E0C083C0825391EF90E65D7404F0D095");
        hexstrList.push_back(":0608600082D083D0E032DB");
        hexstrList.push_back(":10086600C0E0C083C0825391EF90E65D7402F0D081");
        hexstrList.push_back(":0608760082D083D0E032C5");
        hexstrList.push_back(":10073600C0E0C083C08290E680E030E70E852125C8");
        hexstrList.push_back(":10074600852226852927852A28800C852925852A1C");
        hexstrList.push_back(":10075600268521278522285391EF90E65D7410F0B7");
        hexstrList.push_back(":07076600D082D083D0E03205");
        hexstrList.push_back(":10083800C0E0C083C082D2035391EF90E65D740894");
        hexstrList.push_back(":08084800F0D082D083D0E03231");
        hexstrList.push_back(":10076D00C0E0C083C08290E680E030E70E85212591");
        hexstrList.push_back(":10077D00852226852927852A28800C852925852AE5");
        hexstrList.push_back(":10078D00268521278522285391EF90E65D7420F070");
        hexstrList.push_back(":07079D00D082D083D0E032CE");
        hexstrList.push_back(":01004200328B");
        hexstrList.push_back(":0104FF0032CA");
        hexstrList.push_back(":0108C0003205");
        hexstrList.push_back(":0108C1003204");
        hexstrList.push_back(":0108C2003203");
        hexstrList.push_back(":0108C3003202");
        hexstrList.push_back(":0108C4003201");
        hexstrList.push_back(":0108C5003200");
        hexstrList.push_back(":0108C60032FF");
        hexstrList.push_back(":0108C70032FE");
        hexstrList.push_back(":0108C80032FD");
        hexstrList.push_back(":0108C90032FC");
        hexstrList.push_back(":0108CA0032FB");
        hexstrList.push_back(":0108CB0032FA");
        hexstrList.push_back(":0108CC0032F9");
        hexstrList.push_back(":0108CD0032F8");
        hexstrList.push_back(":0108CE0032F7");
        hexstrList.push_back(":0108CF0032F6");
        hexstrList.push_back(":0108D00032F5");
        hexstrList.push_back(":0108D10032F4");
        hexstrList.push_back(":0108D20032F3");
        hexstrList.push_back(":0108D30032F2");
        hexstrList.push_back(":0108D40032F1");
        hexstrList.push_back(":0108D50032F0");
        hexstrList.push_back(":0108D60032EF");
        hexstrList.push_back(":0108D70032EE");
        hexstrList.push_back(":0108D80032ED");
        hexstrList.push_back(":0108D90032EC");
        hexstrList.push_back(":0108DA0032EB");
        hexstrList.push_back(":0108DB0032EA");
        hexstrList.push_back(":0108DC0032E9");
        hexstrList.push_back(":0108DD0032E8");
        hexstrList.push_back(":0108DE0032E7");
        hexstrList.push_back(":0108DF0032E6");
        hexstrList.push_back(":0108E00032E5");
        hexstrList.push_back(":0108E10032E4");
        hexstrList.push_back(":0A08A0000001020203030404050531");
        hexstrList.push_back(":10028D00E4F513F512F511F510C203C200C202C256");
        hexstrList.push_back(":10029D000112069C7E067F008E238F24752B06751A");
        hexstrList.push_back(":1002AD002C1275210675221C752906752A4A752D85");
        hexstrList.push_back(":1002BD0006752E78EE54C0700302038E751400750A");
        hexstrList.push_back(":1002CD0015808E168F17C3749A9FFF74069ECF24C8");
        hexstrList.push_back(":1002DD0002CF3400FEE48F0F8E0EF50DF50CF50BED");
        hexstrList.push_back(":1002ED00F50AF509F508AF0FAE0EAD0DAC0CAB0B65");
        hexstrList.push_back(":1002FD00AA0AA909A808C31205EF5033E517250B63");
        hexstrList.push_back(":10030D00F582E516350AF583E0FFE515250BF58237");
        hexstrList.push_back(":10031D00E514350AF583EFF0E50B2401F50BE43513");
        hexstrList.push_back(":10032D000AF50AE43509F509E43508F50880B785BD");
        hexstrList.push_back(":10033D00142385152474002480FF740634FFFEC336");
        hexstrList.push_back(":10034D00E52C9FF52CE52B9EF52BC3E5269FF52679");
        hexstrList.push_back(":10035D00E5259EF525C3E5289FF528E5279EF5277C");
        hexstrList.push_back(":10036D00C3E5229FF522E5219EF521C3E52A9FF5E0");
        hexstrList.push_back(":10037D002AE5299EF529C3E52E9FF52EE52D9EF53F");
        hexstrList.push_back(":10038D002DD2E843D82090E668E04409F090E65C71");
        hexstrList.push_back(":10039D00E0443DF0D2AF90E680E020E105D20512B9");
        hexstrList.push_back(":1003AD00000390E680E054F7F0538EF8C20312007C");
        hexstrList.push_back(":1003BD0032300105120056C2013003F212005150C5");
        hexstrList.push_back(":1003CD00EDC2031207FB20001690E682E030E70431");
        hexstrList.push_back(":1003DD00E020E1EF90E682E030E604E020E0E41278");
        hexstrList.push_back(":0703ED0007A41208B680C747");
        hexstrList.push_back(":0B00460090E50DE030E402C322D3225D");
        hexstrList.push_back(":1000560090E6B9E0700302011514700302019224C0");
        hexstrList.push_back(":10006600FE700302021524FB700302010F147003D5");
        hexstrList.push_back(":100076000201091470030200FD1470030201032437");
        hexstrList.push_back(":100086000560030202791208B8400302028590E671");
        hexstrList.push_back(":10009600BBE024FE602714603824FD60111460273D");
        hexstrList.push_back(":1000A60024067050E52390E6B3F0E524803C120068");
        hexstrList.push_back(":1000B60046503EE52B90E6B3F0E52C802DE52590E5");
        hexstrList.push_back(":1000C600E6B3F0E5268023E52790E6B3F0E5288041");
        hexstrList.push_back(":1000D6001990E6BAE0FF1207D0AA06A9077B01EA43");
        hexstrList.push_back(":1000E600494B600DEE90E6B3F0EF90E6B4F00202F5");
        hexstrList.push_back(":1000F6008502027402027412088E0202851208AA90");
        hexstrList.push_back(":100106000202851205B802028512087C02028512D7");
        hexstrList.push_back(":1001160008BA400302028590E6B8E0247F60151411");
        hexstrList.push_back(":10012600601924027063A200E43325E0FFA202E412");
        hexstrList.push_back(":10013600334F8041E490E740F0803F90E6BCE054C6");
        hexstrList.push_back(":100146007EFF7E00E0D394807C0040047D01800227");
        hexstrList.push_back(":100156007D00EC4EFEED4F24A0F58274083EF5833B");
        hexstrList.push_back(":10016600E493FF3395E0FEEF24A1FFEE34E68F82A1");
        hexstrList.push_back(":10017600F583E0540190E740F0E4A3F090E68AF0BE");
        hexstrList.push_back(":1001860090E68B7402F00202850202741208BC40EB");
        hexstrList.push_back(":100196000302028590E6B8E024FE6016240260039E");
        hexstrList.push_back(":1001A60002028590E6BAE0B40105C20002028502A9");
        hexstrList.push_back(":1001B600027490E6BAE0705590E6BCE0547EFF7E8D");
        hexstrList.push_back(":1001C60000E0D394807C0040047D0180027D00EC39");
        hexstrList.push_back(":1001D6004EFEED4F24A0F58274083EF583E493FFAE");
        hexstrList.push_back(":1001E6003395E0FEEF24A1FFEE34E68F82F583E03F");
        hexstrList.push_back(":1001F60054FEF090E6BCE05480131313541FFFE046");
        hexstrList.push_back(":10020600540F2F90E683F0E04420F08072805F1256");
        hexstrList.push_back(":1002160008BE506B90E6B8E024FE60192402704ECA");
        hexstrList.push_back(":1002260090E6BAE0B40104D200805490E6BAE064E5");
        hexstrList.push_back(":1002360002604C803990E6BCE0547EFF7E00E0D33D");
        hexstrList.push_back(":1002460094807C0040047D0180027D00EC4EFEED32");
        hexstrList.push_back(":100256004F24A0F58274083EF583E493FF3395E0BE");
        hexstrList.push_back(":10026600FEEF24A1FFEE34E68F82F583800D90E643");
        hexstrList.push_back(":10027600A080081203F4500790E6A0E04401F09035");
        hexstrList.push_back(":06028600E6A0E04480F058");
        hexstrList.push_back(":01028C00224F");
        hexstrList.push_back(":030033000208B20E");
        hexstrList.push_back(":0408B20053D8EF32F6");
        hexstrList.push_back(":100600001201000200000040B404041000000102C6");
        hexstrList.push_back(":1006100000010A06000200000040010009022E004D");
        hexstrList.push_back(":1006200001010080320904000004FF0000000705FA");
        hexstrList.push_back(":10063000020200020007050402000200070586020C");
        hexstrList.push_back(":100640000002000705880200020009022E000101D5");
        hexstrList.push_back(":100650000080320904000004FF00000007050202C8");
        hexstrList.push_back(":100660004000000705040240000007058602400024");
        hexstrList.push_back(":10067000000705880240000004030904100343003A");
        hexstrList.push_back(":100680007900700072006500730073000E0345006E");
        hexstrList.push_back(":0C0690005A002D005500530042000000ED");
        hexstrList.push_back(":03004300020500B3");
        hexstrList.push_back(":03005300020500A3");
        hexstrList.push_back(":1005000002082000020866000208500002083800B5");
        hexstrList.push_back(":100510000207360002076D00020042000204FF00DD");
        hexstrList.push_back(":100520000208C0000208C1000208C2000208C3009D");
        hexstrList.push_back(":100530000208C4000208C5000208C6000208C7007D");
        hexstrList.push_back(":100540000208C8000204FF000208C9000208CA002D");
        hexstrList.push_back(":100550000208CB000208CC000208CD000208CE0041");
        hexstrList.push_back(":100560000208CF000204FF000204FF000204FF00A3");
        hexstrList.push_back(":100570000208D0000208D1000208D2000208D3000D");
        hexstrList.push_back(":100580000208D4000208D5000208D6000208D700ED");
        hexstrList.push_back(":100590000208D8000208D9000208DA000208DB00CD");
        hexstrList.push_back(":1005A0000208DC000208DD000208DE000208DF00AD");
        hexstrList.push_back(":0805B0000208E0000208E1006E");
        hexstrList.push_back(":1007A40090E682E030E004E020E60B90E682E03060");
        hexstrList.push_back(":1007B400E119E030E71590E680E04401F07F147E13");
        hexstrList.push_back(":0C07C400001204B990E680E054FEF02220");
        hexstrList.push_back(":1000030030050990E680E0440AF0800790E680E03E");
        hexstrList.push_back(":100013004408F07FDC7E051204B990E65D74FFF0BE");
        hexstrList.push_back(":0F00230090E65FF05391EF90E680E054F7F02203");
        hexstrList.push_back(":1004B9008E198F1A90E600E054187012E51A24017B");
        hexstrList.push_back(":1004C900FFE43519C313F519EF13F51A801590E6F2");
        hexstrList.push_back(":1004D90000E05418FFBF100BE51A25E0F51AE519DD");
        hexstrList.push_back(":1004E90033F519E51A151AAE19700215194E60057A");
        hexstrList.push_back(":0604F90012080F80EE2244");
        hexstrList.push_back(":0207D000A90777");
        hexstrList.push_back(":1007D200AE2DAF2E8F828E83A3E064037017AD011E");
        hexstrList.push_back(":1007E20019ED7001228F828E83E07C002FFDEC3E9A");
        hexstrList.push_back(":0807F200FEAF0580DFE4FEFF0D");
        hexstrList.push_back(":0107FA0022DC");
        hexstrList.push_back(":1007FB0090E682E044C0F090E681F0438701000070");
        hexstrList.push_back(":04080B0000000022C7");
        hexstrList.push_back(":10080F007400F58690FDA57C05A3E582458370F9FC");
        hexstrList.push_back(":01081F0022B6");
        hexstrList.push_back(":03000000020036C5");
        hexstrList.push_back(":0C003600787FE4F6D8FD75812E02028D63");
        hexstrList.push_back(":1005EF00EB9FF5F0EA9E42F0E99D42F0E89C45F062");
        hexstrList.push_back(":0105FF0022D9");
        hexstrList.push_back(":00000001FF");
    }
    
    string tmp;
    int v;

    for (list<string>::iterator it = hexstrList.begin(); it != hexstrList.end();)
    {
        if (it->length())
        {
            tmp = it->substr(8 - 1, 2);
            v = 0;
            HexToBin(tmp.c_str(), (unsigned char *)&v, 1);
            v *= 2;
            if (v)
                it = hexstrList.erase(it);
            else
                ++it;
        }
    }

    for (list<string>::iterator it = hexstrList.begin(); it != hexstrList.end(); ++it)
    {
        string::size_type pos = it->find("//");
        if (pos != it->npos)
        {
            *it = it->substr(0, pos);
        }

        if (it->length())
        {
            string offset = it->substr(4 - 1, 4);
            tmp = it->substr(2 - 1, 2);
            v = 0;
            HexToBin(tmp.c_str(), (unsigned char *)&v, 1);
            v *= 2;

            string s = it->substr(10 - 1, v);
            
            *it = offset + s;
        }
    }


    if (bLow) ResetFX2(dev, 1);      // Stop the processor

    dev->ControlEndPt->ReqCode = bLow ? 0xA0 : 0xA3;
    dev->ControlEndPt->Index = 0;
    dev->ControlEndPt->Value = 0;

    // Go through the list, loading data into RAM
    string DataString = "";
    WORD nxtoffset = 0;
    LONG xferLen = 0;

    WORD offset;
    int RamSize = 0x2000;  // 8KB

    UCHAR buf[0x1000];

    char  c;
    PCHAR pc;


    for (list<string>::iterator it = hexstrList.begin(); it != hexstrList.end(); ++it)
    {
        tmp = it->substr(1 - 1, 4);
        HexToBin(tmp.c_str(), (unsigned char*)&offset, 2);
        pc = (char *)&offset; c = pc[0]; pc[0] = pc[1]; pc[1] = c;
        
        int sLen = it->length();
        int bytes = (sLen - 4) / 2;
        LONG lastAddr = offset + bytes;
        if (bLow && (offset < RamSize) && (lastAddr > RamSize))
            bytes = RamSize - offset;

        if (!bLow && (offset < RamSize) && (lastAddr > RamSize))
        {
            bytes = lastAddr - RamSize;
            string s = "xxxx" + it->substr(sLen - (bytes * 2), bytes * 2);
            *it = s;
            offset = RamSize;
        }

        if ((bLow && (offset < RamSize)) || // Below 8KB - internal RAM
            (!bLow && (offset >= RamSize)))
        {

            xferLen += bytes;

            if ((offset == nxtoffset) && (xferLen < 0x1000)) 
            {
                DataString += it->substr(5 - 1, bytes * 2);
            }
            else 
            {
                LONG len = DataString.length() / 2;
                if (len) 
                {
                    Hex2Bytes(DataString, buf);
                    dev->ControlEndPt->Write(buf, len);
                }

                dev->ControlEndPt->Value = offset;  // The destination address

                DataString = it->substr(5 - 1, bytes * 2);

                xferLen = bytes;

            }

            nxtoffset = offset + bytes;  // Where next contiguous data would sit
        }
    }


    // Send the last segment of bytes
    LONG len = DataString.length() / 2;
    if (len) 
    {
        Hex2Bytes(DataString, buf);
        dev->ControlEndPt->Write(buf, len);
    }

    if (bLow) ResetFX2(dev, 0);      // Start running this new code
}

