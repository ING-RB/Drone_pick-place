classdef buildableTools
%#codegen

%   Copyright 2023-2024 The MathWorks, Inc.

    methods (Static)
        function [linkLibPath,binPath,dynExt] = addCodegenModule(cppmodulename,buildInfo,buildContext)
        % Link against the autonomouscodegen module.
            [linkLibPath,linkLibExt] = buildContext.getStdLibInfo();
            libname = ['libmw' cppmodulename];
            arch      = computer('arch');
            binPath   = fullfile(matlabroot,'bin',arch);
            sysOSArch = fullfile(matlabroot,'sys','os',arch);

            % On Windows, don't use linkLibPath returned by getStdLibInfo because it
            % is the MATLAB sandbox lib directory and that is not where the lib of
            % the shipped product resides.
            if ispc
                libDir = coder.internal.importLibDir(buildContext);
                linkLibPath = fullfile(matlabroot,'extern','lib',arch,libDir);
                dynExt = '.dll';
            else
                dynExt = linkLibExt;
            end
            buildInfo.addLinkObjects([libname linkLibExt], linkLibPath, [], true, true);

            % Include specific version of shared library we use in our
            % builtin modules
            switch arch
              case 'glnxa64'
                % Include libstdc++.so.6 on Linux, since we
                % are shipping a MathWorks specific version.
                libstdcppFull = {fullfile(sysOSArch, 'libstdc++.so.6')};
              otherwise
                libstdcppFull = '';
            end

            % Add cppmodule library to non-build files
            modulelibInfo = dir(fullfile(binPath, strcat(libname, '*')));
            modulelibFullPath = fullfile({modulelibInfo.folder}, {modulelibInfo.name});

            % Include all executable shared library in the non-build files
            nonBuildFiles = [libstdcppFull modulelibFullPath];
            buildInfo.addNonBuildFiles(nonBuildFiles, '', '');
        end
        function zlibname = getZLIBName()
            switch computer('arch')
              case ["maca64","linux-arm-32","linux-arm-64"]
                zlibname = 'libz';
              case ["win32","win64"]
                zlibname = 'zlib';
              otherwise
                % zlib is not shipped with product on these architectures, system zlib is used
                zlibname = '';
            end
        end
        function libpattern = getVDBLibraryNames(dynExt)
        %getVDBLibraryNames Get correct 3p library for current architecture
            libnames = {'zstd','blosc','openvdb','vdbfusion','tbb', 'mwboost_iostreams'};
            if ~any(strcmpi(computer('arch'), {'win32','win64'}))
                libnames = strcat('lib',libnames);
            end
            libpattern = strcat([libnames nav.geometry.internal.coder.buildableTools.getZLIBName],'*',dynExt,'*');
        end
    end
end
