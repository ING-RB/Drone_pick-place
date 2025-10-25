%#codegen
classdef API < coder.ExternalDependency
% matlab.internal.coder.API Helper class that updates the build 
% configuration for internal VideoReader for codegen

% Copyright 2019-2024 The MathWorks, Inc.

    % Implementation for coder.ExternalDependency
    methods(Static)
        function name = getDescriptiveName(~)
            name = 'MIVRAPI';
        end
        
        function tf = isSupportedContext(buildConfig)
            tf = buildConfig.isMatlabHostTarget(); % See also isCodeGenTarget()
        end
        
        function updateBuildInfo(buildInfo, buildConfig)
            % Link against the videoreader coder utilities module.
            [linkLibPath, linkLibExt, execLibExt, libPrefix] = buildConfig.getStdLibInfo();
            
            % Prefixes to use for third party libraries.
            if ispc()
                libPrefix3p = '';
            else
                libPrefix3p = 'lib';
            end
            
            mlBinPath = fullfile(matlabroot, 'bin', computer('arch'));
            
            % Add the include paths for utils
            includePath = fullfile(matlabroot, 'extern/include/multimedia');
            buildInfo.addIncludePaths(includePath, 'Multimedia Includes');
            
            % On Windows, don't use linkLibPath returned by getStdLibInfo because it
            % is the MATLAB sandbox lib directory and that is not where the lib of
            % the shipped product resides.
            if ispc()
                libDir = coder.internal.importLibDir(buildConfig);
                linkLibPath = fullfile(matlabroot, 'extern', 'lib', computer('arch'), libDir);
            end
            buildInfo.addLinkObjects([libPrefix 'videocoderutils' linkLibExt], linkLibPath, '', true, true);
            
            % Add the shared library dependencies that need to be packaged
            
            % Add the plugins
            [pluginsToUse, converterPlugin, nullPlugin] = ...
                                    matlab.internal.coder.getPlugins();
            
            for cnt = 1:numel(pluginsToUse)
                buildInfo.addNonBuildFiles(pluginsToUse{cnt}, '', 'Device Plugins');
            end
            
            buildInfo.addNonBuildFiles(converterPlugin, '', 'Converter Plugin');
            buildInfo.addNonBuildFiles(nullPlugin, '', 'Null Plugin');
            
            % Kakadu Library for MJ2000
            kduALib = [libPrefix3p 'kdu_a83R' execLibExt];
            kduVLib = [libPrefix3p 'kdu_v83R' execLibExt];
            
            buildInfo.addNonBuildFiles(kduALib, mlBinPath, 'Kakadu Libraries');
            buildInfo.addNonBuildFiles(kduVLib, mlBinPath, 'Kakadu Libraries');

            % libjpeg-turbo library for MJPEG
            % The shared libraries are named as follows:
            % windows:    mwjpeg62.dll
            % mac:        libmwjpeg.62.4.0.dylib
            % linux:      libmwjpeg.so.62.4.0
            if ispc()
                libjpegturboLib = ['mwjpeg62' execLibExt];
             % On linux and mac, we need to include the symlink as well as the
            % actual shared library for the packNgo makefile (which creates and
            % tests the executable from the generated code).  Otherwise, the
            % packNgo linker picks up the system jpeg library instead of
            % our libjpeg-turbo library.
 
            elseif ismac()
                libjpegturboLib = [libPrefix3p 'mwjpeg.' '62.4.0' execLibExt];
                libjpegturboLibSymLink = [libPrefix3p 'mwjpeg.' '62' execLibExt];
            elseif isunix()
                libjpegturboLib = [libPrefix3p 'mwjpeg' execLibExt '.62.4.0'];
                libjpegturboLibSymLink = [libPrefix3p 'mwjpeg' execLibExt '.62'];
            else
                assert(false, 'unexpected platform');
            end
                                        
            buildInfo.addNonBuildFiles(libjpegturboLib, mlBinPath, 'libjpeg-turbo Library');
            if (ismac() || isunix())
                buildInfo.addNonBuildFiles(libjpegturboLibSymLink, mlBinPath, 'libjpeg-turbo Library SymLink');
            end
            
            % All libraries that the plugins depend upon. 
            % Start with libraries that are required on all platforms
            smMultimediaLib = [libPrefix 'multimedia' execLibExt];
            buildInfo.addNonBuildFiles( smMultimediaLib, mlBinPath, ...
                                        'Shared Multimedia Common Libraries' );
                    
            smJPEGLib = [libPrefix 'shared_multimedia_utils_jpeg' execLibExt];
            buildInfo.addNonBuildFiles( smJPEGLib, mlBinPath, ...
                                        'Shared Multimedia utilities Libraries' );

            smAVILib = [libPrefix 'shared_multimedia_utils_avi' execLibExt];
            buildInfo.addNonBuildFiles( smAVILib, mlBinPath, ...
                                        'Shared Multimedia utilities Libraries' );

            smLFHLib = [libPrefix 'shared_multimedia_utils_local_file_handler' execLibExt];
            buildInfo.addNonBuildFiles( smLFHLib, mlBinPath, ...
                                        'Shared Multimedia utilities Libraries' );
            
            smExceptionsLib = [libPrefix 'multimediacommonexceptions' execLibExt];
            buildInfo.addNonBuildFiles( smExceptionsLib, mlBinPath, ...
                                        'Shared Multimedia Common Libraries' );
            
            smAVBufferLib = [libPrefix 'multimediacommonavbuffer' execLibExt];
            buildInfo.addNonBuildFiles( smAVBufferLib, mlBinPath, ...
                                        'Shared Multimedia Common Libraries' );
                    
            videoCoderUtilsLib = [libPrefix 'videocoderutils' execLibExt];
            buildInfo.addNonBuildFiles( videoCoderUtilsLib, mlBinPath, ...
                                        'Shared Multimedia Common Libraries' );
                                    
            % T&M Library Dependencies
            % Not adding asynciocoder and asynciocore as this is already
            % being done by the AsyncIO infrastructure. 
            tamimframeLib = [libPrefix 'tamimframe' execLibExt];
            buildInfo.addNonBuildFiles(tamimframeLib, mlBinPath, 'T&M Libraries');
                                        
            tamutilLib = [libPrefix 'tamutil' execLibExt];
            buildInfo.addNonBuildFiles(tamutilLib, mlBinPath, 'T&M Libraries');
                                        
            % Adding TBB for TAMIMFRAME
            if ismac()
                % need to use 'libtbb.12' and 'libtbbmalloc.2' for maca,
                % and use 'libttb.12.8' and 'libtbbmalloc.2.8' for maci
                if strcmp(computer('arch'), 'maca64')
                    tbbLib = 'libtbb.12.dylib';
                    tbbMallocLib = 'libtbbmalloc.2.dylib';
                else
                    tbbLib = 'libtbb.12.8.dylib';
                    tbbMallocLib = 'libtbbmalloc.2.8.dylib';
                end
            elseif ispc()
               tbbLib = 'tbb12.dll';
               tbbMallocLib = 'tbbmalloc.dll';
            else
                tbbLib = 'libtbb.so.12';
                tbbMallocLib = 'libtbbmalloc.so.2';
            end

            buildInfo.addNonBuildFiles(tbbLib, mlBinPath, 'T&M Libraries');
                buildInfo.addNonBuildFiles(tbbMallocLib, mlBinPath, 'T&M Libraries');
            % For faster permute operation
            flPermuteLib = ['libmwmfl_permute' execLibExt];
            buildInfo.addNonBuildFiles(flPermuteLib, mlBinPath, 'Math Foundation Libraries');

            % Add shared_multimedia_pluginInfo dependencies
            if ispc()
                mlsharedpluginInfo = ['plugininfo', execLibExt];
                buildInfo.addNonBuildFiles( mlsharedpluginInfo, mlBinPath, ...
                    'Shared Multimedia Plugin' );
            else
                mlsharedpluginInfo = [libPrefix, 'plugininfo', execLibExt];
                buildInfo.addNonBuildFiles(mlsharedpluginInfo, mlBinPath, 'Shared Multimedia Plugin');                     
            end

            % Windows specific dependencies
            if ispc()
                % For DirectShow Plugin
                tamMWDXLib = [libPrefix 'mwdx' execLibExt];
                buildInfo.addNonBuildFiles(tamMWDXLib, mlBinPath, 'T&M Libraries');
                mlsharedmfreaderImpl = ['libmwsharedmfreader' execLibExt];
                buildInfo.addNonBuildFiles( mlsharedmfreaderImpl, mlBinPath, ...
                    'Media Foundation Library implementation' );
                mlsharedDXreaderImpl = ['libmwshareddirectshowreader' execLibExt];
                buildInfo.addNonBuildFiles( mlsharedDXreaderImpl, mlBinPath, ...
                    'DirectShow Library implementation' );
            elseif ismac()
                % For AVFoundation Plugin
                flNativeStringLib = [libPrefix 'nativestrings' execLibExt];
                buildInfo.addNonBuildFiles(flNativeStringLib, mlBinPath, 'Foundation Libraries');                     
                mlsharedavfreaderImpl = ['libmwsharedavfreader' execLibExt];
                buildInfo.addNonBuildFiles( mlsharedavfreaderImpl, mlBinPath, ...
                    'AVFoundation Library implementation' );
            else
                % Linux specific dependencies
                 mlsharedgstreaderImpl = ['libmwsharedgstreader' execLibExt];
                buildInfo.addNonBuildFiles( mlsharedgstreaderImpl, mlBinPath, ...
                    'Gstreamer implementation' );
            end

            mlsharedmjpegavireaderImpl = ['libmwsharedmjpegavireader' execLibExt];
                buildInfo.addNonBuildFiles( mlsharedmjpegavireaderImpl, mlBinPath, ...
                    'Motion Jpeg avi reader implementation' );
                
            mlsharedmj2000readerImpl = ['libmwsharedmj2000reader' execLibExt];
                buildInfo.addNonBuildFiles( mlsharedmj2000readerImpl, mlBinPath, ...
                    'MJ2000 reader implementation' );
        end
    end
    
    % Utility functions
    methods(Static)

        function vidFrame = permute(inputFrame)
            % The Data of the input frame has dimensions
            % CHANS x WIDTH x HEIGHT. The output has dimensions HEIGHT x
            % WIDTH x CHANS.
            height = size(inputFrame.Data, 3);
            width = size(inputFrame.Data, 2);
            numChannels = size(inputFrame.Data, 1);
            dtype  = class(inputFrame.Data);

            sampleData = coder.nullcopy( zeros(height, width, numChannels, dtype) );
            vidFrame = struct('Data', sampleData, 'Timestamp', inputFrame.Timestamp);

            nDims = uint64(numel(size(inputFrame.Data)));
            inputDataDims = uint64([numChannels width height]);

            if contains(dtype, '8')
                numBytesPerVal = uint64(1);
            elseif contains(dtype, '16')
                numBytesPerVal = uint64(2);
            else
                numBytesPerVal = uint64(0);
            end

            perm = uint64([3 2 1]);

            coder.cinclude('coderutils_fcns.hpp');
            coder.ceval( 'coderPermute', ...
                         coder.rref(inputFrame.Data), ...
                         coder.ref(vidFrame.Data), ...
                         nDims, ...
                         coder.rref( inputDataDims, ...
                                     'like', coder.opaque('size_t', '0') ), ... % Do a pointer cast
                         coder.rref( perm, ...
                                     'like', coder.opaque('size_t', '0') ), ... % Do a pointer cast
                         numBytesPerVal );
        end

        function out = resolveValidPath(in)
            % Determine whether the full path specified works. If not,
            % strip out the path and only try the file name. This assumes
            % that the plugin should be in the current working directory.
            pathToPlugin = in;
            coder.varsize('pathToPlugin', [], [0 1]);
            for cntTry = 1:2
                out = matlabshared.asyncio.internal.coder.computeAbsolutePath(pathToPlugin);
                if ~isempty(out)
                    break;
                end
                pathToPlugin = matlab.internal.coder.API.fileparts(pathToPlugin);
            end
        end
        function [fileName, filePath] = fileparts(fullName)
            coder.extrinsic('filesep');
            fsep = coder.const(filesep);
            filesepLocs = strfind(fullName, fsep);
            lastFilesep = filesepLocs(end);
            
            fileName = fullName(lastFilesep+1:end);
            filePath = fullName(1:lastFilesep-1);
        end
    end

end
