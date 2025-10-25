classdef CoderTimeAPI < coder.ExternalDependency & coder.internal.JITSupportedExternalDependency
%MATLAB Code Generation Private Class

%   Copyright 2020-2021 The MathWorks, Inc.
%#codegen
    properties (Constant)
        HeaderFile = 'coder_posix_time.h';
        SourceFile = 'coder_posix_time.c';
        ExternalDependencyDir = fullfile(matlabroot, 'toolbox', 'eml', 'externalDependency','timefun');
    end

    % API methods
    methods (Static)
        function t = getTime()
            % Returns a MATLAB struct emulating the output of the POSIX clock_gettime function
            % by calling EMLRT, or coder_posix_time.h
            %
            %   t.tv_nsec - double
            %   t.tv_sec - double
            if coder.internal.runs_in_matlab()
                t = coder.internal.time.CoderTimeAPI.callEMLRTClockGettime();
            else
                t = timespecToMATLABTimespec(coder.internal.time.CoderTimeAPI.callCoderClockGettime());
            end
        end

        function t = getLocalTime()
            % Returns a MATLAB struct emulating the output of the C localtime function
            % with an added nanoseconds field for better precision:
            %
            %   structTm.tm_nsec
            %   structTm.tm_sec
            %   structTm.tm_min
            %   structTm.tm_hour
            %   structTm.tm_mday
            %   structTm.tm_mon
            %   structTm.tm_year
            %   structTm.tm_isdst

            % tm_year and tm_mon are offset from C by 1900 and 1 respectively to
            % give real-world values for the year and month.
            if coder.internal.runs_in_matlab()
                structTm = makeEMLRTStructTm();
                coder.ceval('-jit','emlrtWallclock',coder.wref(structTm));
                t = structTm;
            else
                structTm = makeStructTm();
                status = coder.internal.indexInt(0);
                status = coder.ceval('coderLocalTime', coder.wref(structTm));
                coderTimeCheckStatus('coderLocalTime', status);
                t = tmToMATLABTimespec(structTm);
            end
        end

        function durationPauseImpl(delayInt, delayNano)
            if coder.internal.runs_in_matlab()
                coder.internal.errorIf(coder.internal.canUseExtrinsic(), ...
                                       'Coder:builtins:Explicit', ...
                                       'Internal error: Should have used extrinsic pause');
                sleepFcn = @cDurationPauseEMLRT;
            else
                sleepFcn = @cDurationPauseCoder;
            end
            sleepFcn(delayInt,delayNano);
        end
    end

    methods(Static, Hidden)
        function name = getDescriptiveName(~)
            name = 'CoderTimeAPI';
        end

        function supported = isSupportedContext(~)
            supported = true;
        end

        function updateBuildInfo(buildInfo, buildConfig)
            arguments
                buildInfo RTW.BuildInfo
                buildConfig coder.BuildConfig
            end
            if buildConfig.CodeGenTarget == "mex" || buildConfig.CodeGenTarget == "sfun"
                return
            else
                if buildConfig.CanCopyToBuildDir
                    bldDir = buildConfig.getBuildDir();
                    coder.internal.time.CoderTimeAPI.copyHeader(bldDir);
                    coder.internal.time.CoderTimeAPI.copySource(bldDir);
                    codeDir = bldDir;
                else
                    % We can't copy to the build folder in some contexts. So just add the files from MATLABROOT
                    codeDir = coder.internal.time.CoderTimeAPI.ExternalDependencyDir;
                    buildInfo.addIncludePaths(codeDir);
                end
                buildInfo.addSourceFiles(coder.internal.time.CoderTimeAPI.SourceFile, codeDir);
                buildInfo.addIncludeFiles(coder.internal.time.CoderTimeAPI.HeaderFile, codeDir);
            end
        end
    end

    methods(Static, Access = private)
        function copyHeader(bldDir)
            file = coder.internal.time.CoderTimeAPI.HeaderFile;
            header = fullfile(coder.internal.time.CoderTimeAPI.ExternalDependencyDir,file);
            copyfileAndMakeWriteable(header, fullfile(bldDir, file));
        end

        function copySource(bldDir)
            file = coder.internal.time.CoderTimeAPI.SourceFile;
            source = fullfile(coder.internal.time.CoderTimeAPI.ExternalDependencyDir,file);
            copyfileAndMakeWriteable(source, fullfile(bldDir, file));
        end

        function timespec = callCoderClockGettime()
            % Returns a MATLAB struct emulating the output of the POSIX clock_gettime function:
            %
            %   t.tv_nsec - coder.opaque('long')
            %   t.tv_sec - coder.opaque('time_t')
            coder.internal.errorIf(coder.internal.runs_in_matlab(), 'Coder:builtins:Explicit', ...
                'Internal error: This function is not supported when running in MATLAB. E.g. MEX, SIM, etc. Use callEMLRTClockGettime instead');
            coder.cinclude('coder_posix_time.h');
            persistent freq;
            if isempty(freq)
                freq = 0;
                status = coder.internal.indexInt(0);
                status = coder.ceval('coderInitTimeFunctions', coder.wref(freq));
                coderTimeCheckStatus('coderInitTimeFunctions',status);
            end
            timespec = makeTimespec();
            status = coder.internal.indexInt(0);
            status = coder.ceval('coderTimeClockGettimeMonotonic', ...
                coder.wref(timespec), freq);
            coderTimeCheckStatus('coderTimeClockGettimeMonotonic',status);
        end

        function timespec = callEMLRTClockGettime()
            % Returns a MATLAB struct emulating the output of the POSIX clock_gettime function
            % by calling EMLRT
            %
            %   t.tv_nsec - coder.opaque('long')
            %   t.tv_sec - coder.opaque('time_t')
            coder.internal.assert(coder.internal.runs_in_matlab(), 'Coder:builtins:Explicit', ...
                'Internal error: This function is only supported when running in MATLAB. E.g. MEX, SIM, etc.');
            timespec = makeEMLRTTimespec();
            status = coder.internal.indexInt(0);
            status = coder.ceval('-jit','emlrtClockGettimeMonotonic', ...
                coder.wref(timespec));
            coderTimeCheckStatus('emlrtClockGettimeMonotonic',status);
        end
    end
