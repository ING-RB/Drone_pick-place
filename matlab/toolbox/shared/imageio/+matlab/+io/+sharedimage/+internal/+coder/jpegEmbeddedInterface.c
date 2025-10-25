/**********************************************************************
 *
 * jpegEmbeddedInterface.c
 *
 * This file is used for code generation on embedded targets only.
 *
 * This file calls the libjpeg-turbo API directly and
 * decompresses the image. The file has the following functions:
 *
 * ** jpegreader_getimagesize **
 * This method reads the JPEG header to get the image bit depth and image dimensions.
 *
 * ** jpegreader_uint8 **
 * This method reads the JPEG file by calling the libjpeg-turbo API jpeg_read_scanlines
 * and fills the output buffer.
 *
 *
 * Copyright 2024 The MathWorks, Inc.
 *
 *********************************************************************/
/*
 * <setjmp.h> is used for the optional error recovery mechanism
 */

#include <setjmp.h>
#include "jpegEmbeddedInterface.h"


/*
 * ERROR HANDLING:
 *
 * Override the library's "error_exit" method so that
 * control is returned to the library's caller when a fatal error occurs,
 * rather than calling exit() as the standard error_exit method does.
 *
 * We use C's setjmp/longjmp facility to return control.  This means that the
 * routine which calls the libjpeg-turbo library must first execute a setjmp() call to
 * establish the return point.  We want the replacement error_exit to do a
 * longjmp().  But we need to make the setjmp buffer accessible to the
 * error_exit routine.
 */

struct mw_error_mgr {
    struct jpeg_error_mgr pub; /* "public" fields */

    jmp_buf setjmp_buffer; /* for return to caller */
    char err_warn_buffer[JMSG_LENGTH_MAX];
    int8_t read_done; /* If reading is done then only warn not error */
    // err_warn_type indicates whether the library message from libjpeg-turbo
    // should be interpreted as an error, warning or no-op (ignore). This
    // value is passed back to be used by eml/imread codegen "front-end" API
    int8_t err_warn_type;
};

typedef struct mw_error_mgr* mw_error_ptr;

/*
 * Here's the routine that will replace the standard error_exit method:
 */

METHODDEF(void)
my_error_exit(j_common_ptr cinfo) {
    /* cinfo->err really points to a mw_error_mgr struct, so coerce pointer */
    mw_error_ptr myerr = (mw_error_ptr)cinfo->err;
    if (cinfo->err->msg_code == JERR_EMPTY_IMAGE) 
    {
        // We may be able to handle these.  The message may indicate that this
        // bit-depth and/or compression mode aren't supported by this "flavor"
        // of the library.  Continue on.
        return;
    }

    /* Call the output_message method of jpeg_std_error */
    (*cinfo->err->output_message)(cinfo);
    if (myerr->read_done) 
    {
        if( cinfo->err->msg_code < JERR_ARITH_NOTIMPL ||
        	  cinfo->err->msg_code > JERR_XMS_WRITE )
        /* If reading is done and the error condition is not in [JERR_ARITH_NOTIMPL, JERR_XMS_WRITE]
           we can continue without throwing an error
        */
        {
            return;
        }
        // Since reading is complete, ignore error code and return the image data.
        myerr->err_warn_type =
        (int8_t)(IGNORE_MESSAGE_CODE);
    }
    else{
        // Set type of message code to error and return control to the setjmp point.
        myerr->err_warn_type =
            (int8_t)(ERROR_MESSAGE_CODE);
    }
	
    /* Return control to the setjmp point */
    longjmp(myerr->setjmp_buffer, 1);
}

// Initialize the libjpeg-turbo library and read the JPEG header
void initializeJPEG(FILE** infile_ptr, int32_t* libjpegMsgCode, char* libjpegErrWarnBuffer,
                    int8_t* errWarnType, j_decompress_ptr cinfoPtr, mw_error_ptr jerrPtr)
{
    /* Allocate and initialize JPEG decompression object */

    /* We set up the normal JPEG error routines, then override error_exit. */
    cinfoPtr->err = jpeg_std_error(&(jerrPtr->pub));
    (jerrPtr->pub).error_exit = my_error_exit;
    // Read is not done
    jerrPtr->read_done = (int8_t)(READ_INCOMPLETE);
	
    /* Initialize the JPEG decompression object. */
    jpeg_create_decompress(cinfoPtr);

    /* Specify data source (eg, a file) */
    jpeg_stdio_src(cinfoPtr, *infile_ptr);
	
    int status = jpeg_read_header(cinfoPtr, FALSE);
	
    if (status != JPEG_HEADER_OK) {
        *(libjpegMsgCode) = (*cinfoPtr).err->msg_code;
        strcpy(libjpegErrWarnBuffer, jerrPtr->err_warn_buffer);
        // Set the err_warn_type as this error condition is not handled by
        // my_error_exit()
        jerrPtr->err_warn_type = (int8_t)(ERROR_MESSAGE_CODE);
        *(errWarnType) = jerrPtr->err_warn_type;
        jpeg_destroy_decompress(cinfoPtr);
        fclose(*infile_ptr);
        (*infile_ptr) = NULL;
        return;
    }
}

