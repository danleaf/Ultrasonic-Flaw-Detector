
// fx2lpcpp.h : PROJECT_NAME Ӧ�ó������ͷ�ļ�
//

#pragma once

#ifndef __AFXWIN_H__
	#error "�ڰ������ļ�֮ǰ������stdafx.h�������� PCH �ļ�"
#endif

#include "resource.h"		// ������


// Cfx2lpcppApp: 
// �йش����ʵ�֣������ fx2lpcpp.cpp
//

class Cfx2lpcppApp : public CWinApp
{
public:
	Cfx2lpcppApp();

// ��д
public:
	virtual BOOL InitInstance();

// ʵ��

	DECLARE_MESSAGE_MAP()
};

extern Cfx2lpcppApp theApp;