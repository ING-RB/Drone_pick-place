/**
 * @file:    mexfcns.h
 *
 * Purpose:  Helper function for path search in MCR.
 *
 * Authors:  Feng Han
 *
 * Copyright 2022 The MathWorks, Inc.
 */

#pragma once

#ifdef __cplusplus
extern "C" {
#endif 
	/**
	 * Find directory path for aim files.
	 *
	 *  When transplant a function or MCR. Find the location for aim
	 * filepath. Given the end path, the function can find the root
	 * path for that file and update the input Filepath string.
	 *
	 * @param originalPath: String of the original aim file path. 
	 *        destination: String to store the aim file path.
	 *
	 * @return None.
	 */
	void replacePath(const char* originalPath, char** destination);
	/**
	 * Get the lenght of the aiming path for memory allocation use.
	 *
	 * @param originalPath: String of the original aim file path. 
	 *
	 * @return return the length of the path after update.
	 */
	int getReplacePathLength(const char* originalPath);

#ifdef __cplusplus
}
#endif