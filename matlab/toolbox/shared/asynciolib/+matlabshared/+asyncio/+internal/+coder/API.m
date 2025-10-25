classdef API < coder.ExternalDependency
%

% Copyright 2018-2024 The MathWorks, Inc.

%#codegen

% Implementation of coder.ExternalDependency
    methods(Static)
        function name = getDescriptiveName(~)
            name = 'AsyncIOAPI';
        end

        function tf = isSupportedContext(buildCconfig)
            tf = buildCconfig.isMatlabHostTarget(); % See also isCodeGenTarget()
        end

        function updateBuildInfo(buildInfo, buildConfig)

        % Add include path for asynciocoder API.
            includePath = fullfile(matlabroot, 'extern/include/AsyncIO');
            buildInfo.addIncludePaths(includePath, 'AsyncIO Includes');

            % Link against the asynciocoder module.
            [linkLibPath,linkLibExt,exeLibExt,libPrefix] = buildConfig.getStdLibInfo();

            % Platform specific link and non-build files
            arch      = computer('arch');
            sysOSArch = fullfile(matlabroot,'sys','os',arch,filesep);
            libstdcpp = [];
            % include libstdc++.so.6 on linux.
            if strcmp(arch,'glnxa64')
                % Unless there is a huge change in the compiler this softlink doesn't change.
                libstdcpp = strcat(sysOSArch,{'libstdc++.so.6'});
            end

            % On Windows, don't use linkLibPath returned by getStdLibInfo because it
            % is the MATLAB sandbox lib directory and that is not where the lib of
            % the shipped product resides.
            if ispc()
                libDir = coder.internal.importLibDir(buildConfig);
                linkLibPath = fullfile(matlabroot,'extern','lib',computer('arch'),libDir);
            end
            buildInfo.addLinkObjects([libPrefix 'asynciocoder' linkLibExt], linkLibPath, '', true, true);

            if strcmp(arch,'glnxa64')
                % Non-build files
                nonBuildFiles = libstdcpp{1};
                buildInfo.addNonBuildFiles(nonBuildFiles, '','');
            end

            % Add asynciocoder for PackNGo.
            mlBinPath = fullfile(matlabroot, 'bin', computer('arch'));
            buildInfo.addNonBuildFiles( [libPrefix 'asynciocoder' exeLibExt],...
                                        mlBinPath, 'Asyncio Libraries');

            % Add asynciocore and dependencies for PackNGo.
            buildInfo.addNonBuildFiles( [libPrefix 'asynciocore' exeLibExt],...
                                        mlBinPath, 'Asyncio Libraries');
            buildInfo.addNonBuildFiles( ['libmwfoundation_matlabdata' exeLibExt],...
                                        mlBinPath, 'Foundation Libraries');
            buildInfo.addNonBuildFiles( ['libmwfoundation_matlabdata_standalone' exeLibExt],...
                                        mlBinPath, 'Foundation Libraries');
            buildInfo.addNonBuildFiles( ['libmwfoundation_log' exeLibExt],...
                                        mlBinPath, 'Foundation logging Libraries');
            buildInfo.addNonBuildFiles( [libPrefix 'tamutil' exeLibExt],...
                                        mlBinPath, 'Asyncio Libraries');

            libssl = '';
            libcrypto = '';
            switch arch
              case 'win64'
                libssl =    ['libssl-3-x64-mw' exeLibExt];
                libcrypto = ['libcrypto-3-x64-mw' exeLibExt];

              case 'glnxa64'
                libssl =    ['libssl-mw' exeLibExt '.3'];
                libcrypto = ['libcrypto-mw' exeLibExt '.3'];

              case {'maca64', 'maci64'}
                libssl =    ['libssl.3' exeLibExt];
                libcrypto = ['libcrypto.3' exeLibExt];
            end

            buildInfo.addNonBuildFiles( libssl,...
                                        mlBinPath, 'Plugin Codesignature Verification');
            buildInfo.addNonBuildFiles( libcrypto,...
                                        mlBinPath, 'Plugin Codesignature Verification');


            % Nested functions to capture mlBinPath and exeLibExt and call
            % to static methods.
            function libName = makeBoostLibName(baseName)
                libName = matlabshared.asyncio.internal.coder.API.makeBoostLibName(baseName, mlBinPath, exeLibExt);
            end

            function libName = makeIcuLibName(baseName)
                libName = matlabshared.asyncio.internal.coder.API.makeIcuLibName(baseName, mlBinPath, exeLibExt);
            end

            function libName = makeExpatLibName()
                libName = matlabshared.asyncio.internal.coder.API.makeExpatLibName(mlBinPath, exeLibExt);
            end

            % Boost
            buildInfo.addNonBuildFiles( makeBoostLibName('thread'), mlBinPath, 'Boost');
            buildInfo.addNonBuildFiles( makeBoostLibName('chrono'), mlBinPath, 'Boost');
            buildInfo.addNonBuildFiles( makeBoostLibName('date_time'), mlBinPath, 'Boost');
            buildInfo.addNonBuildFiles( makeBoostLibName('system'), mlBinPath, 'Boost');
            buildInfo.addNonBuildFiles( makeBoostLibName('log'), mlBinPath, 'Boost'); % Required by libmwfoundation_log
            buildInfo.addNonBuildFiles( makeBoostLibName('serialization'), mlBinPath, 'Boost'); % Required by mwboost_log

            % I18n and it's dependencies (yuck)
            % See toolbox/imaq/imaqblks/rules/sfcnrules.gnu for reference.
            buildInfo.addNonBuildFiles( ['libmwi18n' exeLibExt],...
                                        mlBinPath, 'Foundation Libraries');
            buildInfo.addNonBuildFiles( ['libmwfoundation_filesystem' exeLibExt],...
                                        mlBinPath, 'Foundation Libraries');
            if(isunix() && ~ismac()) %linux
                buildInfo.addNonBuildFiles( ['libmwlocale' exeLibExt],...
                                            mlBinPath, 'Foundation Libraries');
            end
            buildInfo.addNonBuildFiles( ['libmwresource_core' exeLibExt],...
                                        mlBinPath, 'Foundation Libraries');
            buildInfo.addNonBuildFiles( ['libmwcpp11compat' exeLibExt],...
                                        mlBinPath, 'Foundation Libraries');
            % ICU
            buildInfo.addNonBuildFiles( makeIcuLibName('uc'),...
                                        mlBinPath, 'Foundation Libraries');
            buildInfo.addNonBuildFiles( makeIcuLibName('io'),...
                                        mlBinPath, 'Foundation Libraries');
            if ispc()
                buildInfo.addNonBuildFiles( makeIcuLibName('in'),...
                                            mlBinPath, 'Foundation Libraries');
                buildInfo.addNonBuildFiles( makeIcuLibName('dt'),...
                                            mlBinPath, 'Foundation Libraries');
            else
                buildInfo.addNonBuildFiles( makeIcuLibName('i18n'),...
                                            mlBinPath, 'Foundation Libraries');
                buildInfo.addNonBuildFiles( makeIcuLibName('data'),...
                                            mlBinPath, 'Foundation Libraries');
            end
            % Expat
            buildInfo.addNonBuildFiles( makeExpatLibName(),...
                                        mlBinPath, 'Foundation Libraries');
            % Don't think this is needed.
            %buildInfo.addNonBuildFiles( 'icudtl.dat',...
            %                        mlBinPath, 'Foundation Libraries');

            % Boost
            buildInfo.addNonBuildFiles( makeBoostLibName('filesystem'), mlBinPath, 'Boost');
            % boost_atomic library is needed by boost_filesystem.
            buildInfo.addNonBuildFiles( makeBoostLibName('atomic'), mlBinPath, 'Boost');
        end
    end

    methods(Static)
        function libName = makeBoostLibName(libNameRoot, mlBinPath, exeLibExt)
        % See BOOST_MAKE_SONAME in makerules/boostrules.gnu
        % Win   mwboost_<root>-<ver>.dll
        % Mac   libmwboost_<root>.dylib
        % Linux libmwboost_<root>.so.<ver>
            if ispc()
                libPrefix = '';
            else
                libPrefix = 'lib';
            end
            if strncmpi(computer('arch'),'glnx', 4)  % islinux()
                libPattern = [exeLibExt '.*']; % Version after the extension
            elseif ismac()
                libPattern = exeLibExt; % No version.
            elseif ispc()
                libPattern = ['-*' exeLibExt]; % Version before the extension.
            else
                assert(false, 'unexpected platform');
            end

            libNamePattern = [libPrefix 'mwboost_' libNameRoot libPattern];
            dirInfo = dir(fullfile(mlBinPath, libNamePattern));
            assert(isscalar(dirInfo), 'expecting only one match for boost');
            libName = dirInfo(1).name;
        end

        function libName = makeIcuLibName(libNameRoot, mlBinPath, exeLibExt)
        % See ICU_MAKE_SONAME in makerules/icurules.gnu.
        % TODO: Use ICU_MAKE_SONAME in our makefile to autogenerate
        % the ICU names on the various platforms into a file and then
        % load them here.

        % Win   icu<root><majorver>.dll
        % Mac   libicu<root><majorver>.dylib
        % Linux libicu<root>.so.<majorver>
            if ispc()
                libPrefix = '';
            else
                libPrefix = 'lib';
            end
            if strncmpi(computer('arch'),'glnx', 4)  % islinux()
                libPattern = [exeLibExt '.*']; % Version(s) after the extension
            elseif ismac()
                libPattern = ['.*' exeLibExt]; % Version(s) before the extension
            elseif ispc()
                libPattern = ['*' exeLibExt]; % Version before the extension
            else
                assert(false, 'unexpected platform');
            end
            libNamePattern = [libPrefix 'icu' libNameRoot libPattern];
            dirInfo = dir(fullfile(mlBinPath, libNamePattern));

            % There might be more than one for two reasons:
            % 1) On Linux/Mac there are symlinks that include major.minor
            %    version numbers.
            % 2) There may be multiple versions present during an ICU
            %    transition (until a sterile build is done).
            % Therefore, take the shortest one to deal with 1) and
            % the lengths are the same, and then take the one that is
            % "greatest" to get the highest major version number.
            libName = dirInfo(1).name;
            for i=2:length(dirInfo)
                nextName = dirInfo(i).name;
                if length(nextName) < length(libName)
                    libName = nextName;
                end
            end
            for i=1:length(dirInfo)
                nextName = dirInfo(i).name;
                if length(nextName) == length(libName)
                    if string(nextName) > string(libName)
                        libName = nextName;
                    end
                end
            end
        end

        function libName = makeExpatLibName(mlBinPath, exeLibExt)
            libNameRoot = 'expat';
            libPrefix = 'lib';
            if strncmpi(computer('arch'),'glnx', 4)  % islinux()
                libPattern = [exeLibExt '.*'];
            elseif ispc() || ismac()
                % Covers all variants, for example, libexpat.dylib, libexpat.1.dylib and libexpat.1.8.10.dylib.
                libPattern = ['*' exeLibExt];
            else
                assert(false, 'unexpected platform');
            end
            libNamePattern = [libPrefix libNameRoot libPattern];
            dirInfo = dir(fullfile(mlBinPath, libNamePattern));
            assert(~isempty(dirInfo), 'expecting at least 1 match for expat');
            if isempty(dirInfo)
                libName = '';
            else
                % addNonBuildFiles accepts cell array of chars to add multiple files.
                libName = cell(1, length(dirInfo));
                % add all variants to ensure availability of actual library and soft links to ensure the application works and addresses dependencies.
                for libIndex = 1:length(dirInfo)
                    libName{1, libIndex} = dirInfo(libIndex).name;
                end
            end
        end
    end

    % Wrappers that delegate to the asynciocoder module.
    methods(Static)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Channel Lifetime
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [chImpl, errorID, errorText] = channelCreate(devicePluginPath, converterPluginPath, streamLimits)
        % Create the channel implementation.
            coder.cinclude('asynciocoder_api.hpp');
            chImpl = matlabshared.asyncio.internal.coder.API.getNullChannel();
            errorID = blanks(1024);
            errorText = blanks(1024);
            devicePluginPath = matlabshared.asyncio.internal.coder.API.terminateString(devicePluginPath);
            converterPluginPath = matlabshared.asyncio.internal.coder.API.terminateString(converterPluginPath);
            chImpl = coder.ceval('coderChannelCreate',...
                                 devicePluginPath,...
                                 converterPluginPath,...
                                 streamLimits(1),...
                                 streamLimits(2),...
                                 coder.wref(errorID),....
                                 coder.wref(errorText));
            if chImpl == matlabshared.asyncio.internal.coder.API.getNullChannel()
                matlabshared.asyncio.internal.coder.API.dispatchInternalError(errorID, errorText);
            end
        end

        function channelDestroy(chImpl)
        % Delete underlying channel implementation.
            coder.cinclude('asynciocoder_api.hpp');
            coder.ceval('coderChannelDestroy', chImpl);
        end

        function chImpl = getNullChannel()
        % Possible return value from channelCreate
            chImpl = coder.opaque('CoderChannel', '0', 'HeaderFile', 'asynciocoder_api.hpp');
        end

        function streamImpl = getNullInputStream()
        % Possible return value from channelGetInputStream
            streamImpl = coder.opaque('CoderInputStream', '0', 'HeaderFile', 'asynciocoder_api.hpp');
        end

        function streamImpl = getNullOutputStream()
        % Possible return value from channelGetOutputStream
            streamImpl = coder.opaque('CoderOutputStream', '0', 'HeaderFile', 'asynciocoder_api.hpp');
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Channel Getter/Setters
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function result = channelIsOpen(chImpl)
        % Test is channel is open
            coder.cinclude('asynciocoder_api.hpp');
            result = false;
            success = int32(0);
            success = coder.ceval('coderChannelIsOpen', chImpl, coder.wref(result));
            matlabshared.asyncio.internal.coder.API.channelErrorIfFailed(chImpl, success);
        end

        function tf = channelHasPropertyValue(chImpl, propName, exampleValue)
        % Attempt to get the property value from the channel and
        % examine if it is was successful
            coder.cinclude('asynciocoder_api.hpp');
            value = exampleValue;
            success = int32(0);

            layout = matlabshared.asyncio.internal.coder.API.computeDataLayout();
            success = coder.ceval(layout, ...
                                  'coderChannelGetPropertyValue', chImpl,...
                                  coder.internal.stringConst(propName), ...
                                  coder.internal.stringConst(class(exampleValue)),...
                                  coder.internal.indexInt(numel(exampleValue)),...
                                  coder.ref(value));
            tf = (success ~= 0);
        end

        function value = channelGetPropertyValue(chImpl, propName, exampleValue)
        % Get the given property value
            coder.cinclude('asynciocoder_api.hpp');
            value = exampleValue;
            success = int32(0);

            layout = matlabshared.asyncio.internal.coder.API.computeDataLayout();
            success = coder.ceval(layout, ...
                                  'coderChannelGetPropertyValue', chImpl,...
                                  coder.internal.stringConst(propName), ...
                                  coder.internal.stringConst(class(exampleValue)),...
                                  coder.internal.indexInt(numel(exampleValue)),...
                                  coder.ref(value));
            matlabshared.asyncio.internal.coder.API.channelErrorIfFailed(chImpl, success);
        end

        function streamImpl = channelGetInputStream(chImpl)
            coder.cinclude('asynciocoder_api.hpp');
            streamImpl = matlabshared.asyncio.internal.coder.API.getNullInputStream();
            streamImpl = coder.ceval('coderChannelGetInputStream', chImpl);
            assert(streamImpl ~= matlabshared.asyncio.internal.coder.API.getNullInputStream());
        end

        function streamImpl = channelGetOutputStream(chImpl)
            coder.cinclude('asynciocoder_api.hpp');
            streamImpl = matlabshared.asyncio.internal.coder.API.getNullOutputStream();
            streamImpl = coder.ceval('coderChannelGetOutputStream', chImpl);
            assert(streamImpl ~= matlabshared.asyncio.internal.coder.API.getNullOutputStream());
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Error-related handling
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function result = channelHasAsyncError(chImpl)
            coder.cinclude('asynciocoder_api.hpp');
            result = false;
            success = int32(0);
            success = coder.ceval('coderChannelHasAsyncError', chImpl, ...
                                  coder.wref(result));
            matlabshared.asyncio.internal.coder.API.channelErrorIfFailed(chImpl, success);
        end

        function [errorID, errorText] = channelGetLastAsyncError(chImpl)
            coder.cinclude('asynciocoder_api.hpp');
            tempID = blanks(1024);
            errorText = blanks(1024);
            % assign the ceval output to a dummy variable type "int", to correctly
            % model the "int" output of the function (as in the header file)
            dummyOut = int32(0);
            dummyOut = coder.ceval('coderChannelGetLastAsyncError', chImpl,...
                                   coder.wref(tempID),...
                                   coder.wref(errorText)); %#ok<NASGU>
            errorID = matlabshared.asyncio.internal.coder.API.trimString(tempID);
        end

        function channelCheckForAsynchronousError(chImpl)
        % Check for an asynchronous error and display it.
            if matlabshared.asyncio.internal.coder.API.channelHasAsyncError(chImpl)
                [errorID, errorText] = matlabshared.asyncio.internal.coder.API.channelGetLastAsyncError(chImpl);
                % TODO Move to MessageHandler.
                matlabshared.asyncio.internal.coder.API.channelClose(chImpl);
                matlabshared.asyncio.internal.coder.API.dispatchAsynchronousError(errorID, errorText);
            end
        end

        function channelPause(chImpl, seconds)
        % PAUSE for the given number of seconds while also checking for
        % an asynchronous error. If an asynchronous error is found, close
        % the Channel and display the error.

        % We are pausing more than a small amount, loop and check
        % often for an error, otherwise pause and then check once.
            if seconds >= 0.01
                startTic = tic();
                while toc(startTic) < seconds
                    pause(0.005);
                    matlabshared.asyncio.internal.coder.API.channelCheckForAsynchronousError(chImpl);
                end
            else
                pause(seconds);
                matlabshared.asyncio.internal.coder.API.channelCheckForAsynchronousError(chImpl);
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Channel Operations
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function channelInit(chImpl, options)
        % Init the channel implementation
            [numArgs, args] = matlabshared.asyncio.internal.coder.API.optionsToArgs(options);
            success = int32(0);

            layout = matlabshared.asyncio.internal.coder.API.computeDataLayout();
            success = coder.ceval(layout, ...
                                  'coderChannelInit', chImpl, ...
                                  numArgs, args{:});
            matlabshared.asyncio.internal.coder.API.channelErrorIfFailed(chImpl, success);
        end

        function channelOpen(chImpl, options)
        % Open the channel implementation
            coder.cinclude('asynciocoder_api.hpp');
            [numArgs, args] = matlabshared.asyncio.internal.coder.API.optionsToArgs(options);
            success = int32(0);

            layout = matlabshared.asyncio.internal.coder.API.computeDataLayout();
            success = coder.ceval(layout, ...
                                  'coderChannelOpen', chImpl, ...
                                  numArgs, args{:});
            matlabshared.asyncio.internal.coder.API.channelErrorIfFailed(chImpl, success);
        end

        function channelClose(chImpl)
        % Open the channel implementation
            coder.cinclude('asynciocoder_api.hpp');
            success = int32(0);
            success = coder.ceval('coderChannelClose', chImpl);
            matlabshared.asyncio.internal.coder.API.channelErrorIfFailed(chImpl, success);
        end

        function channelExecute(chImpl, command, options)
        % Execute on the channel implementation
            coder.cinclude('asynciocoder_api.hpp');
            command = matlabshared.asyncio.internal.coder.API.terminateString(command);
            [numArgs, args] = matlabshared.asyncio.internal.coder.API.optionsToArgs(options);
            success = int32(0);

            layout = matlabshared.asyncio.internal.coder.API.computeDataLayout();
            success = coder.ceval(layout, ...
                                  'coderChannelExecute', chImpl, ...
                                  command, numArgs, args{:});
            matlabshared.asyncio.internal.coder.API.channelErrorIfFailed(chImpl, success);
        end

        function channelTerm(chImpl)
        % Terminate device plug-in.
            coder.cinclude('asynciocoder_api.hpp');
            success = int32(0);
            success = coder.ceval('coderChannelTerm', chImpl);
            matlabshared.asyncio.internal.coder.API.channelErrorIfFailed(chImpl, success);
        end

        function channelErrorIfFailed(chImpl, success)
        % Display the last error, if any.
            coder.cinclude('asynciocoder_api.hpp');
            if (success == 0)
                errorID = blanks(1024);
                errorText = blanks(1024);

                hasSyncError = false;
                % assign the ceval output to a dummy variable type "int", to correctly
                % model the "int" output of the function (as in the header file)
                dummyOut = int32(0);
                dummyOut = coder.ceval('coderChannelHasSyncError', chImpl, ...
                                       coder.wref(hasSyncError));

                % If failure was because of an internal error.
                if ~hasSyncError
                    % assign the ceval output to a dummy variable type "int", to correctly
                    % model the "int" output of the function (as in the header file)
                    dummyOut = coder.ceval('coderChannelGetLastError', chImpl, ...
                                           coder.wref(errorID), ...
                                           coder.wref(errorText)); %#ok<NASGU>
                    matlabshared.asyncio.internal.coder.API.dispatchInternalError(errorID, errorText);
                    % If failure was because of a plug-in synchronous error.
                else
                    % assign the ceval output to a dummy variable type "int", to correctly
                    % model the "int" output of the function (as in the header file)
                    dummyOut = coder.ceval('coderChannelGetLastSyncError', chImpl, ...
                                           coder.wref(errorID), ...
                                           coder.wref(errorText)); %#ok<UNRCH>
                    matlabshared.asyncio.internal.coder.API.dispatchSynchronousError(errorID, errorText);
                end
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Stream Lifetime
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Nothing to do. Streams are created/destroyed by the underlying
        % channel. See channelGetInputStream() and channelGetOutputStream()

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Stream Getters/Setters
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function result = streamIsSupported(streamImpl)
        % Test if stream is supported
            coder.cinclude('asynciocoder_api.hpp');
            result = false;
            success = int32(0);
            success = coder.ceval('coderStreamIsSupported', streamImpl, coder.wref(result));
            matlabshared.asyncio.internal.coder.API.streamErrorIfFailed(streamImpl, success);
        end

        function result = streamIsDone(streamImpl)
        % Test if stream is done
            coder.cinclude('asynciocoder_api.hpp');
            result = false;
            success = int32(0);
            success = coder.ceval('coderStreamIsDeviceDone', streamImpl, coder.wref(result));
            matlabshared.asyncio.internal.coder.API.streamErrorIfFailed(streamImpl, success);
        end

        function result = streamIsOpen(streamImpl)
        % Test if stream is done
            coder.cinclude('asynciocoder_api.hpp');
            result = false;
            success = int32(0);
            success = coder.ceval('coderStreamIsOpen', streamImpl, coder.wref(result));
            matlabshared.asyncio.internal.coder.API.streamErrorIfFailed(streamImpl, success);
        end

        function count = streamGetSpaceAvailable(streamImpl)
        % Get the space available in the stream
            coder.cinclude('asynciocoder_api.hpp');
            count = double(0);
            success = int32(0);
            success = coder.ceval('coderStreamGetSpaceAvailable', streamImpl, coder.wref(count));
            matlabshared.asyncio.internal.coder.API.streamErrorIfFailed(streamImpl, success);
        end

        function count = streamGetDataAvailable(streamImpl)
        % Get the data available in the stream
            coder.cinclude('asynciocoder_api.hpp');
            count = double(0);
            success = int32(0);
            success = coder.ceval('coderStreamGetDataAvailable', streamImpl, coder.wref(count));
            matlabshared.asyncio.internal.coder.API.streamErrorIfFailed(streamImpl, success);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Stream Operations
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function streamAddFilter(streamImpl, filterPluginPath, options)
        % Add a filter to the stream
            coder.cinclude('asynciocoder_api.hpp');
            [numArgs, args] = matlabshared.asyncio.internal.coder.API.optionsToArgs(options);
            success = int32(0);
            filterPluginPath = matlabshared.asyncio.internal.coder.API.terminateString(filterPluginPath);

            layout = matlabshared.asyncio.internal.coder.API.computeDataLayout();
            success = coder.ceval(layout, ...
                                  'coderStreamAddFilter', streamImpl, ...
                                  filterPluginPath,...
                                  numArgs, args{:});
            matlabshared.asyncio.internal.coder.API.streamErrorIfFailed(streamImpl, success);
        end

        function streamTuneFilters(streamImpl, options)
        % Tune all filters of the stream
            coder.cinclude('asynciocoder_api.hpp');
            [numArgs, args] = matlabshared.asyncio.internal.coder.API.optionsToArgs(options);
            success = int32(0);

            layout = matlabshared.asyncio.internal.coder.API.computeDataLayout();
            success = coder.ceval(layout, ...
                                  'coderStreamTuneFilters', streamImpl, ...
                                  numArgs, args{:});
            matlabshared.asyncio.internal.coder.API.streamErrorIfFailed(streamImpl, success);
        end

        function streamFlush(streamImpl)
        % Flush the stream's data
            coder.cinclude('asynciocoder_api.hpp');
            success = int32(0);
            success = coder.ceval('coderStreamFlush', streamImpl);
            matlabshared.asyncio.internal.coder.API.streamErrorIfFailed(streamImpl, success);
        end

        function streamErrorIfFailed(streamImpl, success)
            coder.cinclude('asynciocoder_api.hpp');
            if (success == 0)
                % If anything failed, delegate to Channel to process error.
                chImpl = matlabshared.asyncio.internal.coder.API.getNullChannel();
                chImpl = coder.ceval('coderStreamGetChannel', streamImpl);
                matlabshared.asyncio.internal.coder.API.channelErrorIfFailed(chImpl, success)
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % InputStream Operations
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function [countToRead, bufferCounts, numBuffers] = ...
                inputstreamPeek(streamImpl, countRequested)

            coder.cinclude('asynciocoder_api.hpp');
            % TODO: In order to not use maxPacketsPerRead, we'll have to first
            % peek on the input stream and ask for how many buffers we will
            % need to fulfill to countRequested and THEN ask what those
            % buffer counts need to be. Currently we will assume a max
            % number of buffers and ask for their counts here.
            maxPacketsPerRead = 80;
            countToRead = double(0);
            bufferCounts = zeros(1,maxPacketsPerRead, 'double');
            numBuffers = numel(bufferCounts);
            success = int32(0);
            success = coder.ceval('coderInputStreamPeek', ...
                                  streamImpl, ...
                                  countRequested, ...
                                  coder.ref(countToRead),...
                                  coder.ref(bufferCounts),...
                                  coder.ref(numBuffers));
            matlabshared.asyncio.internal.coder.API.streamErrorIfFailed(streamImpl, success);
        end

        function inputstreamReadBuffers(streamImpl, countToRead, numBuffers)
        % Read the buffers out of the queue.
            coder.cinclude('asynciocoder_api.hpp');
            success = int32(0);

            layout = matlabshared.asyncio.internal.coder.API.computeDataLayout();
            success = coder.ceval(layout, ...
                                  'coderInputStreamReadBuffers',...
                                  streamImpl,...
                                  countToRead,...
                                  numBuffers);
            matlabshared.asyncio.internal.coder.API.streamErrorIfFailed(streamImpl, success);
        end

        function value = inputstreamReadBufferData(streamImpl, bufferIndex, itemIndex, name, value)
        % Helper function to read a single field value of a structure from a buffer.
        % For typed data, itemIndex should be 1 and name should be empty

            success = int32(0);

            layout = matlabshared.asyncio.internal.coder.API.computeDataLayout();
            success = coder.ceval(layout, ...
                                  'coderInputStreamReadBufferData', ...
                                  streamImpl,...
                                  coder.internal.indexInt(bufferIndex),...
                                  coder.internal.indexInt(itemIndex),...
                                  coder.internal.stringConst(name),...
                                  coder.internal.stringConst(class(value)),...
                                  coder.internal.indexInt(numel(value)),...
                                  coder.wref(value));
            matlabshared.asyncio.internal.coder.API.streamErrorIfFailed(streamImpl, success);
        end

        function inputstreamFreeBuffer(streamImpl, bufferIndex)
        % Free the given buffer.
            coder.cinclude('asynciocoder_api.hpp');
            coder.ceval('coderInputStreamFreeBuffer', ...
                        streamImpl,...
                        coder.internal.indexInt(bufferIndex));
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % OutputStream Operations
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function countWrittenThisIteration = outputstreamWriteTypedData(streamImpl, packet)

            coder.cinclude('asynciocoder_api.hpp');
            countWrittenThisIteration = 0;
            success = int32(0);

            layout = matlabshared.asyncio.internal.coder.API.computeDataLayout();
            success = coder.ceval(layout, ...
                                  'coderOutputStreamWriteTypedDataOld', ...
                                  streamImpl, ...
                                  coder.wref(countWrittenThisIteration),...
                                  coder.internal.indexInt(1), ... % Number of packets.
                                  coder.internal.stringConst(class(packet)),...
                                  coder.internal.indexInt(numel(packet)),...
                                  coder.rref(packet));
            matlabshared.asyncio.internal.coder.API.streamErrorIfFailed(streamImpl, success);
        end
    end

    % Helper functions
    methods(Static)
        function absolutePath = computeAbsolutePath(inputFileName)
        % Computes the absolute path, given the relative path to an
        % input file. If the input file does not exist, it returns
        % empty.

        % Allocate the buffer into which the resolved path is going to
        % be copied into.
            localAbsPath = blanks(4096);

            coder.cinclude('asynciocoder_api.hpp');

            inputFileNullTerm = matlabshared.asyncio.internal.coder.API.terminateString(inputFileName);

            coder.ceval('coderComputeAbsolutePath', inputFileNullTerm, coder.wref(localAbsPath));

            absolutePath = matlabshared.asyncio.internal.coder.API.trimString(localAbsPath);
        end
    end

    methods(Static, Access='private')

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Helpers
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [numArgs, args] = optionsToArgs(options)
        % Helper function to convert a structure of options into a cell
        % array name, class, length, and value for each structure field.
            if isempty(options)
                numArgs = coder.internal.indexInt(0);
                args = {};
                return;
            end

            % Convert a struct to a cell array of argument name, type, size
            % and value.
            fields = fieldnames(options);
            numArgs = coder.internal.indexInt(numel(fields));
            args = cell(1,4*numArgs); % name, class, length, value
            argIdx = 1;
            coder.unroll();
            for ii = 1:4:numel(args)
                field = fields{argIdx};
                args{ii} = coder.internal.stringConst(field);
                args{ii+1} = coder.internal.stringConst(class(options.(field)));
                args{ii+2} = coder.internal.indexInt(numel(options.(field)));
                % This foolishness is to force the C call to always send a
                % pointer instead of a value when the option is a scalar.
                if isscalar(options.(field)) && ...
                        (isnumeric(options.(field)) || islogical(options.(field)) || ischar(options.(field)))
                    value = [options.(field) options.(field)];
                else
                    value = options.(field);
                end
                args{ii+3} = value;
                argIdx = argIdx+1;
            end
        end

        function out = terminateString(in)
            if coder.internal.isConst(in)
                out = coder.internal.stringConst(in);
            else
                out = [in, 0];
            end
        end

        function out = trimString(in)
            len = coder.internal.indexInt(0);
            for k = 1:numel(in)
                if in(k) == char(0)
                    break;
                end
                len = len+1;
            end
            out = in(1:len);
        end

        function dispatchInternalError(errorID, errorText)
            % Need to trim to the exact length so Coder doesn't optimize the switch away or end up in an exception
            errorID = matlabshared.asyncio.internal.coder.API.trimString(errorID);
            errorText = matlabshared.asyncio.internal.coder.API.trimString(errorText);
            switch errorID
              case 'asyncio:InputStream:notSupported'
                coder.internal.error('asyncio:InputStream:notSupported');
              case 'asyncio:OutputStream:notSupported'
                coder.internal.error('asyncio:OutputStream:notSupported');
              case 'asyncio:Channel:couldNotLoadDevice'
                coder.internal.error('asyncio:Channel:couldNotLoadDevice');
              case 'asyncio:Channel:couldNotLoadConverter'
                coder.internal.error('asyncio:Channel:couldNotLoadConverter');
              case 'asyncio:Stream:couldNotLoadFilter'
                coder.internal.error('asyncio:Stream:couldNotLoadFilter');
              case 'asyncio:Channel:couldNotCreateDevice'
                coder.internal.error('asyncio:Channel:couldNotCreateDevice');
              case 'asyncio:Channel:couldNotCreateConverter'
                coder.internal.error('asyncio:Channel:couldNotCreateConverter');
              case 'asyncio:Stream:couldNotCreateFilter'
                coder.internal.error('asyncio:Stream:couldNotCreateFilter');
              case 'asyncio:InputStream:synchronousInputNotPossible'
                coder.internal.error('asyncio:InputStream:synchronousInputNotPossible');
              case 'asyncio:OutputStream:synchronousOutputNotPossible'
                coder.internal.error('asyncio:OutputStream:synchronousOutputNotPossible');
              case 'asyncio:InputStream:couldNotConvertInputData'
                coder.internal.error('asyncio:InputStream:couldNotConvertInputData');
              case 'asyncio:OutputStream:couldNotConvertOutputData'
                coder.internal.error('asyncio:OutputStream:couldNotConvertOutputData');
              case 'asyncio:Stream:cannotAddFilterWhileOpen'
                coder.internal.error('asyncio:Stream:cannotAddFilterWhileOpen');
              case 'asyncio:Channel:unexpectedException'
                coder.internal.error('asyncio:Channel:unexpectedException', errorText);
              otherwise
                coder.internal.error('asyncio:Channel:unexpectedException', ...
                                     ['ErrID: ' errorID ', Msg: ', errorText]);
            end
        end

        function dispatchSynchronousError(errorID, errorText)
            % TODO Call Message Handler (we'll need to pass MessageHandler to all API calls).
            % Need to trim to the exact length so Coder doesn't optimize the switch away or end up in an exception
            errorID = matlabshared.asyncio.internal.coder.API.trimString(errorID);
            errorText = matlabshared.asyncio.internal.coder.API.trimString(errorText);
            coder.internal.error('asyncio:Channel:coderSynchronousError', errorID, errorText);
        end

        function dispatchAsynchronousError(errorID, errorText)
            % TODO Call Message Handler.
            % Need to trim to the exact length so Coder doesn't optimize the switch away or end up in an exception
            errorID = matlabshared.asyncio.internal.coder.API.trimString(errorID);
            errorText = matlabshared.asyncio.internal.coder.API.trimString(errorText);
            coder.internal.error('asyncio:Channel:coderAsynchronousError', errorID, errorText);
        end

        function layout = computeDataLayout()
            if coder.isColumnMajor
                layout = '-layout:columnMajor';
            else
                layout = '-layout:rowMajor';
            end
        end
    end
end

% LocalWords:  IOAPI asynciocoder os libstdc linux softlink NGo asynciocore libmwfoundation
% LocalWords:  matlabdata tamutil chrono imaq imaqblks sfcnrules libmwi libmwlocale libmwresource
% LocalWords:  libmwcpp compat uc icudtl dat SONAME makerules boostrules mwboost libmwboost dylib
% LocalWords:  glnx islinux icurules autogenerate icu majorver libicu libssl mw libcrypto maca maci
% LocalWords:  Codesignature libexpat
