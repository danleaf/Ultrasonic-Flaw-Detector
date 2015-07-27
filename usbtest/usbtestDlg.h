
// usbtestDlg.h : ͷ�ļ�
//

#pragma once


// CUsbtestDlg �Ի���
class CUsbtestDlg : public CDialog
{
// ����
public:
	CUsbtestDlg(CWnd* pParent = NULL);	// ��׼���캯��

// �Ի�������
	enum { IDD = IDD_USBTEST_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV ֧��


// ʵ��
protected:
    HICON m_hIcon;
    FILE* m_pf;
    int ifile;
    int curNo;
    bool run;
    int devID;
    DWORD dwThreadID;
    PWAVBUFFER m_pBuffer;

	// ���ɵ���Ϣӳ�亯��
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
