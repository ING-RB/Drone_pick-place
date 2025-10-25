/* Copyright 2019-2024 The MathWorks, Inc. */
#include "MWRuntimeLogUtility.hpp"

#include <stdio.h>
#include <time.h>

void mwGpuCoderRuntimeLog(const char* msg) {
    time_t currentTime;
    struct tm* timeinfo = NULL;
    const char* logFileName = "gpucoder_runtime_log.txt";
    FILE* fp = fopen(logFileName, "a");
    if (fp == NULL) {
        printf("Error opening %s\n", logFileName);
        return;
    }
    time(&currentTime);
    timeinfo = localtime(&currentTime);
    fprintf(fp, "%s%s\n", asctime(timeinfo), msg);
    fclose(fp);
}