/*
 jpegreader_getimagesize()

 jpegreader_getimagesize() reads the header of a JPEG file, filename and
 returns its size as 1x3 vector in imgDims. It also returns status codes
 which are used to report any errors when opening and reading the input
 file. They are as follows:

 fileStatus        - Custom flag which specifies whether file open
                     operation was successful or not.
 colorSpaceStatus  - Custom flag which specifies whether the color space
                     of the jpeg file is valid or not.
 bitDepthStatus    - Custom flag which specifies whether the bit depth of
                     the jpeg file is supported or not.
 libjpegMsgCode    - Message code returned by libjpeg-turbo library
 libjpegWarnBuffer - Message buffer filled by libjpeg-turbo library
 errWarnType       - Custom flag which specifies how to treat the messages
                     from the libjpeg-turbo library. The messages can treated as
                     errors, warnings or no-op.

*/
int jpegreader_getimagesize(const char* filename,
                            int32_t* imgDims,
                            int8_t* fileStatus,
                            int8_t* colorSpaceStatus,
                            int8_t* bitDepthStatus,
                            int32_t* libjpegMsgCode,
                            char* libjpegErrWarnBuffer,
                            int8_t* errWarnType) {
    /* This struct contains the JPEG decompression parameters and pointers to
     * working space (which is allocated as needed by the libjpeg-turbo library).
     */
    struct jpeg_decompress_struct cinfo;
    /* We use our private extension JPEG error handler.
     * Note that this struct must live as long as the main JPEG parameter
     * struct, to avoid dangling-pointer problems.
     */
    struct mw_error_mgr jerr;
    // Success or failure of libjpeg-turbo library call.
    int status = 0;

    FILE* infile;      /* source file */
    
    // Initialize status codes for FOPEN(), colorSpace, libjpeg
    // error/warn conditions.
    *(fileStatus) = (int8_t)(FILE_OPEN_SUCCESS);
    *(colorSpaceStatus) = (int8_t)(VALID_COLOR_SPACE);
    *(bitDepthStatus) = (int8_t)(BIT_DEPTH_SUPPORTED);
    jerr.err_warn_type = (int8_t)(IGNORE_MESSAGE_CODE);
    *(errWarnType) = jerr.err_warn_type;

    /* We want to open the input file before doing anything else,
     * so that the setjmp() error recovery below can assume the file is open.
     * Using "b" option to fopen() in case we are on a machine that
     * requires it in order to read binary files.
     */

    // Return -1 to indicate that file could not be opened
    if ((infile = fopen(filename, "rb")) == NULL) {
        *(fileStatus) = (int8_t)(FILE_OPEN_ERROR);
        *(libjpegMsgCode) = 0;
        strcpy(libjpegErrWarnBuffer, "");
        return -1;
    }

    /* Establish the setjmp return context for my_error_exit to use. */
    /* setjmp establishes the code that is to be executed after a call to longjmp is made
       in the my_error_exit error handling function */
    if (setjmp(jerr.setjmp_buffer)) {
        /* If we get here, the libjpeg-turbo code has signaled an error.
         * We need to clean up the JPEG object, close the input file, and return.
         */
        *(libjpegMsgCode) = cinfo.err->msg_code;
        *(errWarnType) = jerr.err_warn_type;
        strcpy(libjpegErrWarnBuffer, jerr.err_warn_buffer);
        jpeg_destroy_decompress(&cinfo);
        if (infile != NULL) {
            fclose(infile);
        }
        return -1;
    }

    initializeJPEG(&infile, libjpegMsgCode, libjpegErrWarnBuffer, errWarnType, &cinfo, &jerr);
    // Return -1 to indicate that file could not be opened or if jpeg_read_header failed.
    if (infile  == NULL) {
        return -1;
    }

    if (cinfo.data_precision != 8) {
        // codegen supported for 8-bit JPEG only
        *(bitDepthStatus) = (int8_t)(BIT_DEPTH_UNSUPPORTED);
        jpeg_destroy_decompress(&cinfo);
        fclose(infile);
        return -1;
    }


    jpeg_start_decompress(&cinfo);

    imgDims[0] = cinfo.output_height;
    imgDims[1] = cinfo.output_width;
    imgDims[2] = cinfo.output_components;

    // Only grayscale and RGB colorspaces are supported for codegen
    switch (cinfo.out_color_space) {
    case JCS_GRAYSCALE:
        break;

    case JCS_RGB:
        break;

    case JCS_CMYK:
        *(colorSpaceStatus) = (int8_t)(NO_CMYK_COLOR_SPACE);
        break;

    default:
        *(colorSpaceStatus) = (int8_t)(UNSUPPORTED_COLOR_SPACE);
        break;
    }

    *(errWarnType) = jerr.err_warn_type;
    *(libjpegMsgCode) = cinfo.err->msg_code;
    strcpy(libjpegErrWarnBuffer, jerr.err_warn_buffer);

    // Release JPEG decompression object
    jpeg_abort_decompress(&cinfo);
    jpeg_destroy_decompress(&cinfo);
    fclose(infile);

    return 0;
}