end

%--------------------------------------------------------------------------

function coderTimeCheckStatus(fcn,status)
    % Check the status code from a coder_posix_time.h API
    if status ~= zeros('like',status)
        if coder.internal.hasRuntimeErrors()
            coder.internal.error('Coder:toolbox:CoderTimeCallFailed',fcn,status);
        end
    end
end

%--------------------------------------------------------------------------

function structTm = makeEMLRTStructTm()
    structTm = struct("tm_nsec", 0, ...
        "tm_sec", 0, ...
        "tm_min", 0, ...
        "tm_hour", 0, ...
        "tm_mday", 0, ...
        "tm_mon", 0, ...
        "tm_year", 0, ...
        "tm_isdst", false);

    coder.cstructname(structTm,'emlrtStructTm','extern','HeaderFile','emlrt.h');
end

%--------------------------------------------------------------------------

function structTm = makeStructTm()
    % Returns a struct that matches the C struct tm with all fields set to 0.
    %
    % struct tm {
    %     long tm_nsec;       /* nanoseconds */
    %     int tm_sec;         /* seconds */
    %     int tm_min;         /* minutes */
    %     int tm_hour;        /* hours */
    %     int tm_mday;        /* day of the month */
    %     int tm_mon;         /* month */
    %     int tm_year;        /* year */
    %     int tm_wday;        /* day of the week */
    %     int tm_yday;        /* day in the year */
    %     int tm_isdst;       /* daylight saving time */
    % };
    ZERO = coder.internal.indexInt(0);
    structTm.tm_nsec = coder.opaque('long','0');
    structTm.tm_sec = ZERO;
    structTm.tm_min = ZERO;
    structTm.tm_hour = ZERO;
    structTm.tm_mday = ZERO;
    structTm.tm_mon = ZERO;
    structTm.tm_year = ZERO;
    structTm.tm_wday = ZERO;
    structTm.tm_yday = ZERO;
    structTm.tm_isdst = ZERO;

    coder.cstructname(structTm,'coderTm','extern','HeaderFile', coder.internal.time.CoderTimeAPI.HeaderFile);
end

%--------------------------------------------------------------------------

function timespec = timespecToMATLABTimespec(origTimespec)
    % Normalize the timespec to something that contains primitive data. Since we need to use floating
    % point arithmetic to compute the elapsed time, we just use double here.
    timespec.tv_sec = double(origTimespec.tv_sec);
    timespec.tv_nsec = double(origTimespec.tv_nsec);
end

%--------------------------------------------------------------------------

function structTm = tmToMATLABTimespec(origStructTm)
    % Normalize the timespec to something that contains primitive data. Since we need to use floating
    % point arithmetic to compute the elapsed time, we just use double here.
    structTm.tm_nsec = double(origStructTm.tm_nsec);
    structTm.tm_sec = double(origStructTm.tm_sec);
    structTm.tm_min = double(origStructTm.tm_min);
    structTm.tm_hour = double(origStructTm.tm_hour);
    structTm.tm_mday = double(origStructTm.tm_mday);
    structTm.tm_mon = double(origStructTm.tm_mon);
    structTm.tm_year = double(origStructTm.tm_year);
    structTm.tm_isdst = logical(origStructTm.tm_isdst);
end

%--------------------------------------------------------------------------

function cDurationPauseEMLRT(delayInt,delayNano,~)
    timespec = makeEMLRTTimespec(delayInt,delayNano);
    status = coder.internal.indexInt(0);
    status = coder.ceval('-jit','emlrtSleep',coder.rref(timespec)); %#ok
end

%--------------------------------------------------------------------------

function cDurationPauseCoder(delayInt,delayNano,~)
    timespec = makeTimespec(delayInt,delayNano);
    status = coder.internal.indexInt(0);
    status = coder.ceval('coderTimeSleep',coder.rref(timespec)); %#ok
end

%--------------------------------------------------------------------------

function timespec = makeEMLRTTimespec(sec,nsec)
    if nargin < 1
        sec = coder.internal.indexInt(0);
    end
    if nargin < 2
        nsec = coder.internal.indexInt(0);
    end
    timespec.tv_sec = double(sec);
    timespec.tv_nsec = double(nsec);
    coder.cstructname(timespec,'emlrtTimespec','extern','HeaderFile','emlrt.h');

end

%--------------------------------------------------------------------------

function timespec = makeTimespec(sec,nsec)
    if nargin < 1
        sec = coder.internal.indexInt(0);
    end
    if nargin < 2
        nsec = coder.internal.indexInt(0);
    end

    timespec.tv_sec = double(sec);
    timespec.tv_nsec = double(nsec);
    coder.cstructname(timespec,'coderTimespec','extern','HeaderFile',coder.internal.time.CoderTimeAPI.HeaderFile);
end

%--------------------------------------------------------------------------

function copyfileAndMakeWriteable(srcFile, destFile)
    copyfile(srcFile, destFile, "f");
    try %#ok<EMTC>
        if ispc
            u = "";
        else
            u = "u";
        end
        fileattrib(destFile, "+w", u);
    catch
    end
end

%--------------------------------------------------------------------------
