// Driver.h : Declaration of the CDriver

#pragma once
#include "resource.h"       // main symbols

#include "OdfWordXPAddinDriver.h"


#if defined(_WIN32_WCE) && !defined(_CE_DCOM) && !defined(_CE_ALLOW_SINGLE_THREADED_OBJECTS_IN_MTA)
#error "Single-threaded COM objects are not properly supported on Windows CE platform, such as the Windows Mobile platforms that do not include full DCOM support. Define _CE_ALLOW_SINGLE_THREADED_OBJECTS_IN_MTA to force ATL to support creating single-thread COM object's and allow use of it's single-threaded COM object implementations. The threading model in your rgs file was set to 'Free' as that is the only threading model supported in non DCOM Windows CE platforms."
#endif



// CDriver

class ATL_NO_VTABLE CDriver :
	public CComObjectRootEx<CComSingleThreadModel>,
	public CComCoClass<CDriver, &CLSID_Driver>,
	public IDispatchImpl<IDriver, &IID_IDriver, &LIBID_OdfWordXPAddinDriverLib, /*wMajor =*/ 1, /*wMinor =*/ 0>
{
public:
	CDriver()
	{
	}

DECLARE_REGISTRY_RESOURCEID(IDR_DRIVER)


BEGIN_COM_MAP(CDriver)
	COM_INTERFACE_ENTRY(IDriver)
	COM_INTERFACE_ENTRY(IDispatch)
END_COM_MAP()



	DECLARE_PROTECT_FINAL_CONSTRUCT()

	HRESULT FinalConstruct()
	{
		return S_OK;
	}

	void FinalRelease()
	{
	}

public:

};

OBJECT_ENTRY_AUTO(__uuidof(Driver), CDriver)
