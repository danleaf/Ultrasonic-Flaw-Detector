
// usbtestDlg.h : 头文件
//

#pragma once


// CUsbtestDlg 对话框
class CUsbtestDlg : public CDialog
{
// 构造
public:
	CUsbtestDlg(CWnd* pParent = NULL);	// 标准构造函数

// 对话框数据
	enum { IDD = IDD_USBTEST_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV 支持


// 实现
protected:
    HICON m_hIcon;
    FILE* m_pf;
    int ifile;
    int curNo;
    bool run;
    int devID;
    DWORD dwThreadID;
    PWAVBUFFER m_pBuffer;

	// 生成的消息映射函数
	virtual BOOL OnInitDialog();
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
    DECLARE_MESSAGE_MAP()
public:
    afx_msg void OnBnClickedExit();
    afx_msg void OnTimer(UINT_PTR id);
    afx_msg void OnLButtonUp(UINT_PTR id, CPoint pt);
    afx_msg void OnRButtonUp(UINT_PTR id, CPoint pt);
    afx_msg LRESULT OnWavePacket(WPARAM wParam, LPARAM lParam);
protected:
    void ShowWave(CPaintDC& dc, RECT& rc);
public:
    DWORD WaitWaveProc();
};
