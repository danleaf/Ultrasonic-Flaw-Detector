
// fx2lpcppDlg.h : 头文件
//

#pragma once


// Cfx2lpcppDlg 对话框
class Cfx2lpcppDlg : public CDialogEx
{
// 构造
public:
	Cfx2lpcppDlg(CWnd* pParent = NULL);	// 标准构造函数

// 对话框数据
	enum { IDD = IDD_FX2LPCPP_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV 支持


// 实现
protected:
	HICON m_hIcon;

    CCyUSBDevice* myDevice;
    CCyUSBEndPoint* inEndPoint;
    CCyUSBEndPoint* outEndPoint;

	// 生成的消息映射函数
	virtual BOOL OnInitDialog();
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	DECLARE_MESSAGE_MAP()
public:
    afx_msg void OnBnClickedButton1();
    afx_msg void OnBnClickedButton2();
};
