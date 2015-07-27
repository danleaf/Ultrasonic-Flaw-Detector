
// usbtestDlg.cpp : 实现文件
//

#include "stdafx.h"
#include "usbtest.h"
#include "usbtestDlg.h"
#include "afxdialogex.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// CUsbtestDlg 对话框



CUsbtestDlg::CUsbtestDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CUsbtestDlg::IDD, pParent)
{
    m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
    run = true;
    curNo = 0;
    ifile = 0;
    m_pBuffer = NULL;
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
    ON_MESSAGE(0x1000, OnWavePacket)
END_MESSAGE_MAP()


DWORD WINAPI WaitWaveProc(void* param)
{
    CUsbtestDlg* pDlg = (CUsbtestDlg*)param;

    return pDlg->WaitWaveProc();
}


// CUsbtestDlg 消息处理程序

BOOL CUsbtestDlg::OnInitDialog()
{
	CDialog::OnInitDialog();

	// 设置此对话框的图标。  当应用程序主窗口不是对话框时，框架将自动
	//  执行此操作
	SetIcon(m_hIcon, TRUE);			// 设置大图标
	SetIcon(m_hIcon, FALSE);		// 设置小图标

	// TODO:  在此添加额外的初始化代码

    int devCount = 1;

    if (!EnumerateDevices(&devID, &devCount))
    {
        AfxMessageBox(_T("打开USB Slave失败,程序即将关闭!"));
        PostQuitMessage(-1);
    }

    SetWaveAndBufferParam(devID, 10000, 1, 10, 100);

    HANDLE h = CreateThread(NULL, 0, ::WaitWaveProc, this, CREATE_SUSPENDED, &dwThreadID);
    SetThreadPriority(h, 31);
    ResumeThread(h);

	return TRUE;  // 除非将焦点设置到控件，否则返回 TRUE
}

// 如果向对话框添加最小化按钮，则需要下面的代码
//  来绘制该图标。  对于使用文档/视图模型的 MFC 应用程序，
//  这将由框架自动完成。

void CUsbtestDlg::OnPaint()
{
	if (IsIconic())
	{
		CPaintDC dc(this); // 用于绘制的设备上下文

		SendMessage(WM_ICONERASEBKGND, reinterpret_cast<WPARAM>(dc.GetSafeHdc()), 0);

		// 使图标在工作区矩形中居中
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// 绘制图标
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
    run = !run;
}

void CUsbtestDlg::OnRButtonUp(UINT_PTR id, CPoint pt)
{
    DWORD lenBytes = 0;
    static unsigned int i = 0;
    unsigned char cmd1[] = { 85, 170, 3, 4, 5, 6 };
    unsigned char cmd2[] = { 170, 85, 3, 4, 5, 6 };

    SendPacket(devID, i % 2 ? cmd1 : cmd2, 6);

    i++;
}

void CUsbtestDlg::OnBnClickedExit()
{
    // TODO: 在此添加控件通知处理程序代码
    ::PostQuitMessage(0);
}

//当用户拖动最小化窗口时系统调用此函数取得光标
//显示。
HCURSOR CUsbtestDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}



void CUsbtestDlg::ShowWave(CPaintDC& dc, RECT& rc)
{
    if (!m_pBuffer)
        return;


    CDC memDC;  //定义内存DC
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

    //memDC.Rectangle(&rect);

    unsigned char* waveData = m_pBuffer->address;
    int len = m_pBuffer->waveSize;

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

        PWAVBUFFER pBuffer = NULL;
        if (DEVCTRL_SUCCESS != WaitWavePacket(devID, &pBuffer, 30000))
        {
            Sleep(0);
            continue;
        }

        if (pBuffer)
            PostMessage(0x1000, (WPARAM)pBuffer, NULL);
    }

    return 0;
}

LRESULT CUsbtestDlg::OnWavePacket(WPARAM wParam, LPARAM lParam)
{
    m_pBuffer = (PWAVBUFFER)wParam;
    curNo++;

    Invalidate();
    UpdateWindow();
    ReleasePacket(devID, m_pBuffer);

    return 0;
}