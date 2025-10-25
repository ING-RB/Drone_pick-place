classdef (Hidden) Channel < handle
% A communications channel to any device that is a data source or sink.
%
%   The device may be a piece of hardware, a file, socket, network, etc.
%   The device may be bidirectional, input-only, or output-only. If the device
%   is a source of incoming data, then the channel will contain a valid
%   InputStream property. If the device is a sink for outgoing data, then the
%   channel will contain a valid OutputStream property.
%
%   The channel works in conjunction with a two C++ plug-ins. The device
%   plug-in wraps the device-specific software API. The converter plug-in
%   converts data in MATLAB format to a format expected by the device
%   plug-in (and vice-versa).
%
%   See also matlabshared.asyncio.internal.coder.Channel, matlabshared.asyncio.internal.coder.InputStream,
%   matlabshared.asyncio.internal.coder.OutputStream.

% Copyright 2018-2024 The MathWorks, Inc.

%#codegen

    properties(GetAccess='public',SetAccess='private')
        % A matlabshared.asyncio.internal.InputStream used for reading.
        InputStream;

        % A matlabshared.asyncio.internal.OutputStream used for writing.
        OutputStream;
    end

    properties (Constant, Access = 'private')
        % Default to scalar
        DefaultCountDimensions      = [1 1];
        % Default for options is empty struct
        DefaultOptions              = [];%struct();
                                         % Write and read data continuously until system memory is reached
        DefaultStreamLimits         = [Inf Inf];
        % Default for CustomPropsExpected is empty struct
        DefaultCustomPropsExpected  = struct();
        % Coder infra is looking for a default value for parsing. Hence
        % providing a default of empty double for coder example data even
        % though it is a mandatory argument
        DefaultCoderExampleData     = [];
        % NV Pair Names allowed as input to Channel constructor for codegen
        AllowedInputArguments = {'CountDimensions', 'Options', ...
                                 'StreamLimits', 'CustomPropsExpected', ...
                                 'CoderExampleData'};
    end

    methods(Access='public')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Lifetime
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = Channel(devicePluginPath, converterPluginPath, varargin)
        % CHANNEL Create an asynchronous communication channel to a device.
        %
        % OBJ = CHANNEL(DEVICEPLUGINPATH, CONVERTERPLUGINPATH, ...
        %               CountDimension = COUNTDIMENSIONS, ...
        %               Options = OPTIONS, ...
        %               StreamLimits = STREAMLIMITS, ...
        %               CustomPropsExpected = CUSTOMPROPSEXPECTED, ...
        %               CoderExampleData = CODEREXAMPLEDATA)
        % creates a communication channel to the given device and sets up
        % the appropriate input and output streams.
        %
        % Inputs:
        % DEVICEPLUGINPATH - The full path and name of the device plug-in.
        % The file extension of the plug-in should be omitted.
        %
        % CONVERTERPLUGINPATH - The full path and name of the converter
        % plug-in. The file extension of the plug-in should be omitted.
        %
        % COUNTDIMENSIONS - An array of two doubles that indicate the
        % dimension of the incoming and outgoing data that should be used
        % to determine the count of items. Each count dimension must be a
        % value that is greater than zero. This value is required if the
        % Channel will have either a supported input or output stream.
        % Normally this information is specified at run-time by the
        % converter plug-in, but MATLAB Coder requires this information
        % at compile time.
        %
        % OPTIONS - A structure containing information that needs to be
        % passed to the device plug-in during initialization. This parameter
        % is optional.
        %
        % STREAMLIMITS - An array of two doubles that indicate the maximum
        % number of items to buffer in the input and output streams. Valid
        % values for each limit are between 0 and Inf, inclusive. If Inf is
        % used, buffering will be limited only by the amount of memory available
        % to the application. If zero is used, the stream is unbuffered and all
        % reads or writes are synchronous (i.e. go directly to the device).
        % This parameter is optional and defaults to [Inf, Inf] if not
        % specified.
        %
        % CUSTOMPROPSEXPECTED - A structure that contains sample data for
        % all the custom properties that the device plug-in can create.
        % For example:
        %     customPropsExpected.Resolution = blanks(80);
        %     customPropsExpected.Timestamp = 0;
        %     customPropsExpected.FrameRate = 0;
        % This parameter is optional and only needs to be specified
        % if the device plugin creates custom properties.
        %
        % CODEREXAMPLEDATA - Example data for a single item along the Count
        % Dimension. Must be numeric, logical, char, or struct. This
        % argument is mandatory in codegen workflow
        % For example:
        %    exampleData = zeros(1, numAudioChannels);
        % OR
        %    exampleData.Frame = zeros(height, width, numBands, 'uint8');
        %    exampleData.Timestamp = 0;
        %
        % Notes:
        % During initialization, the device plug-in can specify custom
        % properties and their initial values.

            coder.extrinsic('computer');
            coder.extrinsic('fullfile');
            coder.extrinsic('fileparts');

            % Must initialize to null before calling anything that can error.
            coder.internal.assert(coder.internal.isTargetMATLABHost() || coder.target('rtwForRapid'),'asyncio:Channel:coderInvalidTarget');
            narginchk(2, 12);
            coder.internal.errorIf((mod(nargin,2) ~= 0), 'asyncio:Channel:coderExpectedNVPair');%Arguments after converterPluginPath are expected to be Name Value pairs');

            popt = struct( ...
                'PartialMatching', 'unique', ...
                'SupportOverrides', false);

            result = coder.internal.parseParameterInputs(obj.AllowedInputArguments, popt, varargin{:});
            countDimensions = coder.internal.getParameterValue(result.CountDimensions, obj.DefaultCountDimensions, varargin{:});
            options         = coder.internal.getParameterValue(result.Options, obj.DefaultOptions, varargin{:});
            streamLimits    = coder.internal.getParameterValue(result.StreamLimits, obj.DefaultStreamLimits, varargin{:});
            obj.CustomProps = coder.internal.getParameterValue(result.CustomPropsExpected, obj.DefaultCustomPropsExpected, varargin{:});

            % If CoderExampleData is not used, throw.
            % parseParameterInputs returns uint32(0) if NV Pair is not used
            coder.internal.errorIf((result.CoderExampleData == zeros('uint32')), 'asyncio:Channel:CoderExampleDataMandatory');
            exampleData     = coder.internal.getParameterValue(result.CoderExampleData, obj.DefaultCoderExampleData, varargin{:});

            % Validating Count Dimensions this way in order to catch it at
            % build time
            invalidCountDimensions = ~isfloat(countDimensions) || ...
                length(countDimensions) ~= 2 || ...
                any(isnan(countDimensions)) ||...
                any(countDimensions <= 0);
            coder.internal.errorIf(invalidCountDimensions, 'asyncio:Channel:invalidCountDimensions');

            % Validating Options
            invalidOptions = ~(isstruct(options) || (isempty(options) && isnumeric(options)));
            coder.internal.errorIf(invalidOptions, 'asyncio:Channel:invalidOptions');

            % Validating StreamLimits
            invalidStreamLimits = ~isfloat(streamLimits) || ...
                length(streamLimits) ~= 2 || ...
                any(isnan(streamLimits)) || ...
                any(streamLimits < 0);
            coder.internal.errorIf(invalidStreamLimits, 'asyncio:Channel:invalidStreamLimits');

            % Validating Custom Properties
            invalidCustomProps = ~isstruct(obj.CustomProps);
            coder.internal.errorIf(invalidCustomProps, 'asyncio:Channel:invalidCustomProps');

            obj.ChannelImpl = matlabshared.asyncio.internal.coder.API.getNullChannel();
            if isempty(converterPluginPath)
                % Prepare Array coder converter
                pathPart = fileparts(mfilename('fullpath'));
                plugindir = fullfile(pathPart,'..','..','..','..');
                pluginRoot = coder.const(fullfile(plugindir,'bin',computer('arch')));
                converterPlugin = coder.const(fullfile(pluginRoot, 'testcoderconverterarrays'));
            else
                converterPlugin = converterPluginPath;
            end
            % Create underlying C++ channel implementation.
            obj.ChannelImpl = matlabshared.asyncio.internal.coder.API.channelCreate(devicePluginPath, converterPlugin, streamLimits);

            % Initialize C++ channel.
            matlabshared.asyncio.internal.coder.API.channelInit(obj.ChannelImpl, options);

            % Create the input/output streams.
            obj.InputStream = matlabshared.asyncio.internal.InputStream(obj.ChannelImpl, countDimensions(1), exampleData);
            obj.OutputStream = matlabshared.asyncio.internal.OutputStream(obj.ChannelImpl, countDimensions(2));

            % Do post init functionality.
            obj.postInit();
        end

        function delete(obj)
        % DELETE Destroy the communications channel.
        %

        % Call destroy. Destroy exists so clients can explicitly
        % destroy the Channel. This is a work-around for the lack of
        % support for explicit delete() in MATLAB Coder. See g1756065
            destroy(obj);
        end

        function destroy(obj)
        % DESTROY Destroy the communications channel.
        %
        % If the communication channel is still open, it will be closed
        % and all data in the input and output streams will be lost.

        % If the underlying channel implementation never completed,
        % bail out to avoid any errors here.
            if obj.ChannelImpl == matlabshared.asyncio.internal.coder.API.getNullChannel()
                return;
            end

            % Make sure we are closed.
            if isOpen(obj)
                coder.internal.warning('asyncio:Channel:stillOpenDuringDelete');
                obj.close();
            end

            % Do pre-term functionality (can be overridden by a subclass).
            obj.preTerm();

            % Terminate device plug-in.
            matlabshared.asyncio.internal.coder.API.channelTerm(obj.ChannelImpl);

            % Delete streams. NOTE: Call destroy since delete can't be
            % called explicitly.
            destroy(obj.InputStream);
            destroy(obj.OutputStream);

            % Delete underlying channel implementation.
            matlabshared.asyncio.internal.coder.API.channelDestroy(obj.ChannelImpl);

            % Set this to null, so destroy can be called again without
            % crashing.
            obj.ChannelImpl = matlabshared.asyncio.internal.coder.API.getNullChannel();
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Getters/Setters
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function result = isOpen(obj)
        % ISOPEN Return true is the channel is open, false otherwise.

            result = matlabshared.asyncio.internal.coder.API.channelIsOpen(obj.ChannelImpl);
        end

        function tf = hasCustomProp(obj, propName)
        % HASCUSTOMPROP Returns TRUE if the custom property exists and
        % FALSE if it does not
            if ~isfield(obj.CustomProps, propName)
                tf = false;
                return;
            end
            exampleValue = obj.CustomProps.(propName);
            tf = matlabshared.asyncio.internal.coder.API.channelHasPropertyValue(obj.ChannelImpl, propName, exampleValue);
        end

        function value = getCustomProp(obj, propName)
        % GETCUSTOMPROP Returns the current value of the custom property.
        % Errors at compile time if PROPNAME does not exist.
            exampleValue = obj.CustomProps.(propName);
            value = matlabshared.asyncio.internal.coder.API.channelGetPropertyValue(obj.ChannelImpl, propName, exampleValue);
            %obj.CustomProps.(propName) = value; % Technically not needed.
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Commands
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function open(obj, options)
        % OPEN Connect to the device and begin the streaming of data.
        %
        % OPEN(OBJ,OPTIONS) opens the communication channel, gains
        % exclusive access to any resources, and allows the device
        % to begin sending and receiving data. If the streams have any
        % filters, they will also be opened.
        %
        % Inputs:
        % OPTIONS - A structure containing information that needs to be passed
        % to the device plug-in and filter plug-in(s) prior to opening. This
        % parameter is optional and defaults to an empty structure.
        %
        % Notes:
        % - Open does not flush either the input stream or the output
        %   stream. To alter this behavior, override the preOpen method.
        % - Resources will be opened in the following order:
        %      1) Filter plug-in(s) of the input stream, if any, in the
        %         order in which they were added to the input stream.
        %      2) Filter plug-in(s) of the output stream, if any, in the
        %         order in which they were added to the output stream.
        %      3) Device plug-in.
        % - If open fails, the Channel remain closed.
        %
        % See also matlabshared.asyncio.internal.Stream.addFilter
        %
        % If no options specified...
            if nargin < 2
                options = [];
            end

            if isOpen(obj)
                return;
            end

            % Do pre-open functionality (can be overridden by a subclass).
            obj.preOpen();

            % Gain exclusive access of the device.
            matlabshared.asyncio.internal.coder.API.channelOpen(obj.ChannelImpl, options);
        end

        function close(obj)
        % CLOSE Disconnect from the device and stop the streaming of data.
        %
        % CLOSE(OBJ) stops the streaming of data, releases exclusive access
        % to any resources, and closes the communication channel. If the
        % streams have any filters, they will also be closed.
        %
        % Notes:
        % - Close does not flush either the input stream or the output
        %   stream. To alter this behavior, override the postClose method.
        % - Resources will be closed in the following order:
        %      1) Device plug-in.
        %      2) Filter plug-in(s) of the output stream, if any, in the
        %         order in which they were added to the output stream.
        %      3) Filter plug-in(s) of the input stream, if any, in the
        %         order in which they were added to the input stream.
        %
        % See also matlabshared.asyncio.internal.Stream.addFilter
        %
            if ~isOpen(obj)
                return;
            end

            % Release exclusive access to the device.
            matlabshared.asyncio.internal.coder.API.channelClose(obj.ChannelImpl);

            % Do post-close functionality (can be overridden by a subclass).
            obj.postClose();
        end

        function execute(obj, command, options)
        % EXECUTE Execute an arbitrary device-specific command.
        %
        % EXECUTE(OBJ,COMMAND,OPTIONS) will pass the given command and
        % options to the device plug-in.
        %
        % Inputs:
        % COMMAND - A string that represents the command to execute.
        % OPTIONS - A structure containing information that needs to be passed
        % to the device plug-in in order to execute the command. This
        % parameter is optional and defaults to an empty structure.
        %
        % Notes:
        % Execute can be called at any time, not just when the channel is open.
        % Errors, warnings, custom events, and custom property updates are
        % propagated as usual during execute.

        % If no options specified...
            if nargin < 3
                options = struct();
            end

            if isstring(command)
                matlabshared.asyncio.internal.coder.API.channelExecute(obj.ChannelImpl, char(command), options);
            else
                matlabshared.asyncio.internal.coder.API.channelExecute(obj.ChannelImpl, command, options);
            end
        end

        function yield(~, useNamedQueues)
        % YIELD Dequeue and run events from the MATLAB instruction queue.
        %
        % YIELD(OBJ,useNamedQueues)
        %
        % Inputs: useNamedQueues - Optional (default = false).
        %
        % If useNamedQueues == true, yield will dequeue AsyncIO events
        % from the instruction queue - ahead of other non-AsyncIO events.
        % All AsyncIO events will remain ordered with respect to each other
        % and will run in the same order in which they entered the queue.
        %

            if nargin < 2
                useNamedQueues = false;
            end

            if useNamedQueues
                matlab.internal.yield("matlabshared.asyncio");
            else
                drawnow();
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Error-related handling
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function result = hasAsyncError(obj)
        % HASASYNCERROR Returns true if an asynchronous error has occurred.
        % If true, use getLastAsyncError() to retrieve the error
        % information.
            result = matlabshared.asyncio.internal.coder.API.channelHasAsyncError(obj.ChannelImpl);
        end

        function [errorID, errorText] = getLastAsyncError(obj)
        % GETLASTASYNCERROR returns the error information for the most
        % recent asynchronous error. Also resets the state of returned by
        % hasAsyncError() to false until the next asynchronous error
        % occurs.
            [errorID, errorText] = matlabshared.asyncio.internal.coder.API.channelGetLastAsyncError(obj.ChannelImpl);
        end

        function pause(obj, seconds)
        % PAUSE for the given number of seconds while also checking for
        % an asynchronous error and other "background" stuff.
        % If an asynchronous error is found, close the Channel and display
        % the error.
            matlabshared.asyncio.internal.coder.API.channelPause(obj.ChannelImpl, seconds);
        end
    end

    methods(Access='protected')

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Helpers
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function postInit(~)
        % Functionality done just after channel is initialized.
        end

        function preOpen(~)
        % Functionality done just prior to device being opened.
        end

        function postClose(~)
        % Functionality done just after device is closed.
        end

        function preTerm(~)
        % Functionality done just before channel is destroyed.
        end
    end

    properties(Hidden=true)
        % Enables/disables trace statements from plug-ins.
        TraceEnabled = false;

        % Enables/disables the data flow events from the underlying
        % C++ channel. This is a performance optimization for clients
        % that don't need to use the DataRead and DataWritten events.
        % NOTE: Must be set before the channel is opened.
        DataEventsDisabled = true;
    end

    properties(GetAccess='private',SetAccess='private')
        % Underlying C++ implementation of channel.
        ChannelImpl;

        % Storage of custom property example data.
        CustomProps;
    end
end

% LocalWords:  DEVICEPLUGINPATH CONVERTERPLUGINPATH COUNTDIMENSIONS STREAMLIMITS CUSTOMPROPSEXPECTED
% LocalWords:  CODEREXAMPLEDATA HASCUSTOMPROP GETCUSTOMPROP Dequeue dequeue Async HASASYNCERROR
% LocalWords:  GETLASTASYNCERROR testcoderconverterarrays
