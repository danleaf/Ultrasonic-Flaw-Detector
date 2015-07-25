
// fx2lpcppDlg.cpp : ʵ���ļ�
//

#include "stdafx.h"
#include "fx2lpcpp.h"
#include "fx2lpcppDlg.h"
#include "afxdialogex.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// Cfx2lpcppDlg �Ի���



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


// Cfx2lpcppDlg ��Ϣ�������

BOOL Cfx2lpcppDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	// ���ô˶Ի����ͼ�ꡣ  ��Ӧ�ó��������ڲ��ǶԻ���ʱ����ܽ��Զ�
	//  ִ�д˲���
	SetIcon(m_hIcon, TRUE);			// ���ô�ͼ��
	SetIcon(m_hIcon, FALSE);		// ����Сͼ��

	// TODO:  �ڴ���Ӷ���ĳ�ʼ������
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

	return TRUE;  // ���ǽ��������õ��ؼ������򷵻� TRUE
}

// �����Ի��������С����ť������Ҫ����Ĵ���
//  �����Ƹ�ͼ�ꡣ  ����ʹ���ĵ�/��ͼģ�͵� MFC Ӧ�ó���
//  �⽫�ɿ���Զ���ɡ�

void Cfx2lpcppDlg::OnPaint()
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
		CDialogEx::OnPaint();
	}
}

//���û��϶���С������ʱϵͳ���ô˺���ȡ�ù��
//��ʾ��
HCURSOR Cfx2lpcppDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}



void Cfx2lpcppDlg::OnBnClickedButton1()
{
    // TODO:  �ڴ���ӿؼ�֪ͨ����������
    UCHAR buf[1024];
    LONG len = 512;
    bool ret = inEndPoint->XferData(buf, len);
}


void Cfx2lpcppDlg::OnBnClickedButton2()
{
    // TODO:  �ڴ���ӿؼ�֪ͨ����������

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
