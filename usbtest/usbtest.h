
// usbtest.h : PROJECT_NAME Ӧ�ó������ͷ�ļ�
//

#pragma once

#ifndef __AFXWIN_H__
	#error "�ڰ������ļ�֮ǰ������stdafx.h�������� PCH �ļ�"
#endif

#include "resource.h"		// ������


// CUsbtestApp: 
// �йش����ʵ�֣������ usbtest.cpp
//

class CUsbtestApp : public CWinApp
{
public:
	CUsbtestApp();

// ��д
public:
	virtual BOOL InitInstance();

// ʵ��

	DECLARE_MESSAGE_MAP()
};

extern CUsbtestApp theApp;