#ifndef __TYPES_H__
#define __TYPES_H__

typedef __int8              S8;
typedef __int16             S16;
typedef __int32             S32;
typedef __int64             S64;

typedef unsigned __int8	    U8;
typedef unsigned __int16    U16;
typedef unsigned __int32    U32;
typedef unsigned __int64    U64;

typedef INT32 RETCODE;
typedef void*   POINTER;

typedef int RETURN_CODE;

#define    ApiSuccess          	         0                     
#define    ApiFailed					-1		
#define    ApiAccessDenied				-2	
#define    ApiNullParam					-3	
#define    ApiInvalidBusIndex			-4		
#define    ApiUnsupportedFunction		-5	
#define    ApiInvalidPciSpace			-6		
#define    ApiInvalidIopSpace			-7			
#define    ApiInvalidSize				-8			
#define    ApiInvalidAddress			-9		
#define    ApiInvalidAccessType			-10		
#define    ApiInvalidIndex				-11		
#define    ApiMuNotReady				-12			
#define    ApiMuFifoEmpty				-13			
#define    ApiMuFifoFull				-14			
#define    ApiInvalidRegister			-15			
#define    ApiDoorbellClearFailed		-16			
#define    ApiInvalidUserPin			-17			
#define    ApiInvalidUserState			-18		
#define    ApiEepromNotPresent			-19		
#define    ApiEepromTypeNotSupported	-20			
#define    ApiEepromBlank				-21			
#define    ApiConfigAccessFailed		-22			
#define    ApiInvalidDeviceInfo			-23		
#define    ApiNoActiveDriver			-24			
#define    ApiInsufficientResources		-25		
#define    ApiObjectAlreadyAllocated	-26			
#define    ApiAlreadyInitialized		-27			
#define    ApiNotInitialized			-28			
#define    ApiBadConfigRegEndianMode	-29			
#define    ApiInvalidPowerState			-30		
#define    ApiPowerDown					-31		
#define    ApiFlybyNotSupported			-32		
#define    ApiNotSupportThisChannel		-33		
#define    ApiNoAction					-34		
#define    ApiHSNotSupported			-35			
#define    ApiVPDNotSupported			-36			
#define    ApiVpdNotEnabled				-37		
#define    ApiNoMoreCap					-38		
#define    ApiInvalidOffset				-39		
#define    ApiBadPinDirection			-40			
#define    ApiPciTimeout				-41			
#define    ApiDmaChannelClosed			-42		
#define    ApiDmaChannelError			-43			
#define    ApiInvalidHandle				-44		
#define    ApiBufferNotReady			-45			
#define    ApiInvalidData				-46			
#define    ApiDoNothing					-47		
#define    ApiDmaSglBuildFailed			-48		
#define    ApiPMNotSupported			-49			
#define    ApiInvalidDriverVersion		-50		
#define    ApiWaitTimeout				-51			
#define    ApiWaitCanceled				-52		
#define    ApiBufferTooSmall			-53			
#define    ApiBufferOverflow			-54			
#define    ApiInvalidBuffer				-55		
#define    ApiInvalidRecordsPerBuffer	-56			
#define    ApiDmaPending				-57			
#define    ApiLockAndProbePagesFailed	-58			
#define    ApiWaitAbandoned				-59		
#define    ApiWaitFailed				-60			
#define    ApiTransferComplete			-61		
#define    ApiPllNotLocked				-62		
#define    ApiNotSupportedInDualChannelMode       -63
#define    ApiNotSupportedInQuadChannelMode		  -64
#define    ApiFileIoError				-65			
#define    ApiInvalidClockFrequency		-66		
#define    ApiSendUSBDataFailed         -67
#define    ApiRecveUSBDataFailed        -68
#define    ApiWaitDeviceRspTimeOut      -69
#define    ApiLastError							// Do not add API errors below this line

#endif