// jpegreader_uint8()
//
// jpegreader_uint8() reads the JPEG file, filename and fills the output
// buffer, img.
// It also returns status codes which are used to report any errors
// encountered when opening and reading the input file.
// They are as follows:
//
// fileStatus        - Custom flag which specifies whether file open
//                     operation was successful or not.
// libjpegReadDone   - Custom flag which specifies whether the jpeg file was
//                     read completely by libjpeg-turbo library.
// libjpegMsgCode    - Message code returned by libjpeg-turbo library
// libjpegWarnBuffer - Message buffer filled by libjpeg-turbo library
// errWarnType       - Custom flag which specifies how to treat the messages
//                     from the libjpeg-turbo library. The meesages can treated as
//                     errors, warnings or no-op.

int jpegreader_uint8(const char* filename,
                     uint8_t* img,
                     int8_t* fileStatus,
                     int8_t* libjpegReadDone,
                     int32_t* libjpegMsgCode,
                     char* libjpegErrWarnBuffer,
                     int8_t* errWarnType,
                     int8_t* runtimeFileDimsConsistent) {
    /* This struct contains the JPEG decompression parameters and pointers to
     * working space (which is allocated as needed by the libjpeg-turbo library).
     */
    struct jpeg_decompress_struct cinfo;
    /* We use our private extension libjpeg-turbo error handler.
     * Note that this struct must live as long as the main JPEG parameter
     * struct, to avoid dangling-pointer problems.
     */
    struct mw_error_mgr jerr;
    // Initialize status codes
    *(fileStatus) = (int8_t)(FILE_OPEN_SUCCESS);
    jerr.err_warn_type = (int8_t)(IGNORE_MESSAGE_CODE);
    *(errWarnType) = jerr.err_warn_type;
    *runtimeFileDimsConsistent = (int8_t)(FILEDIMS_CONSISTENT);

    FILE* infile;      /* source file */
    JSAMPARRAY buffer; /* Output row buffer */
    int row_stride = 0;    /* physical row width in output buffer */

    // Success or failure of libjpeg-turbo library call.
    int status;

     /* We want to open the input file before doing anything else,
     * so that the setjmp() error recovery below can assume the file is open.
     * Using "b" option to fopen() in case we are on a machine that
     * requires it in order to read binary files.
     */

    if ((infile = fopen(filename, "rb")) == NULL) {
        *(fileStatus) = (int8_t)(FILE_OPEN_ERROR);
        *(libjpegMsgCode) = 0;
        strcpy(libjpegErrWarnBuffer, "");
        return -1;
    }
	
    *(libjpegReadDone) = (int8_t)(READ_INCOMPLETE);

    /* Establish the setjmp return context for my_error_exit to use. */
    /* setjmp establishes the code that is to be executed after a call to longjmp is made
       in the my_error_exit error handling function */
    if (setjmp(jerr.setjmp_buffer)) {
        /* If we get here, the libjpeg-turbo code has signaled an error.
         * We need to clean up the JPEG object, close the input file, and return.
         */
        *(libjpegMsgCode) = cinfo.err->msg_code;
        strcpy(libjpegErrWarnBuffer, jerr.err_warn_buffer);
        // Value of jpegutils::err_warn_buffer is set in my_error_exit()
        *(errWarnType) = jerr.err_warn_type;

        jpeg_destroy_decompress(&cinfo);
        if (infile != NULL) {
            fclose(infile);
        }
        return -1;
    }
    
    initializeJPEG(&infile, libjpegMsgCode, libjpegErrWarnBuffer, errWarnType, &cinfo, &jerr);
    // Return -1 to indicate that file could not be opened or if jpeg_read_header failed.
    if (infile  == NULL) {
        return -1;
    }

    /* Start decompressor */

    (void)jpeg_start_decompress(&cinfo);
    /* We can ignore the return value since suspension is not possible
     * with the stdio data source.
     */

    /* JSAMPLEs per row in output buffer */
    row_stride = cinfo.output_width * cinfo.output_components;
    /* Make a one-row-high sample array that will go away when done with image */
    buffer = (JSAMPARRAY)(*cinfo.mem->alloc_sarray)((j_common_ptr)&cinfo, JPOOL_IMAGE, row_stride, 1);

    size_t totalSamplesPerRow = 3 * (size_t)cinfo.output_width;
    
    size_t planedims = (size_t)(cinfo.output_height * cinfo.output_width);
    uint8_t *pr_red, *pr_green, *pr_blue;
    uint8_t *pr_gray;

    switch (cinfo.out_color_space){
    case JCS_RGB: 
        pr_red = img;
        pr_green = pr_red + planedims;
        pr_blue = pr_red + (2 * planedims);
        ReadRGB8JPEG (&cinfo, buffer, pr_red, pr_green, pr_blue);
        break;

    case JCS_GRAYSCALE:
        pr_gray = img;
        ReadGrayscale8JPEG (&cinfo, buffer, pr_gray);
        break;

    default:
        jpeg_destroy_decompress(&cinfo);
        fclose(infile);
        return -1;

	}
	
	// Clean up

    jerr.read_done = (int8_t)(READ_COMPLETE);
    *(libjpegReadDone) = jerr.read_done;
    /* Finish decompression */

    (void)jpeg_finish_decompress(&cinfo);
    /* We can ignore the return value since suspension is not possible
     * with the stdio data source.
     */
    *(errWarnType) = jerr.err_warn_type;
    *(libjpegMsgCode) = cinfo.err->msg_code;
    strcpy(libjpegErrWarnBuffer, jerr.err_warn_buffer);
    /* Release JPEG decompression object */

    /* This is an important step since it will release a good deal of memory. */
    jpeg_destroy_decompress(&cinfo);

    /* After finish_decompress, we can close the input file.
     */
    fclose(infile);

    /* At this point you may want to check to see whether any corrupt-data
     * warnings occurred (test whether jerr.pub.num_warnings is nonzero).
     */

    return 0;
}

