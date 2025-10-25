/*
 *   Copyright 2013-2024 The MathWorks, Inc.
 *
 *
 */

#ifndef DATAMODIFY_H_
#define DATAMODIFY_H_
#include "MW_target_hardware_resources.h"
#include "rtwtypes.h"

/*
QUE_SIZE determines the size of the SW Que variable queRx. This is use to supplement the HW Serial FIFO
******************************************Very Important**********************************************
Changing QUE_SIZE and QUE_SIZE_INDEX


1.>If QUE_SIZE is small, it has a risk of corrupting data in the QUE. There is no check in the software
   to take care of a QUE overflow condition. Dont decrease the QUE_SIZE unless there is surity that the
   SW Que doesnt overflow
2.>QUE_SIZE Must always be power of 2. As Overflow conditions while adding que are handling assuming
   this fact. This helps to optimize the ISR filling in the SW Que.
3.>Also correspondingly change the QUE_SIZE_INDEX variable. This is used to define the first_element
   variable in the Que.
4.>QUE_SIZE_INDEX Calculation
   QUE_SIZE = 2 ^ QUE_SIZE_INDEX
   Whenever QUE_SIZE is changed. Change the QUE_SIZE_INDEX acoordingly as per the above equation

******************************************Very Important**********************************************
*/
#define QUE_SIZE (512)
#define QUE_SIZE_INDEX (9)
#define UINT16_SIZE_BITS (16)

/*

Note this Size should change when TARGET_SERIAL_RECEIVE_BUFFER_SIZE is changed in ext_serial_utils_c2000.c

*/

typedef struct queSciTag
{
	char queElements[QUE_SIZE];
	uint16_T  firstElement:QUE_SIZE_INDEX;
	uint16_T dummy:(UINT16_SIZE_BITS-QUE_SIZE_INDEX);
	/*
		Read the Notes at the header file above before making changes to this structure

	*/
	int  queCount;
}	queSci;

extern queSci queRx;

extern void BytePackerInplace32bits(char* src);

extern void BytePacker32bits(void* dst, const char* src);

extern void BytePacker16bits(void* dst, const char* src);

extern boolean_T isEmpty(queSci* que);

extern boolean_T isFull(queSci* que);

extern boolean_T addElement(queSci* que, char* new_element);

extern boolean_T deleteElement(queSci* que, char* read_element);

extern void initQue(queSci* que);

#endif
