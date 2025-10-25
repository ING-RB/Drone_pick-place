classdef Buffer < handle & matlab.mixin.Heterogeneous
    %BUFFER Generic buffer for storing data of any particular MATLAB type
    %
    % Usage:
    %    obj = matlabshared.asyncio.buffer.Buffer();
    %    obj = matlabshared.asyncio.buffer.Buffer(BUFFERSIZE);
    %
    %    BUFFERSIZE is the desired size of the buffer (in elements). This
    %    is an optional parameter (default is 'Inf').
    %    
    % Example:
    %   bf = matlabshared.asyncio.buffer.Buffer(); 
    %
    %   bf.enableTrace();
    %   blockSize = 1024;
    %   data = linspace(-1, 1, blockSize)';
    %
    %   bf.write(data);
    %   bf.write(3*data);
    %
    %   getData = bf.read(blockSize);  % (-1, 1)
    %   getData = bf.read(blockSize);  % (-3, 3)    
    %
    %   clear bf;
    %
    % Notes: none

    % Copyright 2018-2019 The MathWorks, Inc.

    properties (Dependent)
        % The number of elements available in the buffer
        NumElementsAvailable (1, 1) double
        
        % The total number of elements written to the buffer
        TotalElementsWritten (1, 1) double
        
        % Send out a notification when the number of elements available
        % reaches or exceeds this threshold        
        ElementsAvailableEventCount (1, 1) double {mustBePositive}        
    end

    properties
        % The maximum number of elements the buffer can store without
        % removing existing elements
        Size (1, 1) double {mustBePositive} = Inf
    end
    
    properties (Hidden)
        % Remove warning backtrace in the event that callback function is
        % specified incorrectly
        TrimBacktrace (1, 1) logical = false
    end
    
    events (NotifyAccess = protected)
        ElementsAvailable
    end
    
    %% Lifetime
    methods
        function obj = Buffer(bufferSize)
            % BUFFER Create an asynchronous buffer that acts as a buffer
            % for any data-type that can be represented as a MATLAB DATA
            % ARRAY (MDA)
            %
            % OBJ = BUFFER(BUFFERSIZE)
            %
            % Inputs:            
            % BUFFERSIZE - The maximum amount of data the buffer may hold.
            % If additional data is written to the buffer beyond this
            % amount, old data is removed to accommodate the new data
            %
            % Notes: none            
            
            narginchk(0, 1)
            
            if nargin == 0
                bufferSize = inf;
            end
            
            try
                obj.Channel = matlabshared.asyncio.buffer.internal.BufferChannel([inf 0]);
                obj.Channel.open();
                
                obj.Size = bufferSize;
                obj.ElementsAvailableEventCount = inf;
            catch e
                rethrow(e);
            end
        end
        
        function delete(obj)
            obj.Channel.close();
            obj.Channel = matlabshared.asyncio.buffer.internal.BufferChannel.empty(1, 0);
        end
    end
    
    %% Set / Get
    methods
        function count = get.NumElementsAvailable(obj)
            count = obj.getNumElementsAvailableHook();
        end
        
        function totalWritten = get.TotalElementsWritten(obj)
            totalWritten = obj.getTotalElementsWrittenHook();
        end
        
        function notificationCount = get.ElementsAvailableEventCount(obj)
            notificationCount = obj.getNotificationCountHook();
        end
        
        function set.ElementsAvailableEventCount(obj, notificationCount)
            obj.setNotificationCountHook(notificationCount);
            
            if isempty(obj.ElementsAvailableListener)
                obj.createListener();
            end
            
            obj.updateListener(~isinf(notificationCount));
        end
    end
    
    %% Operations
    methods
        function write(obj, data, blockSize)
            % WRITE Store data in the buffer.
            %
            % WRITE(OBJ, DATA, BLOCKSIZE)                      
            % Writes an array of data to the channel. If the count of
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
            % to the channel as one packet. The count-dimension of the
            % buffer is 1 (rows).
            
            narginchk(2, 3)
            
            if nargin < 3
                blockSize = [];
            end              
            
            if isempty(data)
                return
            end

            bufferSize = obj.Size;
            
            if isinf(bufferSize)
                obj.Channel.write(data, blockSize);
                return
            end
                
            dataSize = size(data, 1);
            availableSpace = bufferSize - obj.NumElementsAvailable;

            % Three possible outcomes for |data|:
            % 1. |data| <= |space|         : data fits in available space
            % 2. |space| < data < |buffer| : data fits in buffer; not in space
            % 3. |data| >= |buffer|        : data does not fit in buffer
            
            if dataSize >= bufferSize
                % 3. Just fill the buffer with the final points
                obj.flush();
                obj.Channel.write(data(end-bufferSize+1:end), blockSize);
            elseif dataSize > availableSpace
                % 2. Data fits in the buffer; the buffer does not have
                % enough available space. Free enough space to hold all the
                % incoming data
                [~] = obj.read(dataSize - availableSpace);
                obj.Channel.write(data, blockSize);
            else % dataSize <= availableSpace
                % 1. Data fits into available space
                obj.Channel.write(data, blockSize);
            end 
        end     
        
        function data = read(obj, count)
            %READ Read data from the input stream.
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
            
            data = obj.Channel.read(count);
        end
        
        function flush(obj)
            % FLUSH Remove all data stored in the buffer (sets
            % NumElementsAvailable to 0).
            narginchk(1, 1);
            obj.Channel.flush();            
        end
        
        function reset(obj)
            % RESET Remove all data stored in the buffer (sets both
            % NumElementsAvailable and TotalElementsWritten to 0).
            narginchk(1, 1);
            obj.Channel.reset();              
        end
        
        function notify(obj, varargin)
            if obj.TrimBacktrace
                ws = warning('off', 'backtrace');
                oc = onCleanup(@()warning(ws));
            end
                
            notify@handle(obj, varargin{:});
        end
    end 
    
    %% Debug / Helpers    
    methods (Hidden, Sealed)
        % Trace / Debug
        function enableTrace(obj)
            obj.Channel.enableTrace();
        end
        
        function disableTrace(obj)
            obj.Channel.disableTrace();
        end
        
        function addFilter(obj, filterPluginPath, options)
            % ADDFILTER Add an asyncio filter to the internal buffer
            % channel. Filters can be used to modify the data stored in the
            % buffer.
            %
            % ADDFILTER(OBJ, FILTERPLUGINPATH, OPTIONS) adds a filter to
            % the internal buffer channel by loading the given filter
            % plug-in and initializing it with the given options.
            %
            % Inputs:
            % FILTERPLUGINPATH - The full path and name of the filter
            % plug-in. The file extension of the plug-in should be omitted.
            %
            % OPTIONS - A structure containing information that needs to be
            % passed to the filter plug-in during initialization. This
            % parameter is optional and defaults to an empty structure.
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
        
            obj.Channel.addFilter(filterPluginPath, options);
        end
        
        function tuneFilters(obj, options)
            %TUNEFILTERS tunes all the filters of the internal buffer
            %channel
            %
            %   TUNEFILTERS(OBJ, OPTIONS) tunes all the filters of the
            %   buffer channel by sending the given options to all the
            %   filters.
            %
            % Inputs:
            %    OPTIONS is a structure containing information that will be
            %    passed to all filter plug-ins for the buffer channel.
            %
            % Notes:
            %    1) Filters will be tuned in the order in which they were
            %    added to the buffer channel
            %    2) If any filter throws an error, the remaining filters
            %    will not be tuned. The error will appear in the MATLAB
            %    command window, and the buffer channel will remain in the same
            %    open/closed state.
            
            narginchk(1, 2);
            
            if nargin == 1
                options = [];
            end            
            
            obj.Channel.tuneFilters(options);
        end                 
    end 
    
    %% Save / Load / 
    
    methods
        function s = saveobj(obj)
            s.Size = obj.Size;
            s.ElementsAvailableEventCount = obj.ElementsAvailableEventCount;
        end
    end
    
    methods (Hidden, Static)
        function bf = loadobj(s)
            if isstruct(s)
                bf = matlabshared.asyncio.buffer.Buffer(s.Size);
                bf.ElementsAvailableEventCount = s.ElementsAvailableEventCount;
            else
                bf = s;
            end
        end
    end    
    
    %% Limited Access
    properties (Transient, Access = protected)
        Channel (1, :) matlabshared.asyncio.buffer.internal.BufferChannel
    end
    
    methods (Access = protected)
        function count = getNumElementsAvailableHook(obj)
            count = obj.Channel.NumElementsAvailable;
        end
        
        function totalWritten = getTotalElementsWrittenHook(obj)
            totalWritten = obj.Channel.TotalElementsWritten;
        end
        
        function notificationCount = getNotificationCountHook(obj)
            notificationCount = obj.Channel.ElementsAvailableEventCount;
        end
        
        function setNotificationCountHook(obj, notificationCount)
            obj.Channel.ElementsAvailableEventCount = notificationCount;            
        end
        
        function dataWrittenHandler(obj, src, evt) %#ok<INUSL>
            % Forward the event issued by the channel
            notify(obj, 'ElementsAvailable', evt);
        end        
    end    
    
    properties (Transient, Access = private)
        ElementsAvailableListener (1, :) event.listener = event.listener.empty(1, 0)        
    end
    
    methods (Access = private)
        function createListener(obj)
            objWeakRef = matlab.lang.WeakReference(obj);
            obj.ElementsAvailableListener =  event.listener(...
                obj.Channel, 'ElementsAvailable', @(src, evt) objWeakRef.Handle.dataWrittenHandler(src, evt));
        end
        
        function updateListener(obj, enabled)
            obj.ElementsAvailableListener.Enabled = enabled;
        end  
    end
end

