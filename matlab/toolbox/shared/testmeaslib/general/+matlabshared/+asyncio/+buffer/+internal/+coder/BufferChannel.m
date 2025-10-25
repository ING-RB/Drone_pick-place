classdef (Hidden) BufferChannel < matlabshared.asyncio.internal.Channel & ...
                                  coder.ExternalDependency
    %BUFFERCHANNEL An asyncio channel representing a buffer;
    %
    % Use:
    %    bc = matlabshared.asyncio.buffer.internal.BufferChannel(STREAMLIMITS);
    %
    % Example: buffer channel
    %   bc = matlabshared.asyncio.buffer.internal.BufferChannel([inf 0]); 
    %   bc.open();
    %
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
    %
    %   
    % See also matlabshared.asyncio.buffer.Buffer
    %
    % Notes: 
    %   This class is meant primarily for internal development. In most 
    %   cases, matlabshared.asyncio.buffer.Buffer is more appropriate.
    %
    %   This undocumented class may be removed in a future release.

    % Copyright 2019-2021 The MathWorks, Inc.

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
        % Datatype of elemets to read
        DataType (1,:) char {mustBeMember(DataType,{'uint8','uint16','uint32','uint64','int8','int16','int32','int64','single','double'})} = 'uint8';
        PartialPacket
        PartialPacketStart
        PartialPacketCount
        DataTypeInitialized = false
    end
    
    properties (Access = private)
        BytesPerElement = 1;
    end
    
    properties (Constant, Access = private)
        DefaultDataType = 'uint8' % There is no intention to support heterogeneous data in the buffer
        DefaultLibExtention = coder.const(feature('GetSharedLibExt'));
        DefaultFileSep = coder.const(filesep);
        DefaultDeviceName = 'buffer';
        DefaultOS = coder.const(computer('arch'));
        DefaultMATLABRoot = coder.const(matlabroot);
        DefaultMATLABVersion = coder.const(matlabRelease.Release);
        DefaultPluginRelativePath = coder.const(fullfile('toolbox', 'shared', 'testmeaslib', 'general', 'bin', computer('arch')));
    end
    
    % Implementation of coder.ExternalDependency
    methods(Static)
        function name = getDescriptiveName(~)
            name = 'BUFFERCHANNEL';
        end

        function tf = isSupportedContext(buildConfig)
            tf = buildConfig.isMatlabHostTarget(); % See also isCodeGenTarget()
        end

        function updateBuildInfo(buildInfo, buildConfig)
            % Add AsyncIO plugin for PackNGo.
            [~, ~, exeLibExt, libPrefix] = buildConfig.getStdLibInfo();          
            pluginPath = fullfile(matlabroot, 'toolbox', 'shared', 'testmeaslib', 'general', 'bin', computer('arch'));
            buildInfo.addNonBuildFiles([libPrefix 'buffer' exeLibExt],...
                                        pluginPath, 'BufferChannel AsyncIO device plugin');
            MLBinPath = fullfile(matlabroot, 'bin', computer('arch'));
            % This library is needed for foundation::extdata::Array and foundation::matlabdata::ArrayFactory
            buildInfo.addNonBuildFiles(['libmwfoundation_matlabdata' exeLibExt],...
                                        MLBinPath, 'libmwfoundation_matlabdata library');
            % This library is needed for foundation::matlabdata::standalone::ArrayFactory
            buildInfo.addNonBuildFiles(['libmwfoundation_matlabdata_standalone' exeLibExt],...
                                        MLBinPath, 'libmwfoundation_matlabdata_standalone library');
        end
    end
    
    methods (Access = private, Static)
        function devicePath = getPluginPath()
            % Helper method to derive plugin paths at run time.
            coder.extrinsic('matlabroot');
            coder.extrinsic('matlabRelease');
            coder.extrinsic('getfield');
            coder.extrinsic('exist');
            coder.varsize('devicePath', [], [0 1]);
            
            if strcmp(matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultOS, 'win64')
                libPrefix = '';
            else
                libPrefix = 'libmw';
            end
            deviceFullName = [libPrefix matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultDeviceName matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultLibExtention];
            if coder.internal.canUseExtrinsic()
                % This is for mex codegen. Use the device plaugin and
                % conveter plugin with the MATLAB where the mex is called.
                % The MATLAB that generates the mex and the MATLAB the
                % calls the mex should have the same release version and
                % for same OS. This implicitly enforce the MATLAB that runs
                % the mex should have proper licence. Otherwise the plugins
                % files could not be installed.
                thisOS = computer('arch');
                thisMLVersion = getfield(matlabRelease, 'Release');
                thisMatlabRoot = blanks(coder.ignoreConst(512));
                thisMatlabRoot = matlabroot;
                % Check if it running in same OS and same MATLAB
                % version
                if strcmp(thisOS, matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultOS)...
                        && strcmp(thisMLVersion, matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultMATLABVersion)
                    deviceFullPathML = [thisMatlabRoot matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultFileSep ...
                        matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultPluginRelativePath matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultFileSep deviceFullName];
                    if exist(deviceFullPathML, 'file')
                        % Fall back to the library from the MATLAB install
                        devicePath = deviceFullPathML;
                    else                        
                        % Error out. We should not allow mex to run
                        % if the MATLAB does not have the required library
                        % file. Usually it means it does not have proper
                        % licence, Need to have required version to run.
                        coder.internal.error('testmeaslib:AsyncioBuffer:CannotFindPlugin');
                        devicePath = '';
                    end
                else
                    % Wrong version of MATLAB the mex file is platform and 
                    % release specific
                    coder.internal.error('testmeaslib:AsyncioBuffer:WrongMATLABVersion',...
                        matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultMATLABVersion,...
                        matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultOS);
                    
                    devicePath = '';
                end             
            else
                % This is for lib, dll and exe mode. Library search order: 
                % 1. Current folder, this is usually the case if the user
                % set postCodegenCommand for packngo
                % 2. MATLAB path that generates the code, this is a fall
                % back option if the user did not set postCodegenCommand
                % for packngo. The dll and exe should still run on the same
                % machine that generates the code
                deviceFullPath = matlabshared.asyncio.internal.coder.computeAbsolutePath(deviceFullName);
                if ~isempty(deviceFullPath)
                    % Located device plugin in the current folder first
                    devicePath = deviceFullPath;
                else
                    % Check if the MATLAB that generates the code is still
                    % available
                    deviceFullPathML = matlabshared.asyncio.internal.coder.computeAbsolutePath(...
                        [matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultMATLABRoot matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultFileSep ...
                        matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultPluginRelativePath matlabshared.asyncio.buffer.internal.coder.BufferChannel.DefaultFileSep deviceFullName]);
                    if ~isempty(deviceFullPathML)                        
                        % Fall back to the library from the MATLAB install
                        devicePath = deviceFullPathML;
                    else
                        % Error out. Cannot find the device plugin
                        coder.internal.error('testmeaslib:AsyncioBuffer:CannotFindPlugin');
                        devicePath = '';
                    end
                end
            end
        end
    end
    
    %% Lifetime
    methods
        function obj = BufferChannel(streamLimits)
            % BUFFERCHANNEL Create an asynchronous channel that acts as a
            % buffer for any non-complex numeric data type
            %
            % OBJ = BUFFERCHANNEL(STREAMLIMITS)
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
            % Notes: none
            
            % Define a plugin directory if one isn't provided
            narginchk(1, 1);
            
            initOptions = [];
            
            %Dynamic derive device plugin path            
            devicePath = matlabshared.asyncio.buffer.internal.coder.BufferChannel.getPluginPath();
            obj@matlabshared.asyncio.internal.Channel(devicePath, ...
                                [],...
                                CountDimensions = [2 2],...
                                Options = initOptions,...
                                StreamLimits = streamLimits, ...
                                CoderExampleData = zeros(1, 1, 'uint8'));
                            
            % In code generation, calls to base constructors cannot be 
            % preceded by FOR, WHILE, SWITCH, IF or RETURN. The check can
            % only being done here 
            if streamLimits(1) == 0
                coder.internal.error('testmeaslib:AsyncioBuffer:InvalidInputStreamLimit');
            end
                            
            % If true, then write & read explicitly (no events required)
            obj.DataEventsDisabled = true;             
            obj.StreamLimits = streamLimits;
            obj.TotalElementsWritten = 0;
            obj.clearPartialPacket();
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
            % The buffer channel stores its elements in its InputStream and
            % PartialPacket.
            % This is raw byte count
            count = obj.InputStream.DataAvailable + obj.PartialPacketCount;
            % Convert into number count according to the actual datatype 
            count = count/obj.BytesPerElement;
        end

        function count = get.ElementsAvailableEventCount(~)
            coder.internal.assert(false, 'testmeaslib:AsyncioBuffer:PropertyNotSupportedByCodegen', 'ElementsAvailableEventCount');
            count = 0;
        end
        
        function set.PartialPacket(obj, val)
            obj.PartialPacket = zeros(1, coder.ignoreConst(0), 'like', val);
            obj.PartialPacket = val;
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
            % DATA - An vector of data with any numeric type. All the 
            % elements of this vector have to be real numbers.
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
            
            validateattributes(data, {'numeric'}, {'nonempty', 'real', ...
                'nonnan', 'vector'}, mfilename, 'data');
                
            % oldDataType would be [] if the property has not been assigned
            oldDataType = coder.internal.getprop_if_defined(obj.DataType);
            if ~isempty(oldDataType)
                coder.internal.assert(strcmp(class(data), oldDataType), ...
                    'testmeaslib:AsyncioBuffer:InvalidWriteDataTypeCodegen',...
                    class(data), oldDataType);
            end
            obj.DataType = class(data);           
            obj.BytesPerElement = obj.getNumBytes(obj.DataType);
            
            % This line would not be reached if tries to write different datatypes
            % It would error out at compile time            
            if ~strcmp('uint8', obj.DataType)
                convertedData = typecast(data, 'uint8');
                if isempty(blockSize)
                    obj.OutputStream.write(convertedData);
                else
                    obj.OutputStream.write(convertedData, blockSize);
                end
            else
                if isempty(blockSize)
                    obj.OutputStream.write(data);
                else
                    obj.OutputStream.write(data, blockSize);
                end
            end
            
            obj.TotalElementsWritten = obj.TotalElementsWritten + size(data, 1);
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
            % DATA - An vector of data (of any type that can be represented
            % by real numbers. If no data was returned this will be an empty
            % array.

            narginchk(1, 3);
            
            if nargin == 1
                count = obj.NumElementsAvailable;
            else                        
                count = min(count, obj.NumElementsAvailable);
            end
            
            if isempty(count) || count == 0
                data = zeros(0, 0, obj.DataType);
            else             
                if ~strcmp(obj.DataType, obj.DefaultDataType)
                    rawData = obj.readRaw(count*obj.BytesPerElement);
                    data = typecast(rawData(1,:), obj.DataType);
                else
                    data = obj.readRaw(count*obj.BytesPerElement);
                end
            end
        end
               
        function flush(obj)
            % FLUSH Remove all data stored in the buffer (sets 
            % NumElementsAvailable to 0).
            obj.InputStream.flush();
            obj.clearPartialPacket();
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
            coder.internal.assert(false, 'testmeaslib:AsyncioBuffer:TraceNotAvailableForCodegen');
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
    
    % methods to handle partial packet read 
    methods(Access='private')       
        function data = readRaw(obj, numBytesToRead)
            %READ Read raw (uint8) data from the buffer channel.
            %
            % DATA = READRAW(OBJ, COUNT)
            % reads the requested number of items from the input stream. 
            %
            % Inputs:            
            % COUNT - Indicates the number of items to read. This
            % parameter is optional and defaults to all the data currently
            % available.
            %
            % Outputs:            
            % DATA - An vector of uint8 data. If no data was returned this
            % will be an empty array.            
            
            if isempty(numBytesToRead) || numBytesToRead == 0
                data = zeros(0, 0, 'uint8');
            else
                [dataRead, countRead] = readPartialPacket(obj, numBytesToRead, 2);
                
                remainingCount = numBytesToRead - countRead;
                if remainingCount > 0
                    if remainingCount > obj.InputStream.DataAvailable
                        coder.internal.error('testmeaslib:AsyncioBuffer:CannotReadMoreDataThanAvailable');
                    end
                    rawData = obj.InputStream.read(obj.InputStream.DataAvailable, zeros(1, 1, obj.DefaultDataType));
                    if remainingCount < size(rawData, 2)
                        obj.setPartialPacket(rawData, 2);
                        dataReadNext = readPartialPacket(obj, remainingCount, 2);
                        data = [dataRead dataReadNext];
                    else
                        data = [dataRead rawData];
                    end
                else
                    data = dataRead;
                end
            end
        end
         
        function [dataRead, countRead] = readPartialPacket(obj, countRequested, countDimension)
            ppc = obj.PartialPacketCount;
            % If there is a partial packet, start with that.
            if ppc > 0
                pps = obj.PartialPacketStart;
                % If the left over partial packet fully satifies the read.
                if countRequested < ppc
                    dataRead = obj.extractFromPacket(countDimension, pps, pps+countRequested-1);
                    countRead = countRequested;
                    obj.PartialPacketStart = pps + countRead;
                    obj.PartialPacketCount = ppc - countRead;
                else
                    % Use the entire remaining partial packet.
                    dataRead = obj.extractFromPacket(countDimension, pps, pps+ppc-1);
                    countRead = ppc;
                    % Clear partial packet.
                    obj.clearPartialPacket();
                end
            else
                dataRead = zeros(0,0,'uint8');
                countRead = 0;
            end
        end
        
        function setPartialPacket(obj, data, countDimension)
            obj.PartialPacket = data;
            obj.PartialPacketStart = 1;
            obj.PartialPacketCount = size(data, countDimension);
        end
        
        function clearPartialPacket(obj)
            obj.PartialPacket = zeros(0, 0, 'uint8');
            obj.PartialPacketStart = 0;
            obj.PartialPacketCount = 0;
        end
        
        % This is from matlabshared.asyncio.internal.Stream.extractFromPacket
        function result = extractFromPacket(obj, countDimension, startIndex, endIndex)
        % EXTRACTFROMPACKET Extract the given sub-array in the count dimension.
        %
        % RESULT = EXTRACTFROMPACKET(PACKET, COUNTDIMENSION, STARTINDEX, ENDINDEX) extracts a
        % sub-array from the given matrix along the count dimension.
        %
        % Inputs:
        % PACKET - The N-dimensional array to extract data from.
        % COUNTDIMENSION - The dimension of the array along which to exract.
        %    From 1 to ndims(packet).
        % STARTINDEX - The index of the first element to extract.
        % ENDINDEX - The index of the last element to extract.
        %
        % Outputs:
        % RESULT - The resulting sub-array.
        %

        % Optimization for vectors - 50% over 2-D case.
            if isvector(obj.PartialPacket)
                result = obj.PartialPacket(startIndex:endIndex);

                % Optimization for 2-D arrays - 300% speedup over N-D case.
            elseif ismatrix(obj.PartialPacket)
                if countDimension == 1
                    result = obj.PartialPacket(startIndex:endIndex,:);
                else
                    result = obj.PartialPacket(:,startIndex:endIndex);
                end

                % For N-D arrays
            else
                % Create a cell array of indices for every dimension.
                dims = cell(1,ndims(obj.PartialPacket));
                for ii=1:length(dims)
                    if ii == countDimension
                        dims{ii} = startIndex:endIndex;
                    else
                        dims{ii} = 1:size(obj.PartialPacket,ii);
                    end
                end
                result = obj.PartialPacket(dims{:});
            end
        end
    end
    
    methods (Access = private, Static = true)
        function result = matlabCodegenNontunableProperties(~)
            result = {'DataType','DataTypeInitialized'};
        end
    end
    
    %% Save / Load    
    properties (Access = private)
        % These properties exist to store values required to save & load a
        % BufferChannel        
        StreamLimits
    end
    
    methods (Hidden, Static)
        function numBytes = getNumBytes(dataType)
            switch dataType
                case {'uint8', 'int8'}
                    numBytes = 1;
                case {'uint16', 'int16'} 
                    numBytes = 2;
                case {'uint32', 'int32', 'single'}
                    numBytes = 4;
                case {'uint64', 'int64', 'double'}
                    numBytes = 8;
                otherwise
                    numBytes = 1;
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
end

