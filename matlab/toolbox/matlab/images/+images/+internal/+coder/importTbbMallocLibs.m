function nonBuildFiles = importTbbMallocLibs(nonBuildFiles, arch, pathBinArch, execLibExt)
% This function is used to query the TbbMalloc libs for specific platform and add
% as non-build files to the buildinfo

%   Copyright 2024 The MathWorks, Inc.
switch arch
    case {'win32','win64'}
        libNameNoExt = 'tbbmalloc';
        libExt = execLibExt; % '.dll' => tbbmalloc.dll
    case {'glnxa64'}
        libNameNoExt = 'libtbbmalloc';
        libExt = [execLibExt '.2']; % '.so.2' => libtbbmalloc.so.2
    case {'maci64'}
        libNameNoExt = 'libtbbmalloc';
        libExt = execLibExt; % '.dylib' => libtbbmalloc.dylib
    case {'maca64'}
        libNameNoExt = 'libtbbmalloc.2';
        libExt = execLibExt; % '.dylib' => libtbbmalloc.2.dylib
    otherwise
        % unsupported
        assert(false,[ arch ' operating system not supported']);
end
nonBuildFiles{end+1} = strcat(pathBinArch,libNameNoExt, libExt);