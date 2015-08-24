
// usbtestDlg.cpp : ʵ���ļ�
//

#include "stdafx.h"
#include "usbtest.h"
#include "usbtestDlg.h"
#include "afxdialogex.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// CUsbtestDlg �Ի���



CUsbtestDlg::CUsbtestDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CUsbtestDlg::IDD, pParent)
{
    m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
    run = true;
    curNo = 0;
    ifile = 0;
    m_buffer = NULL;
}

void CUsbtestDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CUsbtestDlg, CDialog)
	ON_WM_PAINT()
    ON_WM_QUERYDRAGICON()
    ON_WM_LBUTTONUP()
    ON_WM_RBUTTONUP()
    ON_WM_CLOSE()
END_MESSAGE_MAP()


DWORD WINAPI WaitWaveProc(void* param)
{
    CUsbtestDlg* pDlg = (CUsbtestDlg*)param;

    return pDlg->WaitWaveProc();
}

DWORD WINAPI Msg(void* param)
{
    return AfxMessageBox(_T("��USB Slaveʧ��,���򼴽��ر�!"));
}


// CUsbtestDlg ��Ϣ�������

BOOL CUsbtestDlg::OnInitDialog()
{
	CDialog::OnInitDialog();

	// ���ô˶Ի����ͼ�ꡣ  ��Ӧ�ó��������ڲ��ǶԻ���ʱ����ܽ��Զ�
	//  ִ�д˲���
	SetIcon(m_hIcon, TRUE);			// ���ô�ͼ��
	SetIcon(m_hIcon, FALSE);		// ����Сͼ��

	// TODO:  �ڴ���Ӷ���ĳ�ʼ������

    int devCount = 1;

    if (DEVCTRL_SUCCESS != EnumerateDevices(&devID, &devCount))
    {
        DWORD tid;
        CreateThread(NULL, 0, Msg, NULL, 0, &tid);
        Sleep(1500);
        PostQuitMessage(-1);
    }

    waveSize = 1000;
    waveCount = 1;
    SetWaveParam(devID, waveSize, 1);    

   // SendCommand(devID, CMD_SET_TEST, 1);
    SendCommand(devID, CMD_SET_TRIGWAVE_DELAY, 100);

    for (int i = 0; i < 10; i++)
    {
        unsigned char* buf = new unsigned char[waveSize*waveCount];
        AddBuffer(devID, buf, waveSize*waveCount);
    }

    HANDLE h = CreateThread(NULL, 0, ::WaitWaveProc, this, 0, &dwThreadID);

    StartDevice(devID);

	return TRUE;  // ���ǽ��������õ��ؼ������򷵻� TRUE
}

void CUsbtestDlg::OnPaint()
{
	if (IsIconic())
	{
		CPaintDC dc(this); // ���ڻ��Ƶ��豸������

		SendMessage(WM_ICONERASEBKGND, reinterpret_cast<WPARAM>(dc.GetSafeHdc()), 0);

		// ʹͼ���ڹ����������о���
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// ����ͼ��
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
    {
        RECT rect;
        GetClientRect(&rect);
        CPaintDC dc(this);
        ShowWave(dc, rect);
	}
}

void CUsbtestDlg::OnLButtonUp(UINT_PTR id, CPoint pt)
{
    static int i = 0;
    if (i % 2 == 0)
    {
        if (pt.x < 300)
            SendCommand(devID, CMD_SET_TRIG_MODE, 1);
        else
            SendCommand(devID, CMD_SET_TRIG_FREQU, 1000);
    }
    else
    {
        if (pt.x < 300)
            SendCommand(devID, CMD_SET_TRIG_MODE, 0);
        else
            SendCommand(devID, CMD_SET_TRIG_FREQU, 100);
    }
    i++;

}

void CUsbtestDlg::OnRButtonUp(UINT_PTR id, CPoint pt)
{
    static unsigned int i = 1;
    if (i % 2)
        StartCapture(devID);
    else
        StopCapture(devID);

    i++;
}

void CUsbtestDlg::OnClose()
{
    StopDevice(devID);
    SendCommand(devID, CMD_SET_TRIG_MODE, 0);
    ::PostQuitMessage(0);
}

//���û��϶���С������ʱϵͳ���ô˺���ȡ�ù��
//��ʾ��
HCURSOR CUsbtestDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}

void CUsbtestDlg::ShowWave(CPaintDC& dc, RECT& rc)
{
    if (!m_buffer)
        return;

    CDC memDC;  //�����ڴ�DC
    CBitmap memBitmap;
    CBitmap* pOldBmp = NULL;

    memDC.CreateCompatibleDC(&dc);
    memBitmap.CreateCompatibleBitmap(&dc, rc.right, rc.bottom);
    pOldBmp = memDC.SelectObject(&memBitmap);
    memDC.BitBlt(rc.left, rc.top, rc.right, rc.bottom, &dc, 0, 0, SRCCOPY);

    RECT rect;
    rect.top = rc.top + 30;
    rect.bottom = rc.bottom - 30;
    rect.left = rc.left + 2;
    rect.right = rc.right - 2;

    unsigned char* waveData = m_buffer;
    int len = waveSize;

    double step = (double)(rect.right - rect.left) / len;
    double scale = (double)(rect.bottom - rect.top) / (double)255;

    memDC.MoveTo(rect.left, rect.bottom - waveData[0] * scale);

    for (int i = 1; i < len; i++)
    {
        memDC.LineTo(rect.left + i*step, rect.bottom - waveData[i] * scale);
    }

    char str[10];
    sprintf_s(str, 10, "%d", curNo);

    memDC.TextOut(0, 0, CString(str));


    dc.BitBlt(rc.left, rc.top, rc.right, rc.bottom, &memDC, 0, 0, SRCCOPY);
    memDC.SelectObject(pOldBmp);
    memDC.DeleteDC();
    memBitmap.DeleteObject();
}

DWORD CUsbtestDlg::WaitWaveProc()
{
    while (true)
    {
        if (!run)
        {
            Sleep(1);
            continue;
        }        
        
        unsigned char* buffer = NULL;
        if (DEVCTRL_SUCCESS != WaitWavePacket(devID, &buffer, 30000))
        {
            Sleep(0);
            continue;
        }
        

        static int ifile = 0;

        if (ifile < 10)
        {
            char name[16];
            sprintf_s(name, 16, "wave_%d.log", ifile);

            FILE* pf = fopen(name, "w");
            for (int i = 0; i < waveSize*waveCount; i++)
            {
                fprintf_s(pf, "%d\n", buffer[i]);
            }
            fclose(pf);

            ifile++;
        }

        AddBuffer(devID, m_buffer, waveSize*waveCount);


        if (buffer)
        {
            m_buffer = buffer;
            curNo++;

            Invalidate();
            UpdateWindow();
        }
    }

    return 0;
}
