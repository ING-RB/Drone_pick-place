/*
 *   Copyright 2014-2024 The MathWorks, Inc.
 *
 *
 */

#include <stdlib.h>
#include "rtwtypes.h"
#include "dataModify.h"

/* Que Declarations */
boolean_T isEmpty(queSci* que);

boolean_T isFull(queSci* que);

queSci queRx;		/* Que to Supplement SCI in External Mode */

#if defined(INCLUDE_BYEPACK)
void BytePackerInplace32bits(char* src)
{
	uint32_T temp32bits=0;
	uint32_T mask = 0xff;
	char 	 index=0;

	for (index = 0; index < 4; index++)
	{
		temp32bits += ( (uint32_T)(src[index] & mask) << (8 * index) );

	}

	*src = temp32bits;

}


void BytePacker32bits(void *dst, const char* src )
{

	uint32_T temp32bits=0;
	uint32_T mask = 0xff;
	char 	 index=0;
	uint32_T *typecastdst = (uint32_T *)dst;

	for (index = 0; index < 4; index++)
	{
		temp32bits += ( (uint32_T)(src[index] & mask) << (8 * index) );

	}

	*typecastdst = temp32bits;

}

void BytePacker16bits(void* dst, const char* src)
{
	uint16_T temp16bits=0;
	uint16_T mask = 0xff;
	uint16_T *typecastdst = (uint16_T*)dst;
	char index = 0;
	for( index=0; index < 2; index++)
	{
		temp16bits += ((uint16_T)(src[index] & mask) << (8 * index));

	}

	*typecastdst = temp16bits;


}
#endif

void initQue(queSci *que)
{
	que->firstElement = 0;
	que->queCount     = 0;
}


boolean_T isEmpty(queSci* que)
{
	if (que->queCount == 0)
	{
		return true;
	}
	else
	{
		return false;
	}
}


boolean_T isFull(queSci* que)
{
	if(que->queCount >= QUE_SIZE)
	{
		return true;
	}
	else
	{
		return false;
	}
}



boolean_T addElement(queSci* que, char* new_element)
{

	int new_element_position=0;

	if(isFull(que))
	{
		return false;
	}

	//Add new element
	new_element_position = (que->firstElement + que->queCount);
	if (new_element_position >= QUE_SIZE)
	{
        //Wrapping Circular Buffer every time new_element_position >= QUE_SIZE
		new_element_position = new_element_position - QUE_SIZE;	
	}

	que->queElements[new_element_position] = *new_element;
	que->queCount++;

	return true;

}


/*
	deleteElement() is supposed to read an element from the Queue and decreases it's length by one. This is the standard and expected behaviour.
	However, in case the Queue is empty, it does check the hardware buffer for any available data. If new data is available, it is read and returned.
	If not, the function returns 'false' indicating a failure to read/fetch any data.

*/

boolean_T deleteElement(queSci* que, char* read_element)
{
	if(isEmpty(que))									// check if queue empty.
        return false;
	else 
    {
		*read_element = que->queElements[que->firstElement++];
		que->queCount--;
		return true;
	}
}
