/* Copyright 2024 The MathWorks, Inc. */

// This file is used for imread code generation.


#ifndef JPEGEMBEDDEDINTERFACE_H
#define JPEGEMBEDDEDINTERFACE_H

#include <stdint.h>
#include "string.h"

#include <stdio.h>
#include <stdlib.h>

/*
 * Include file for users of JPEG library.
 */

#include "jpeglib.h"
#include "jerror.h"

int jpegreader_getimagesize(const char* filename,
                            int32_t* imgDims,
                            int8_t* fileStatus,
                            int8_t* colorSpaceStatus,
                            int8_t* bitDepthStatus,
                            int32_t* libjpegMsgCode,
                            char* libjpegErrWarnBuffer,
                            int8_t* errWarnType);

int jpegreader_uint8(const char* filename,
                     uint8_t* inputBuffer,
                     int8_t* fileStatus,
                     int8_t* libjpegReadDone,
                     int32_t* libjpegMsgCode,
                     char* libjpegErrWarnBuffer,
                     int8_t* errWarnType,
                     int8_t* runtimeFileDimsConsistent);
					 
void ReadRGB8JPEG (j_decompress_ptr cinfoPtr, 
                   JSAMPARRAY buffer, 
                   uint8_t *pr_red, 
                   uint8_t *pr_green, 
                   uint8_t *pr_blue);
				   
void ReadGrayscale8JPEG (j_decompress_ptr cinfoPtr, 
                         JSAMPARRAY buffer, 
                         uint8_t *pr_gray);

// Status codes for file open operation.
enum FILESTATUS { FILE_OPEN_SUCCESS = 0, FILE_OPEN_ERROR = -1, FILE_NOT_OPENED = -2 };

// Status codes for completing file reading operation.
enum LIBJPEGREADSTATUS { READ_INCOMPLETE = 0, READ_COMPLETE = 1 };

// Status codes for any colorspace issues.
enum COLORSPACESTATUS {
    VALID_COLOR_SPACE = 0,
    UNSUPPORTED_COLOR_SPACE = -1,
    NO_CMYK_COLOR_SPACE = -2
};

// Status codes which denote how to interpret messages from libjpeg.
// Depending on when or where the message was issued, it may be treated as
// an error, warning or no-op (ignore).
enum LIBJPEGCODETYPE {
    IGNORE_MESSAGE_CODE = 0,
    ERROR_MESSAGE_CODE = -1,
    WARNING_MESSAGE_CODE = -2
};

// Status codes for inconsistencies between the dimensions of the file at run-time
// and compile-time when the input file is a compile time constant.
enum FILEDIMSTATUS { FILEDIMS_CONSISTENT = 1, FILEDIMS_INCONSISTENT = 0 };

// Status codes for supported JPEG bit depths
enum BITDEPTHSTATUS { BIT_DEPTH_SUPPORTED = 1, BIT_DEPTH_UNSUPPORTED = -1 };

#endif /* JPEGEMBEDDEDINTERFACE_H */
