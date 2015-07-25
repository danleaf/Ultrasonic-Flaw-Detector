
// fx2lpcppDlg.cpp : 实现文件
//

#include "stdafx.h"
#include "fx2lpcpp.h"
#include "fx2lpcppDlg.h"
#include "afxdialogex.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// Cfx2lpcppDlg 对话框



Cfx2lpcppDlg::Cfx2lpcppDlg(CWnd* pParent /*=NULL*/)
	: CDialogEx(Cfx2lpcppDlg::IDD, pParent)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
    outEndPoint = NULL;
    inEndPoint = NULL;
}

void Cfx2lpcppDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(Cfx2lpcppDlg, CDialogEx)
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
    ON_BN_CLICKED(IDC_BUTTON1, &Cfx2lpcppDlg::OnBnClickedButton1)
    ON_BN_CLICKED(IDC_BUTTON2, &Cfx2lpcppDlg::OnBnClickedButton2)
END_MESSAGE_MAP()


// Cfx2lpcppDlg 消息处理程序

BOOL Cfx2lpcppDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	// 设置此对话框的图标。  当应用程序主窗口不是对话框时，框架将自动
	//  执行此操作
	SetIcon(m_hIcon, TRUE);			// 设置大图标
	SetIcon(m_hIcon, FALSE);		// 设置小图标

	// TODO:  在此添加额外的初始化代码
    myDevice = new CCyUSBDevice(NULL, CYUSBDRV_GUID, true);

    int interfaces = myDevice->AltIntfcCount() + 1;

    for (int i = 0; i < interfaces; i++)
    {
        myDevice->SetAltIntfc(i);

        int eptCnt = myDevice->EndPointCount();

        for (int e = 1; e < eptCnt; e++)
        {
            CCyUSBEndPoint *ept = myDevice->EndPoints[e];
            if (ept->Address == 0x2)
                outEndPoint = ept;
            if (ept->Address == 0x86)
                inEndPoint = ept;
        }
    }

	return TRUE;  // 除非将焦点设置到控件，否则返回 TRUE
}

// 如果向对话框添加最小化按钮，则需要下面的代码
//  来绘制该图标。  对于使用文档/视图模型的 MFC 应用程序，
//  这将由框架自动完成。

void Cfx2lpcppDlg::OnPaint()
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
		CDialogEx::OnPaint();
	}
}

//当用户拖动最小化窗口时系统调用此函数取得光标
//显示。
HCURSOR Cfx2lpcppDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}



void Cfx2lpcppDlg::OnBnClickedButton1()
{
    // TODO:  在此添加控件通知处理程序代码
    UCHAR buf[1024];
    LONG len = 512;
    bool ret = inEndPoint->XferData(buf, len);
}


void Cfx2lpcppDlg::OnBnClickedButton2()
{
    // TODO:  在此添加控件通知处理程序代码

    LONG len = 6;
    UCHAR data[6];
    static bool b = true;

    if (b)
    {
        data[0] = 0x55;
        data[1] = 0xaa;
        data[2] = 0x55;
        data[3] = 0xaa;
        data[4] = 0x55;
        data[5] = 0xaa;
    }
    else
    {
        data[1] = 0x55;
        data[0] = 0xaa;
        data[3] = 0x55;
        data[2] = 0xaa;
        data[5] = 0x55;
        data[4] = 0xaa;
    }
    b = !b;

    bool ret = outEndPoint->XferData(data, len);
}
