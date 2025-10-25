classdef (Hidden) BufferChannel < matlabshared.asyncio.internal.Channel 
    %BUFFERCHANNEL An asyncio channel representing a buffer;
    %
    % Use:
    %    bc = matlabshared.asyncio.buffer.internal.BufferChannel(STREAMLIMITS, NOTIFICATIONCOUNT, PLUGININFO);
    %    bc = matlabshared.asyncio.buffer.internal.BufferChannel(STREAMLIMITS, NOTIFICATIONCOUNT);
    %    bc = matlabshared.asyncio.buffer.internal.BufferChannel(STREAMLIMITS);
    %
    % Example: buffer channel (no notification)
    %   bc = matlabshared.asyncio.buffer.internal.BufferChannel([inf 0]); 
    %   bc.open();
    %
    %   bc.enableTrace();
    %   packetSize = 1024;
    %   data = linspace(-1, 1, packetSize)';
    %
    %   bc.write(data);
    %   bc.write(3*data);
    %
    %   getData = bc.read(packetSize);  % (-1, 1)
    %   getData = bc.read(packetSize);  % (-3, 3)    
    %
    %   bc.close();
    %   clear bc;
    %
    % Example: buffer channel (with notification)
    %   packetSize = 1024;
    %   bc = matlabshared.asyncio.buffer.internal.BufferChannel([inf 0], packetSize); 
    %   bc.open();
    %
    %   
    % See also matlabshared.asyncio.buffer.Buffer
    %
    % Notes: 
    %   This class is meant primarily for internal development. In most 
    %   cases, matlabshared.asyncio.buffer.Buffer is more appropriate.
    %
    %   This undocumented class may be removed in a future release.

    % Copyright 2018-2021 The MathWorks, Inc.

    %#codegen
    % Dynamicprops added by asyncio channel: none

    properties (Dependent)
        % The number of elements available in the buffer
        NumElementsAvailable (1, 1) double {mustBeNonnegative}
        
        % Send out a notification when the number of elements available
        % reaches or exceeds this threshold  
        ElementsAvailableEventCount (1, 1) double {mustBePositive}
    end
    
    properties (SetAccess = private)
        % The total number of elements written to the buffer
        TotalElementsWritten (1, 1) double {mustBeNonnegative}
    end
    
    %------------------------------------------------------------------
    % For code generation support
    %------------------------------------------------------------------
    methods(Static)
        function name = matlabCodegenRedirect(~)
            % Use the implementation in the class below when generating
            % code.
            name = 'matlabshared.asyncio.buffer.internal.coder.BufferChannel';
        end
    end
    
    events (NotifyAccess = private)
        ElementsAvailable
    end 
    

    
    %% Lifetime
    methods
        function obj = BufferChannel(streamLimits, notifyWhenNumElementsAvailableExceeds, pluginInfo)
            % BUFFERCHANNEL Create an asynchronous channel that acts as a
            % buffer for any data-type that can be represented as a MATLAB DATA
            % ARRAY (MDA)
            %
            % OBJ = BUFFERCHANNEL(STREAMLIMITS, NOTIFICATIONCOUNT, PLUGININFO)
            %
            % Creates an asyncio channel with an input stream that feeds
            % directly into its output stream.
            %
            % Inputs:
            %
            % STREAMLIMITS - An array of two doubles that indicate the
            % maximum number of items to buffer in the input and output
            % streams. Valid values for input stream are (0..Inf]. Valid
            % values for output stream are [0..Inf]; [Inf, 0] is
            % recommended for optimum performance.
            %
            % NOTIFICATIONCOUNT - A double indicating how many elements
            % need to be available before an event notification is issued.
            % The default value is Inf (never issue a notification).
            %
            % PLUGININFO - A structure containing three fields: folder,
            % converterPath, and devicePath. The converter plugin path and
            % device plugin path are relative to the folder specified. The
            % plugin info does not need to be specified (used for
            % development).
            %
            % Notes: none
            
            % Define a plugin directory if one isn't provided
            narginchk(1, 3);
            
            if nargin < 3
                pluginInfo.folder = fullfile(toolboxdir('shared'), 'testmeaslib', 'general', 'bin', computer('arch'));
                pluginInfo.converterPath = fullfile(pluginInfo.folder, 'buffermlconverter');
                pluginInfo.devicePath = fullfile(pluginInfo.folder, 'buffer');
            end
            
            if nargin < 2
                notifyWhenNumElementsAvailableExceeds = Inf;
            end
            
            initOptions = [];
            
            if streamLimits(1) == 0
                error(message('testmeaslib:AsyncioBuffer:InvalidInputStreamLimit'));
            end
            
            obj@matlabshared.asyncio.internal.Channel(pluginInfo.devicePath, ...
                                pluginInfo.converterPath,...
                                Options = initOptions,...
                                StreamLimits = streamLimits);
                            
            obj.ElementsAvailableEventCount = notifyWhenNumElementsAvailableExceeds;
            % If true, then write & read explicitly (no events required)
            obj.DataEventsDisabled = isinf(notifyWhenNumElementsAvailableExceeds);             
            
            obj.StreamLimits = streamLimits;
            obj.PluginInfo = pluginInfo;            
        end
        
        function delete(obj)
            % DELETE Destroy the buffer channel.
            %
            % If the communication channel is still open, it will be closed
            % and all data in the buffer will be lost.
            if obj.isOpen()
                obj.close()
            end
        end
    end
    
    %% Set / Get
    methods
        function count = get.NumElementsAvailable(obj)
            % The buffer channel stores all of its elements in its
            % InputStream.
            count = obj.InputStream.DataAvailable;
        end
        
        function notifyWhenNumElementsAvailableExceeds = get.ElementsAvailableEventCount(obj)
            notifyWhenNumElementsAvailableExceeds = obj.NotificationCountInternal;
        end
        
        function set.ElementsAvailableEventCount(obj, notifyWhenNumElementsAvailableExceeds)
            obj.NotificationCountInternal = notifyWhenNumElementsAvailableExceeds;
            
            if isempty(obj.DataWrittenListener)
                obj.createListener();
            end
            
            obj.updateListener(~isinf(notifyWhenNumElementsAvailableExceeds));
        end         
    end
    
    %% Operations
    methods (Sealed)
        function write(obj, data, blockSize)
            % WRITE Store data in the buffer channel.
            %
            % WRITE(OBJ, DATA, BLOCKSIZE)                      
            % Writes an array of data to the output stream. If the count of
            % given array is greater than SpaceAvailable then this method
            % will block, where the count is the number of rows of data.
            %
            % Inputs: 
            % DATA - An array of data with any type that can be
            % represented by a MATLAB DATA ARRAY (MDA).
            %
            % BLOCKSIZE - Indicates the number of items to attempt to write
            % to the buffer at one time. This parameter is optional, and if
            % specified, causes the data to be broken up along the count
            % dimension into a cell array of packets before writing to the
            % device. If not specified, the entire matrix will be written
            % to the output stream as one packet. The count-dimension of
            % the buffer is 1 (rows).
            
            narginchk(2, 3)
            
            if nargin < 3
                blockSize = [];
            end              
            
            if isempty(data)
                error(message('testmeaslib:AsyncioBuffer:InvalidWriteData'));
            end            
            
            obj.TotalElementsWritten = obj.TotalElementsWritten + size(data, 1);
            
            if isempty(blockSize)
                obj.OutputStream.write(data);
            else
                obj.OutputStream.write(data, blockSize);
            end
        end  
        
        function data = read(obj, count)
            %READ Read data from the buffer channel.
            %
            % DATA = READ(OBJ, COUNT)
            % reads the requested number of items from the input stream. 
            %
            % Inputs:            
            % COUNT - Indicates the number of items to read. This
            % parameter is optional and defaults to all the data currently
            % available.
            %
            % Outputs:            
            % DATA - An array of data (of any type that can be represented
            % by a MATLAB DATA ARRAY (MDA). If no data was returned this
            % will be an empty array.

            narginchk(1, 2);
            
            if nargin == 1
                count = obj.NumElementsAvailable;
            else                        
                count = min(count, obj.NumElementsAvailable);
            end

            if isempty(count) || count == 0
                data = [];
            else            
                data = obj.InputStream.read(count);
            end
        end
        
        function flush(obj)
            % FLUSH Remove all data stored in the buffer (sets 
            % NumElementsAvailable to 0).
            obj.InputStream.flush();
            obj.OutputStream.flush();            
        end                
        
        function reset(obj)
            % RESET Remove all data stored in the buffer (sets both
            % NumElementsAvailable and TotalElementsWritten to 0).
            obj.TotalElementsWritten = 0;
            obj.flush();            
        end         
    end

    %% Debug / Helpers    
    methods (Hidden, Sealed)
        % Trace / Debug
        function enableTrace(obj)
            obj.TraceEnabled = true;
        end
        
        function disableTrace(obj)
            obj.TraceEnabled = false;
        end
        
        function addFilter(obj, filterPluginPath, options)
            % ADDFILTER Add an asyncio filter to the input stream. Filters
            % can be used to modify the data stored in the input stream.
            %
            % ADDFILTER(OBJ, FILTERPLUGINPATH, OPTIONS) adds a filter to the
            % input stream by loading the given filter plug-in and
            % initializing it with the given options.
            %
            % Inputs:
            % FILTERPLUGINPATH - The full path and name of the filter plug-in.
            % The file extension of the plug-in should be omitted.
            %
            % OPTIONS - A structure containing information that needs to be
            % passed to the filter plug-in during initialization. This parameter
            % is optional and defaults to an empty structure.
            %
            % Notes:
            % - Filters can only be added when the stream is in the closed state.
            % - Filters will be opened when the parent Channel is opened.
            % - Filters will be closed when the parent Channel is closed.
            % - Filters will be opened, applied, and closed in the same order
            %   in which they were added to the stream.
            
            narginchk(2, 3);
            
            if nargin == 2
                options = [];
            end
        
            isOpen = obj.isOpen;
            
            if isOpen
                obj.close();
            end
            
            obj.InputStream.addFilter(filterPluginPath, options);
            
            if isOpen
                obj.open();
            end        
        end
        
        function tuneFilters(obj, options)
            %TUNEFILTERS tunes all the filters of the input stream.
            %
            %   TUNEFILTERS(OBJ, OPTIONS) tunes all the filters of the
            %   input stream by sending the given options to all the
            %   filters.
            %
            % Inputs:
            %    OPTIONS is a structure containing information that will be
            %    passed to all filter plug-ins for the input stream.
            %
            % Notes:
            %    1) Filters can be tuned whether the input stream is open
            %    or closed.            
            %    2) Filters will be tuned in the order in which they were
            %    added to the stream. 
            %    3) If any filter throws an error, the remaining filters
            %    will not be tuned. The error will appear in the MATLAB
            %    command window, and the Channel will remain in the same
            %    open/closed state.

            narginchk(1, 2);
            
            if nargin == 1
                options = [];
            end
            
            obj.InputStream.tuneFilters(options);
        end
        
        function drain(obj)
            % DRAIN Wait until all the data drains from the output stream.
            %
            % DRAIN(OBJ) waits until all data in the output stream has been
            % transferred to the input stream; however, if the channel is
            % closed, or the device becomes done, or a timeout occurs, or
            % an error occurs while waiting, then the remaining data in the
            % output stream is discarded.
            
            obj.OutputStream.drain();
        end
    end     
    
    %% Save / Load    
    properties (Access = private)
        % These properties exist to store values required to save & load a
        % BufferChannel        
        StreamLimits
        PluginInfo
    end    
    
    methods
        function s = saveobj(obj)
            s.StreamLimits = obj.StreamLimits;
            s.PluginInfo = obj.PluginInfo;
            s.ElementsAvailableEventCount = obj.ElementsAvailableEventCount;
        end
    end
    
    methods (Hidden, Static)
        function bc = loadobj(s)
            if isstruct(s)
                bc = matlabshared.asyncio.buffer.internal.BufferChannel(...
                    s.StreamLimits, ...
                    s.ElementsAvailableEventCount, ...
                    s.PluginInfo);
            else
                bc = s;
            end
        end
    end  
    
    %% Overrides
    methods (Access = protected)
        function postClose(obj)
        % Functionality done just after device is closed.
            postClose@matlabshared.asyncio.internal.Channel(obj);
            obj.reset();
        end            
    end
    
    %% Events
    properties (Transient, Access = private)
        DataWrittenListener (1, :) event.listener = event.listener.empty(1, 0)        
    end    
    
    properties (Access = private)
        NotificationCountInternal (1, 1) double {mustBePositive} = inf
    end
    
    methods (Access = private)
        function createListener(obj)
            objWeakRef = matlab.lang.WeakReference(obj);
            obj.DataWrittenListener =  event.listener(...
                obj.InputStream, 'DataWritten', @(src, evt) objWeakRef.Handle.dataWrittenHandler(src, evt));
        end
        
        function updateListener(obj, enabled)
            isOpen = obj.isOpen;
            
            if isOpen
                obj.close();
            end
            
            obj.DataEventsDisabled = ~enabled;
            obj.DataWrittenListener.Enabled = enabled;
            
            if isOpen
                obj.open();
            end
        end  
        
        function dataWrittenHandler(obj, ~, evt)
            count = evt.CurrentCount;
            if count >= obj.ElementsAvailableEventCount
                notify(obj, 'ElementsAvailable', matlabshared.asyncio.buffer.ElementsAvailableInfo(count));
            end
        end
    end   
end

