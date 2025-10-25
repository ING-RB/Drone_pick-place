function timespec = makeTimespec(sec,nsec)
%MATLAB Code Generation Private Function

%   Copyright 2018-2022 The MathWorks, Inc.

%#codegen

if nargin < 1
    sec = coder.internal.indexInt(0);
end
if nargin < 2
    nsec = coder.internal.indexInt(0);
end
if (coder.internal.isTargetMATLABHost() || coder.target('rtwForRapid')) && coder.const(feval('ismac'))
    % Don't add POSIX define as the Mac headers don't work properly with it
    header = coder.internal.getCHeaderName('time');
else
    header = 'coder_posix_time.h';
    coder.updateBuildInfo('addIncludePaths', ...
                          coder.const(feval('coder.internal.externalDependencyDir','timefun')));
    if coder.target('rtwForRapid')
        % Need special group for rapid accelerator
        coder.updateBuildInfo('addDefines','_POSIX_C_SOURCE=199309L','OPTIMIZATION_FLAGS');
    else
        coder.updateBuildInfo('addDefines','_POSIX_C_SOURCE=199309L');
    end
end
timespec.tv_sec = cast(sec,'like',coder.opaque('time_t','0','HeaderFile',header));
timespec.tv_nsec = cast(nsec,'like',coder.opaque('long','0'));
cVarType = coder.internal.getCLibName('struct timespec');
coder.cstructname(timespec,cVarType,'extern','HeaderFile',header)

%--------------------------------------------------------------------------
