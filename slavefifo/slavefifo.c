#pragma NOIV                    // Do not generate interrupt vectors
//-----------------------------------------------------------------------------
//   File:      tcxmaster.c
//   Contents:  Hooks required to implement USB peripheral function.
//              Code written for FX2 56-pin REVD...
//              This firmware is used to test the FX ext. master CY3682 DK
//   Copyright (c) 2001 Cypress Semiconductor All rights reserved
//-----------------------------------------------------------------------------
#include "inc\fx2.h"
#include "inc\fx2regs.h"
#include "inc\fx2sdly.h"            // SYNCDELAY macro

extern BOOL GotSUD;             // Received setup data flag
extern BOOL Sleep;
extern BOOL Rwuen;
extern BOOL Selfpwr;

BYTE Configuration;             // Current configuration
BYTE AlternateSetting;          // Alternate settings
BOOL enum_high_speed;


//sbit PA0 = IOA ^ 0;             // alt. func., INT0#


// EZUSB FX2 PORTE is not bit-addressable...

//-----------------------------------------------------------------------------
// Task Dispatcher hooks
//   The following hooks are called by the task dispatcher.
//-----------------------------------------------------------------------------
void TD_Init( void )
{ // Called once at startup

    //时钟设置
	//CPUCS = 0x02;  //12MHZ CLKOUT ENALBE   
    //CPUCS = 0x0a;  //24MHZ CLKOUT ENALBE 
    CPUCS = 0x12;  //48MHZ CLKOUT ENALBE 
	
	IFCONFIG =0x43;//使用外部时钟，IFCLK输入不反向
	
	SYNCDELAY;
	EP2CFG=0xA0; //需要设定为四缓冲，每个缓冲区大小为512字节
	SYNCDELAY;
	EP4CFG=0x00;
	SYNCDELAY;
	EP6CFG=0xE0;
	SYNCDELAY;
	EP8CFG=0x00;
	
	SYNCDELAY;
	FIFORESET = 0x80;             // activate NAK-ALL to avoid race conditions
	SYNCDELAY;                    // see TRM section 15.14
	FIFORESET = 0x02;             // reset, FIFO 2
	SYNCDELAY;                    // 
	FIFORESET = 0x06;             // reset, FIFO 6
	SYNCDELAY;                    // 
	FIFORESET = 0x00;             // deactivate NAK-ALL
	
	SYNCDELAY;
	PINFLAGSAB = 0xE6;          // FLAGA - fixed EP6PF, FLAGB - fixed EP6FF
	SYNCDELAY;
	PINFLAGSCD = 0xf8;          // FLAGC - fixed EP2EF, FLAGD - reserved
	SYNCDELAY;
	PORTACFG |=  0x00;  //0x40;             // SLCS, set alt. func. of PA7 pin
	SYNCDELAY;
	FIFOPINPOLAR = 0x00;          // all signals active low，
	SYNCDELAY;

	 OEA|=0x0F;
    //小于64字节有效
    //EP6FIFOPFH=0x00; //DEIS PKSTAT  PK2 PK1 PK0 0 PFC9 PFC8
    //EP6FIFOPFL=0x40; //PFC7 PFC6 PFC5 PFC4 PFC3 PFC2 PFC1 PFC0
	
	// handle the case where we were already in AUTO mode...
	EP2FIFOCFG = 0x01;            // AUTOOUT=0, WORDWIDE=1
	SYNCDELAY;
	
	EP2FIFOCFG = 0x11;            // AUTOOUT=1, WORDWIDE=1
	SYNCDELAY;
	
	
	EP6FIFOCFG = 0x09;            // AUTOIN=1, ZEROLENIN=0, WORDWIDE=1
	SYNCDELAY;

	//IO设置
	PORTCCFG=0x00;
	PORTECFG=0x00;
	OEC=0x00;
	OEE=0xff;
	//串口初始化

//	PA3=0;
	PA0=1;

	enum_high_speed=FALSE;

}

void TD_Poll( void )
{ // Called repeatedly while the device is idle

  // ...nothing to do... slave fifo's are in AUTO mode...

}

BOOL TD_Suspend( void )          
{ // Called before the device goes into suspend mode
   return( TRUE );
}

BOOL TD_Resume( void )          
{ // Called after the device resumes
   return( TRUE );
}

//-----------------------------------------------------------------------------
// Device Request hooks
//   The following hooks are called by the end point 0 device request parser.
//-----------------------------------------------------------------------------
BOOL DR_GetDescriptor( void )
{
   return( TRUE );
}

