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

typedef struct __Buffer {
    U8*     address;
    U32   length;
}BUFFER, *PBUFFER;

#endif