classdef ImreadJpegBuildable < coder.ExternalDependency %#codegen
    %IMREADJPEGBUILDABLE Encapsulate libmwjpegreader implementation 
    % library
    
    % Copyright 2015-2024 The MathWorks, Inc.
    
    
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'ImreadJpegBuildable';
        end
        
        function b = isSupportedContext(context)
            b = context.isMatlabHostTarget();
        end
        
        function updateBuildInfo(buildInfo, context)
            % File extensions
            [~, linkLibExt, execLibExt] = ...
                context.getStdLibInfo();
            group = 'BlockModules';
            
            % Header paths
            buildInfo.addIncludePaths(fullfile(matlabroot,'extern','include'));
            
            % Platform specific link and non-build files
            arch            = computer('arch');
            binArch         = fullfile(matlabroot,'bin',arch,filesep);
            sysOSArch = fullfile(matlabroot,'sys','os',arch,filesep);
            
            switch arch
                case {'win64'}
                    libDir          = coder.internal.importLibDir(context);
                    linkLibPath     = fullfile(matlabroot,'extern','lib',computer('arch'),libDir);
                    
                case {'glnxa64','maci64','maca64'}
                    linkLibPath     = binArch;
                                        
                otherwise
                    % unsupported
                    assert(false,[ arch ' operating system not supported']);
            end
            
            linkFiles       = {'libmwjpegreader'}; %#ok<*EMCA>
            linkFiles       = strcat(linkFiles, linkLibExt);
            linkPriority    = matlab.io.sharedimage.internal.coder.getLinkPriority('tbb');
            linkPrecompiled = true;
            linkLinkonly    = true;
            buildInfo.addLinkObjects(linkFiles,linkLibPath,linkPriority,...
                linkPrecompiled,linkLinkonly,group);

            % Non-build files
            if strcmp(arch,'glnxa64')
                libstdcpp          = strcat(sysOSArch,{'libstdc++.so.6'});
            else
                libstdcpp          = [];
            end
            
            % Add TBB
            if ispc()
                tbbLib = 'tbb12';
                tbbLib = strcat(binArch,tbbLib,execLibExt);
            elseif ismac()
                % need to use 'libtbb' for maci and use 'libtbb.12' for
                % maca for now
                if strcmp(arch,'maca64')
                    tbbLib = 'libtbb.12';
                else
                    tbbLib = 'libtbb';
                end
                tbbLib = strcat(binArch,tbbLib,execLibExt);
            else
                tbbLib = 'libtbb.so.12';
                tbbLib = strcat(binArch,tbbLib);
            end

            % Add libjpeg-turbo
            % The shared libraries are named as follows:
            % windows:    mwjpeg62.dll
            % mac:        libmwjpeg.62.4.0.dylib
            % linux:      libmwjpeg.so.62.4.0
            if ispc()
                libjpegturboLib = strcat(binArch,'mwjpeg62',execLibExt);
            % On linux and mac, we need to include the symlink as well as the
            % actual shared library for the packNgo makefile (which creates and
            % tests the executable from the generated code).  Otherwise, the
            % packNgo linker picks up the system jpeg library instead of
            % our libjpeg-turbo library.
            elseif ismac()
                libjpegturboLib = strcat(binArch,'libmwjpeg.62.4.0',execLibExt);
                libjpegturboLibSymLink = strcat(binArch,'libmwjpeg.62',execLibExt);
            elseif isunix()
                libjpegturboLib = strcat(binArch,'libmwjpeg.so.62.4.0');
                libjpegturboLibSymLink = strcat(binArch,'libmwjpeg.so.62');
            else
                assert(false, 'unexpected platform');
            end
            
            nonBuildFilesExt = {'libmwjpegreader','libmwmfl_permute'};
            nonBuildFilesExt = strcat(binArch,nonBuildFilesExt, execLibExt);

            % Add the license file for libjpeg-turbo
            rightsFile = strcat(binArch,'libjpeg-turbo.rights');

            if (ispc())
                nonBuildFilesExt = [libstdcpp nonBuildFilesExt tbbLib, libjpegturboLib, rightsFile];
            elseif (ismac() || isunix())
                nonBuildFilesExt = [libstdcpp nonBuildFilesExt tbbLib, libjpegturboLib, libjpegturboLibSymLink, rightsFile];
            end

            nonBuildFiles = nonBuildFilesExt;
            buildInfo.addNonBuildFiles(nonBuildFiles,'',group);
            
        end
        
        function [outDims, fileStatus, colorSpaceStatus, bitDepthStatus, msgCode, warnBuffer, warnBufferFlag]...
                = jpegreadercore_getimagesize(fcnName,fname, outDims, fileStatus, colorSpaceStatus, bitDepthStatus, msgCode, warnBuffer, warnBufferFlag)
             
            coder.inline('always');
            coder.cinclude('libmwjpegreader.h');
            coder.ceval(fcnName,...%'jpegreader_getimagesize',...
                coder.rref(fname),...
                coder.ref(outDims),...
                coder.ref(fileStatus),...
                coder.ref(colorSpaceStatus),...
                coder.ref(bitDepthStatus),...
                coder.ref(msgCode),...
                coder.ref(warnBuffer),...
                coder.ref(warnBufferFlag));
        end
        
        function [out, fileStatus, libjpegReadDone, msgCode, warnBuffer,warnBufferFlag, runtimeFileDimsConsistency] = jpegreadercore_uint8(fcnName,fname, out, outDims, outNumDims, fileStatus, libjpegReadDone, msgCode, warnBuffer,warnBufferFlag, runtimeFileDimsConsistency)
            coder.inline('always');
            coder.cinclude('libmwjpegreader.h');
            coder.ceval(fcnName,...%'jpegreader_uint8',...
                coder.rref(fname),...
                coder.ref(out),...
                coder.rref(outDims),...
                outNumDims,...
                coder.ref(fileStatus),...
                coder.ref(libjpegReadDone),...
                coder.ref(msgCode),...
                coder.ref(warnBuffer),...
                coder.ref(warnBufferFlag),...
                coder.ref(runtimeFileDimsConsistency));
        end
        
        
    end
    
    
end
