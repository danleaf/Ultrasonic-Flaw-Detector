
// fx2lpcppDlg.h : ͷ�ļ�
//

#pragma once


// Cfx2lpcppDlg �Ի���
class Cfx2lpcppDlg : public CDialogEx
{
// ����
public:
	Cfx2lpcppDlg(CWnd* pParent = NULL);	// ��׼���캯��

// �Ի�������
	enum { IDD = IDD_FX2LPCPP_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV ֧��


// ʵ��
protected:
	HICON m_hIcon;

    CCyUSBDevice* myDevice;
    CCyUSBEndPoint* inEndPoint;
    CCyUSBEndPoint* outEndPoint;

	// ���ɵ���Ϣӳ�亯��
	virtual BOOL OnInitDialog();
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	DECLARE_MESSAGE_MAP()
public:
    afx_msg void OnBnClickedButton1();
    afx_msg void OnBnClickedButton2();
};