BOOL DR_SetConfiguration( void )   
{ // Called when a Set Configuration command is received
  
  if( EZUSB_HIGHSPEED( ) )
  { // ...FX2 in high speed mode
    EP6AUTOINLENH = 0x02;
    SYNCDELAY;
    EP6AUTOINLENL = 0x00;
    SYNCDELAY;
	enum_high_speed = TRUE;
  }
  else
  { // ...FX2 in full speed mode
    EP6AUTOINLENH = 0x00;
    SYNCDELAY;
    EP6AUTOINLENL = 0x40;
    SYNCDELAY;
	enum_high_speed = FALSE;
  }
      
  Configuration = SETUPDAT[ 2 ];
  return( TRUE );        // Handled by user code
}

BOOL DR_GetConfiguration( void )   
{ // Called when a Get Configuration command is received
   EP0BUF[ 0 ] = Configuration;
   EP0BCH = 0;
   EP0BCL = 1;
   return(TRUE);          // Handled by user code
}

BOOL DR_SetInterface( void )       
{ // Called when a Set Interface command is received
   AlternateSetting = SETUPDAT[ 2 ];
   return( TRUE );        // Handled by user code
}

BOOL DR_GetInterface( void )       
{ // Called when a Set Interface command is received
   EP0BUF[ 0 ] = AlternateSetting;
   EP0BCH = 0;
   EP0BCL = 1;
   return( TRUE );        // Handled by user code
}

BOOL DR_GetStatus( void )
{
   return( TRUE );
}

BOOL DR_ClearFeature( void )
{
   return( TRUE );
}

BOOL DR_SetFeature( void )
{
   return( TRUE );
}

#define VEND_IFHIGHSPEED 0xB2 // VEND_IFHIGHSPEED
#define VEND_RSTDEVICE 0xB3 // VEND_RSTDEVICE
#define VEND_GETDI 0xB4 // VEND_GETDI
#define VEND_SETDO 0xB5 // VEND_SETDO
#define VEND_CFGUART 0xB6 // VEND_CFGUART

BOOL DR_VendorCmnd( void )
{
  BYTE bc;
  BYTE i;
   switch (SETUPDAT[1])
  {
	case VEND_IFHIGHSPEED:
	{
		*EP0BUF = enum_high_speed;
		//*(EP0BUF+1) = IOC;
		EP0BCH = 0;
		EP0BCL = 1;
		EP0CS |= bmHSNAK;
		break;
	}
	case VEND_RSTDEVICE: // enable IN transfers  启动数据传输
	{
	  //get ep0 buffer data
	  EP0BCH = 0;
	  EP0BCL = 0; // Clear bytecount to allow new data in; also stops NAKing
	  while(EP0CS & bmEPBUSY);
	  bc = EP0BCL; // Get the new bytecount 
     //可用来设置初始化参数 

	 SYNCDELAY;
	 FIFORESET = 0x80;             // activate NAK-ALL to avoid race conditions
	 SYNCDELAY;  
     PA0=0;	                   // see TRM section 15.14                  // 
	 FIFORESET = 0x06;             // reset, FIFO 6
	 SYNCDELAY;                    // 
	 FIFORESET = 0x00;             // deactivate NAK-ALL

	 EZUSB_Delay(EP0BUF[0]); 
	 PA0=1;
//    *EP0BUF = VX_B3;
//    EP0BCH = 0;
//	  EP0BCL = 1;
	  EP0CS |= bmHSNAK;
	  break;
    }
	case VEND_GETDI: //DI
	{	      
      *EP0BUF = IOC;
  	  EP0BCH = 0;
	  EP0BCL = 1;
	  EP0CS |= bmHSNAK;
	  break;
    }
	case VEND_SETDO: //D0
	{	  
	  EP0BCH = 0;
	  EP0BCL = 0; 
	  while(EP0CS & bmEPBUSY);
      IOE=EP0BUF[0];
	  EP0CS |= bmHSNAK;
	  break;
    }
	case VEND_CFGUART: //UART
	{	  
	  EP0BCH = 0;
	  EP0BCL = 0; 
	  while(EP0CS & bmEPBUSY);
	  bc = EP0BCL; 
	  for(i=0;i<bc;i++)
	  {
			while( !TI );  // poll tx flag
			TI = 0;           // clr it
			SBUF0 = EP0BUF[ i ]; // tx byte using uart0
	  }

	  EP0CS |= bmHSNAK;
	  break;
    }
     default:
        return(TRUE);
  }


  return(FALSE);
}

