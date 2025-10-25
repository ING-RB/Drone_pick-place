function nonBuildFiles = importTbbLibs(nonBuildFiles, arch, pathBinArch, execLibExt)
% This function is used to query the Tbb libs for specific platform and add
% as non-build files to the buildinfo

%   Copyright 2024 The MathWorks, Inc.

switch arch
    case {'win32','win64'}
        libNameNoExt = 'tbb12';
        libExt = execLibExt; % '.dll' => tbb12.dll
    case {'glnxa64'}
        libNameNoExt = 'libtbb';
        libExt = [execLibExt '.12']; % '.so.12' => libtbb.so.12
    case {'maci64'}
        libNameNoExt = 'libtbb';
        libExt = execLibExt; % '.dylib' => libtbb.dylib
    case {'maca64'}
        libNameNoExt = 'libtbb.12';
        libExt = execLibExt; % '.dylib' => libtbb.12.dylib
    otherwise
        % unsupported
        assert(false,[ arch ' operating system not supported']);
end
nonBuildFiles{end+1} = strcat(pathBinArch,libNameNoExt, libExt);