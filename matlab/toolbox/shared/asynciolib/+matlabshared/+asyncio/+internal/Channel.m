classdef Channel < dynamicprops
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
%   See also matlabshared.asyncio.internal.Channel.Channel, matlabshared.asyncio.internal.InputStream, matlabshared.asyncio.internal.OutputStream.

% Copyright 2007-2024 The MathWorks, Inc.

%#codegen

    properties(GetAccess='public',SetAccess='private')
        % A matlabshared.asyncio.internal.InputStream used for reading.
        InputStream;

        % A matlabshared.asyncio.internal.OutputStream used for writing.
        OutputStream;
    end

    properties(Hidden,GetAccess='public',SetAccess='private')
        % If set to true, the polling sleep in the data pump may be replaced by
        % a sleep(0) or yield. Low latency applications can set this to
        % true but will may incur higher CPU usage.
        %
        OptimizedSleep = false;
    end

    properties (Hidden)
        % Methods that implement reentrancy protection directly, must
        % disable this with default construction. Methods that want
        % protection must construct this with string array of methods. See
        % help of ReentryProtectionFSM for more details.
        % Default constructed to disable protection by default.
        ReentryProtector matlabshared.testmeas.ReentryProtectionFSM = matlabshared.testmeas.ReentryProtectionFSM();
    end

    events(NotifyAccess='private')
        % The channel has been closed.
        Closed

        % The channel has been opened.
        Opened

        % A device-specific custom event has occurred.
        Custom
    end

    methods(Access='public')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Lifetime
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function obj = Channel(devicePluginPath, converterPluginPath, varargin)
        % CHANNEL Create an asynchronous communication channel to a device.
        %
        % OBJ = CHANNEL(DEVICEPLUGINPATH, CONVERTERPLUGINPATH, ...
        %               'Options', OPTIONS, ...
        %               'StreamLimits', STREAMLIMITS, ...
        %               'MessageHandler', MESSAGEHANDLER, ...
        %               'OptimizedSleep', false)
        %               'LibraryLoadSearchPath', LIBRARYLOADSEARCHPATH)
        % creates a communication channel to the given device and sets up
        % the appropriate input and output streams.
        %
        % Inputs:
        % DEVICEPLUGINPATH - The full path and name of the device plug-in.
        % The file extension of the plug-in should be omitted.
        %
        % CONVERTERPLUGINPATH - The full path and name of the converter
        % plug-in. The file extension of the plug-in should be omitted. If empty,
        % a default 2x2 MDA converter will be used.
        %
        % OPTIONS - A structure containing information that needs to be
        % passed to the device plug-in during initialization. This parameter
        % is optional unless STREAMLIMITS also needs to be specified.
        % The default value for this parameter is an empty structure.
        %
        % STREAMLIMITS - An array of two doubles that indicate the maximum
        % number of items to buffer in the input and output streams. Valid
        % values for each limit are between 0 and Inf, inclusive. If Inf is
        % used, buffering will be limited only by the amount of memory available
        % to the application. If zero is used, the stream is unbuffered and all
        % reads or writes are synchronous (i.e go directly to the device).
        % This parameter is optional. The default value for this parameter
        % is [Inf Inf].
        %
        % MESSAGEHANDLER - A subclass of matlabshared.asyncio.internal.MessageHandler used to
        % override the default message handling behavior. This parameter
        % is optional. The default value for this parameter is an instance
        % of matlabshared.asyncio.internal.MessageHandler.
        %
        % LIBRARYLOADSEARCHPATH - Additional search path to look for upstream DLL dependencies for
        % device plug-in.
        %
        % OPTIMIZEDSLEEP - Boolean; If true, polled streaming sleeps of duration less than that of
        % a sleep(0) shall be replaced with yields.
        %
        % Notes:
        % During initialization, the device plug-in can specify custom
        % properties and their initial values. These properties will be
        % created as dynamic properties on the channel object and can be
        % updated at any time by the device plug-in.

        % Device plugin path and converter plugin path are mandatory positional
        % arguments
            narginchk(2, 12);
            try
                p = inputParser;
                p.PartialMatching = true;
                % empty struct default for options
                addParameter(p, 'Options', struct([]), @(o) validateOptions(obj, o));
                % buffer data in both directions [inf, inf] until machine memory is available by default
                addParameter(p, 'StreamLimits', [inf, inf], @(s) validateStreamLimits(obj, s));
                % AsyncIO's MessageHandler is the default
                addParameter(p, 'MessageHandler', matlabshared.asyncio.internal.MessageHandler, @(m) validateMessageHandler(obj, m));
                % User Search Directory to search out of process directories to
                % load device / converter plugin dependencies
                addParameter(p, 'LibraryLoadSearchPath', '', @(l) validateLibraryLoadSearchPath(obj, l)); % @(x) isstring(x))
                                                                                                          % Optimized sleep
                addParameter(p, 'OptimizedSleep', false, @(x) validateOptimizedSleep(obj, x));

                parse(p, varargin{:});
            catch e
                throwAsCaller(e);
            end

            options = p.Results.Options;
            streamLimits = p.Results.StreamLimits;
            messageHandler = p.Results.MessageHandler;
            optimizedSleep = p.Results.OptimizedSleep;
            libraryLoadSearchPath = p.Results.LibraryLoadSearchPath;

            if isempty(options)
                options = struct([]);
            end

            % Let message handler know about this Channel.
            messageHandler.Channel = obj;

            % NOTE: The destructor will always be called if there is any
            % failure from this point forward. MATLAB object system rules
            % dictate that once we access any object property in the
            % constructor, then the destructor must be called.
            % Use default converter if empty
            if isempty(converterPluginPath) || (isstring(converterPluginPath) && isequal(converterPluginPath, ""))
                converterPluginPath = fullfile(toolboxdir('shared'), 'asynciolib', 'bin', computer('arch'), 'testmlconverterarrays');
            end
            % Create underlying C++ channel implementation.
            obj.ChannelImpl = asyncioimpl.Channel(devicePluginPath,...
                                                  converterPluginPath,...
                                                  streamLimits(1),...
                                                  streamLimits(2),...
                                                  messageHandler, ...
                                                  libraryLoadSearchPath, ...
                                                  optimizedSleep);

            % Lock asyncio class definitions when there are any instances
            % of a Channel. See g1306865, g1314266, and g1355310 for info.
            matlabshared.asyncio.internal.Channel.lock();

            % Store the message handler.
            obj.MessageHandler = messageHandler;

            % Initialize device plug-in and get custom property/value pairs.
            customProps = obj.ChannelImpl.init(options);

            % Add and initialize dynamic properties.
            fields = fieldnames(customProps);
            for i = 1:length(fields)
                prop = addprop(obj, fields{i});
                obj.(fields{i}) = customProps.(fields{i});
                prop.SetObservable = true;
            end

            % Create the input/output streams.
            channelImplWeakRef = matlab.lang.WeakReference(obj.ChannelImpl);
            obj.InputStream = matlabshared.asyncio.internal.InputStream(channelImplWeakRef.Handle);
            obj.OutputStream = matlabshared.asyncio.internal.OutputStream(channelImplWeakRef.Handle);
            obj.OptimizedSleep = optimizedSleep;

            % Do post init functionality (can be overridden by a subclass).
            obj.postInit();
        end

        function delete(obj)
        % DELETE Destroy the communications channel.
        %
        % If the communication channel is still open, it will be closed
        % and all data in the input and output streams will be lost.

        % If the underlying channel implementation never completed,
        % bail out to avoid any errors here.
            if ~isConstructionComplete(obj)
                return;
            end

            % Make sure we are closed.
            if isOpen(obj)
                warning(message('asyncio:Channel:stillOpenDuringDelete'));
                obj.close();
            end

            % Do pre-term functionality (can be overridden by a subclass).
            obj.preTerm();

            % Terminate device plug-in.
            % NOTE: term is called even if init() fails.
            obj.ChannelImpl.term();

            % Delete streams.
            delete(obj.InputStream);
            delete(obj.OutputStream);

            % Clear message handler. NOTE: We do not delete it because if
            % the client provided the handler, it could still be in use.
            obj.MessageHandler = [];

            % Delete underlying channel implementation.
            delete(obj.ChannelImpl);

            % Unlock asyncio class definitions when there are no more instances
            % of a Channel.
            matlabshared.asyncio.internal.Channel.unlock();
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Getters/Setters
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function result = isOpen(obj)
        % ISOPEN Return true is the channel is open, false otherwise.

            assert( isscalar(obj), 'Channel:isOpen:notScalar',...
                    'OBJ must be scalar.');
            if ~isConstructionComplete(obj)
                return;
            end
            result = obj.ChannelImpl.isOpen();
        end

        function tf = hasCustomProp(obj, propName)
        % HASCUSTOMPROP Returns TRUE if the property is present on the channel.

            assert( isscalar(obj), 'Channel:getCustomProp:notScalar',...
                    'OBJ must be scalar.');

            tf = isprop(obj, propName);
        end

        function value = getCustomProp(obj, propName)
        % GETCUSTOMPROP Returns the current value of the custom property.
        % Throws 'MATLAB:noSuchMethodOrField' if PROPNAME does not exist.

            assert( isscalar(obj), 'Channel:getCustomProp:notScalar',...
                    'OBJ must be scalar.');
            value = obj.(propName);
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
        % See also asyncio.Stream.addFilter
        %
            assert( isscalar(obj), 'Channel:open:notScalar',...
                    'OBJ must be scalar.');

            if ~isConstructionComplete(obj)
                return;
            end

            % If no options specified...
            if nargin < 2 || isempty(options)
                options = struct([]);
            end

            if isOpen(obj)
                return;
            end

            % Do pre-open functionality (can be overridden by a subclass).
            obj.preOpen();

            % Gain exclusive access of the device.
            obj.ChannelImpl.open(options);

            % Notify any listeners that we have opened.
            notify(obj, 'Opened');
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
        % See also asyncio.Stream.addFilter
        %
            assert( isscalar(obj), 'Channel:close:notScalar',...
                    'OBJ must be scalar.');
            if ~isConstructionComplete(obj)
                return;
            end

            if ~isOpen(obj)
                return;
            end

            % Release exclusive access to the device.
            obj.ChannelImpl.close();

            % Do post-close functionality (can be overridden by a subclass).
            obj.postClose();

            % Notify any listeners that we have closed.
            notify(obj, 'Closed');
        end

        function err = execute(obj, command, options)
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

        % stateCleanup and err will be empty and no protection is provided if
        % 1. obj.ReentryProtector is default constructed (OR)
        % 2. obj.ReentryProtector is constructed without "execute" as input
        %
        % If obj.ReentryProtector is constructed with "execute" as input
        % AND
        % If execute is not already running
        % stateCleanup will have an onCleanup function handle and err will 
        % be empty.
        % If execute is already running
        % stateCleanup will be empty and err will be "Reentrancy Prohibited"
        % This err will be returned as part of execute method's output.
            [stateCleanup, err] = setupReentryProtection(obj.ReentryProtector, "execute"); %#ok<ASGLU> onCleanup carrier.

            if ~isempty(err)
                return;
            end

            assert( isscalar(obj), 'Channel:execute:notScalar',...
                    'OBJ must be scalar.');

            if ~isConstructionComplete(obj)
                return;
            end

            % If no options specified...
            if nargin < 3 || isempty(options)
                options = struct([]);
            end

            if isstring(command)
                command = char(command);
            end

            obj.ChannelImpl.execute(command, options);
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
    end

    methods(Static)
        function name = matlabCodegenRedirect(~)
            name = 'matlabshared.asyncio.internal.coder.Channel';
        end
    end

    methods(Static, Access='private')
        function lock()
        % Lock this class definition and the class definitions of the
        % children on the first lock.
            if matlabshared.asyncio.internal.Channel.updateAndFetchLockCount(1) > 0
                if ~mislocked % just in case
                    mlock;
                    matlabshared.asyncio.internal.MessageHandler.lock();
                    matlabshared.asyncio.internal.InputStream.lock();
                    matlabshared.asyncio.internal.OutputStream.lock();
                end
            end
        end

        function unlock()
        % Unlock this class definition and the class definitions of the
        % children on the last unlock.
            if matlabshared.asyncio.internal.Channel.updateAndFetchLockCount(-1) < 1
                if mislocked % just in case
                    munlock;
                    munlock('matlabshared.asyncio.internal.MessageHandler');
                    munlock('matlabshared.asyncio.internal.InputStream');
                    munlock('matlabshared.asyncio.internal.OutputStream');
                end
            end
        end

        function count = updateAndFetchLockCount(increment)
            persistent lockCount;
            if isempty(lockCount)
                lockCount = 0;
            end
            lockCount = lockCount + increment;
            count = lockCount;
        end
    end

    methods(Access='protected')

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Helpers
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function postInit(obj)
        % Functionality done just after channel is initialized.

            objWeakRef = matlab.lang.WeakReference(obj);
            % Connect property, message, and custom events to our methods.
            obj.PropertyChangedListener = event.listener(obj.ChannelImpl,...
                                                         'PropertyChanged',...
                                                         @(source, data) objWeakRef.Handle.onPropertyChanged(data.Name, data.Value));
            % Allow property events to recurse since a client's listener
            % may do something that causes another property event to fire
            % synchronously.
            obj.PropertyChangedListener.Recursive = true;

            obj.CustomListener = event.listener(obj.ChannelImpl,...
                                                'Custom',...
                                                @(source, data) objWeakRef.Handle.onCustomEvent(data.Type, data.Data));
            % Allow custom events to recurse since a client's listener
            % may do something that causes another custom event to fire
            % synchronously.
            obj.CustomListener.Recursive = true;
        end

        function preOpen(obj)
        % Functionality done just prior to device being opened.

            objWeakRef = matlab.lang.WeakReference(obj);
            % If data flow events are enabled...
            if ~obj.DataEventsDisabled

                % Connect data flow callbacks to our methods.
                obj.DataReceivedListener = event.listener(obj.ChannelImpl,...
                                                          'DataReceived',...
                                                          @(source, data) objWeakRef.Handle.onDataReceived());

                obj.DataSentListener = event.listener(obj.ChannelImpl,...
                                                      'DataSent',...
                                                      @(source, data) objWeakRef.Handle.onDataSent());
            else
                obj.DataReceivedListener = [];
                obj.DataSentListener = [];
            end
        end

        function postClose(obj)
        % Functionality done just after device is closed.

        % Disconnect data flow events.
        % This has the effect of stopping the transfer of events
        % that may have been queued by the data source or sink but
        % have not yet been processed by MATLAB.
            if ~isempty(obj.DataSentListener)
                delete(obj.DataSentListener);
            end
            if ~isempty(obj.DataReceivedListener)
                delete(obj.DataReceivedListener);
            end
        end

        function preTerm(obj)
        % Functionality done just before channel is destroyed.

        % Disconnect property, message, and custom events.
        % This has the effect of stopping the transfer of events
        % that may have been queued by the device but have not yet
        % processed by MATLAB.
            delete(obj.CustomListener);
            delete(obj.PropertyChangedListener);
        end

        function validateLibraryLoadSearchPath(~, path)
            if ~isfolder(path)
                error(message('asyncio:Channel:invalidLibraryLoadSearchPath'));
            end
        end
    end

    methods(Access='private')

        function validateMessageHandler(~, messageHandler)
            if ~isa(messageHandler, 'matlabshared.asyncio.internal.MessageHandler')
                error(message('asyncio:Channel:invalidMessageHandler'));
            end
        end

        function validateStreamLimits(~, streamLimits)
            if ~isfloat(streamLimits) || ...
                    length(streamLimits) ~= 2 || ...
                    any(isnan(streamLimits)) || ...
                    streamLimits(1) < 0 || streamLimits(2) < 0

                error(message('asyncio:Channel:invalidStreamLimits'));
            end
        end

        function validateOptions(~, options)
            if ~(isstruct(options) || isempty(options))
                error(message('asyncio:Channel:invalidOptions'));
            end
        end

        function validateOptimizedSleep(~, optimizedSleep)
            if ~islogical(optimizedSleep)
                error(message('asyncio:Channel:invalidOptimizedSleep'));
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Event handlers
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        function onPropertyChanged(obj, name, value)
        % Handle property update from device plug-in.
            obj.(name) = value;
        end

        function onCustomEvent(obj, type, data)
        % Handle custom event from device plug-in.
        % Notify any listeners.
            notify(obj, 'Custom', matlabshared.asyncio.internal.CustomEventInfo(type,data));
        end

        function onDataReceived(obj)
        % Handle data received event from engine.

        % Notify any listeners with the amount of data available.
        % If no data is available to read, don't send the event.
            count = obj.InputStream.DataAvailable;
            if count > 0
                notify(obj.InputStream, 'DataWritten', ...
                                     matlabshared.asyncio.internal.DataEventInfo(count));
            end
        end

        function onDataSent(obj)
        % Handle data sent event from engine.

        % Notify any listeners with the amount of space available.
        % If no space is available to write, don't send the event.
            space = obj.OutputStream.SpaceAvailable;
            if space > 0
                notify(obj.OutputStream, 'DataRead', ...
                                     matlabshared.asyncio.internal.DataEventInfo(space));
            end
        end

        function status = isConstructionComplete(obj)
        % Tells if channel implementation completed or not. If ChannelImpl
        % is empty, AsyncIO Channel construction did not complete and vice
        % versa
        % OUTPUT:
        %   true => channel impl completed
        %   false => channel impl failed
            status = ~isempty(obj.ChannelImpl);
        end
    end

    properties(Hidden=true)
        % Enables/disables trace statements from plug-ins.
        TraceEnabled = false;

        % Enables/disables the data flow events from the underlying
        % C++ channel. This is a performance optimization for clients
        % that don't need to use the DataRead and DataWritten events.
        % NOTE: Must be set before the channel is opened.
        DataEventsDisabled = false;
    end

    properties(GetAccess='private',SetAccess='private')
        % Underlying C++ implementation of channel.
        ChannelImpl;

        % Handler for ChannelImpl messages.
        MessageHandler;

        % Listeners for ChannelImpl events.
        CustomListener;
        PropertyChangedListener;
        DataReceivedListener;
        DataSentListener;
    end

    methods(Hidden)
        function sobj = saveobj(~)
        %SAVEOBJ Handle save operations.
        %SAVEOBJ() Overrides ability to save AsyncIO Channel objects.

        % Properties holding matlabshared.asyncio.internal.Channel objects should set their
        % Transient attribute to true.
            sobj = [];
        end
    end
end

% LocalWords:  DEVICEPLUGINPATH CONVERTERPLUGINPATH STREAMLIMITS MESSAGEHANDLER Async IO's
% LocalWords:  HASCUSTOMPROP GETCUSTOMPROP Dequeue dequeue LIBRARYLOADSEARCHPATH OPTIMIZEDSLEEP
% LocalWords:  isstring testmlconverterarrays impl MDA