//-----------------------------------------------------------------------------
// USB Interrupt Handlers
//   The following functions are called by the USB interrupt jump table.
//-----------------------------------------------------------------------------

// Setup Data Available Interrupt Handler
void ISR_Sudav( void ) interrupt 0
{
   GotSUD = TRUE;         // Set flag
   EZUSB_IRQ_CLEAR( );
   USBIRQ = bmSUDAV;      // Clear SUDAV IRQ
}

// Setup Token Interrupt Handler
void ISR_Sutok( void ) interrupt 0
{
   EZUSB_IRQ_CLEAR( );
   USBIRQ = bmSUTOK;      // Clear SUTOK IRQ
}

void ISR_Sof( void ) interrupt 0
{
   EZUSB_IRQ_CLEAR( );
   USBIRQ = bmSOF;        // Clear SOF IRQ
}

void ISR_Ures( void ) interrupt 0
{
   if ( EZUSB_HIGHSPEED( ) )
   {
      pConfigDscr = pHighSpeedConfigDscr;
      pOtherConfigDscr = pFullSpeedConfigDscr;
   }
   else
   {
      pConfigDscr = pFullSpeedConfigDscr;
      pOtherConfigDscr = pHighSpeedConfigDscr;
   }
   
   EZUSB_IRQ_CLEAR( );
   USBIRQ = bmURES;       // Clear URES IRQ
}

void ISR_Susp( void ) interrupt 0
{
   Sleep = TRUE;
   EZUSB_IRQ_CLEAR( );
   USBIRQ = bmSUSP;
}

void ISR_Highspeed( void ) interrupt 0
{
   if ( EZUSB_HIGHSPEED( ) )
   {
      pConfigDscr = pHighSpeedConfigDscr;
      pOtherConfigDscr = pFullSpeedConfigDscr;
   }
   else
   {
      pConfigDscr = pFullSpeedConfigDscr;
      pOtherConfigDscr = pHighSpeedConfigDscr;
   }

   EZUSB_IRQ_CLEAR( );
   USBIRQ = bmHSGRANT;
}
void ISR_Ep0ack( void ) interrupt 0
{
}
void ISR_Stub( void ) interrupt 0
{
}
void ISR_Ep0in( void ) interrupt 0
{
}
void ISR_Ep0out( void ) interrupt 0
{
}
void ISR_Ep1in( void ) interrupt 0
{
}
void ISR_Ep1out( void ) interrupt 0
{
}
void ISR_Ep2inout( void ) interrupt 0
{
}
void ISR_Ep4inout( void ) interrupt 0
{
}
void ISR_Ep6inout( void ) interrupt 0
{
}
void ISR_Ep8inout( void ) interrupt 0
{
}
void ISR_Ibn( void ) interrupt 0
{
}
void ISR_Ep0pingnak( void ) interrupt 0
{
}
void ISR_Ep1pingnak( void ) interrupt 0
{
}
void ISR_Ep2pingnak( void ) interrupt 0
{
}
void ISR_Ep4pingnak( void ) interrupt 0
{
}
void ISR_Ep6pingnak( void ) interrupt 0
{
}
void ISR_Ep8pingnak( void ) interrupt 0
{
}
void ISR_Errorlimit( void ) interrupt 0
{
}
void ISR_Ep2piderror( void ) interrupt 0
{
}
void ISR_Ep4piderror( void ) interrupt 0
{
}
void ISR_Ep6piderror( void ) interrupt 0
{
}
void ISR_Ep8piderror( void ) interrupt 0
{
}
void ISR_Ep2pflag( void ) interrupt 0
{
}
void ISR_Ep4pflag( void ) interrupt 0
{
}
void ISR_Ep6pflag( void ) interrupt 0
{
}
void ISR_Ep8pflag( void ) interrupt 0
{
}
void ISR_Ep2eflag( void ) interrupt 0
{
}
void ISR_Ep4eflag( void ) interrupt 0
{
}
void ISR_Ep6eflag( void ) interrupt 0
{
}
void ISR_Ep8eflag( void ) interrupt 0
{
}
void ISR_Ep2fflag( void ) interrupt 0
{
}
void ISR_Ep4fflag( void ) interrupt 0
{
}
void ISR_Ep6fflag( void ) interrupt 0
{
}
void ISR_Ep8fflag( void ) interrupt 0
{
}
void ISR_GpifComplete( void ) interrupt 0
{
}
void ISR_GpifWaveform( void ) interrupt 0
{
}