// Read helper method for 8 bit RGB JPEG images
void ReadRGB8JPEG (j_decompress_ptr cinfoPtr, JSAMPARRAY buffer, uint8_t *pr_red, uint8_t *pr_green, uint8_t *pr_blue){
    int i,j;
    size_t current_row = 0;
    /* Here we use the library's state variable cinfo.output_scanline as the
     * loop counter, so that we don't have to keep track ourselves.
     */
    while ((current_row = (size_t)(cinfoPtr->output_scanline)) < cinfoPtr->output_height) {
        /* jpeg_read_scanlines expects an array of pointers to scanlines.
         * Here the array is only one element long, but you could ask for
         * more than one scanline at a time if that's more convenient.
         */
        (void)jpeg_read_scanlines(cinfoPtr, buffer, 1);
        for (i = 0; i < cinfoPtr->output_width; i++) {
            j = i * (size_t)cinfoPtr->output_height + current_row;
            pr_red[j] = (uint8_t)buffer[0][i * 3 + 0];
            pr_green[j] = (uint8_t)buffer[0][i * 3 + 1];
            pr_blue[j] = (uint8_t)buffer[0][i * 3 + 2];
        }
    }
}


// Read helper method for 8 bit Grayscale JPEG images
void ReadGrayscale8JPEG (j_decompress_ptr cinfoPtr, JSAMPARRAY buffer, uint8_t *pr_gray){
	int i,j;
	size_t current_row = 0;
    /* Here we use the library's state variable cinfo.output_scanline as the
     * loop counter, so that we don't have to keep track ourselves.
     */
	while ((current_row = (size_t)(cinfoPtr->output_scanline)) < cinfoPtr->output_height) {
        /* jpeg_read_scanlines expects an array of pointers to scanlines.
         * Here the array is only one element long, but you could ask for
         * more than one scanline at a time if that's more convenient.
         */
        (void)jpeg_read_scanlines(cinfoPtr, buffer, 1);
        for (i = 0; i < cinfoPtr->output_width; i++) {
            j = i * (size_t)cinfoPtr->output_height + current_row;
            pr_gray[j] = (uint8_t) buffer[0][i];
        }
	}	
}
