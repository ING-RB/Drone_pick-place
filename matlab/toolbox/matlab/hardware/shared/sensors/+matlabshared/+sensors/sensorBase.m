classdef (Hidden) sensorBase < matlabshared.sensors.sensorInterface
    %Parent class for sensorUnit and sensorBoard
    
    %   Copyright 2019-2023 The MathWorks, Inc.
    
    properties(Nontunable,Dependent)
        %   SampleRate Sensor sample rate Specify the sampling rate of the
        %   input sensor data in Hertz as a finite numeric scalar.
        SampleRate;
    end
    
    properties(Access = protected)
        % since SampleRate is dependent and hence its value will not be
        % stored, 'DummySampleRate' is a wrapper property to store that
        % value
        DummySampleRate = 100;
        MaxSamplesPerRead = 500;
        isRegistered = 0;
        cleanUp; % This property is to invoke delete function even during partial construction
        timerVal = [];
    end
    
    properties(Abstract, SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate;
        MaxSampleRate;
    end
    
    properties(SetAccess = protected, GetAccess = public, Hidden)
        Parent; % this is the hardware object
    end
    
    properties(SetAccess = protected, GetAccess = public, Hidden,Nontunable)
        UniqueIds;
    end

    properties(Abstract, Access = protected, Constant)
        SupportedInterfaces;
    end
    
    properties(Access = protected,Nontunable)

        DefaultSampleRate=100;
        DefaultSamplesPerRead=10;
        DefaultReadMode='latest';
        DefaultOutputFormat='timetable';
        DefaultTimeFormat='datetime';
    end
    
    properties(Access = protected)
        StreamingObjRegister; % Listener object
    end
    
    properties(Access = protected, Constant)
        % If 'ToleranceTime' has elapsed between successive calls to step,
        % then transport buffer will be cleared.
        ToleranceTime = 3; % in seconds
    end
    
    methods(Abstract, Access = protected)
        setODRImpl(obj);
    end

    methods(Access = protected)
        function obj = sensorBase(varargin)
            if nargin>=1
                parent = varargin{1};
                if isa(parent,'matlabshared.sensors.simulink.internal.TargetI2CSensorUtilities') || isa(parent,'matlabshared.sensors.simulink.internal.TargetSPISensorUtilities') || isa(parent,'matlabshared.sensors.simulink.internal.TargetI2CSensorUtilitiesDeviceBased')
                    obj.isSimulink = 1;
                end
            end
            obj.cleanUp = onCleanup(@()delete(obj));
        end
    end

    methods
        function set.SampleRate(obj, value)
            % SampleRate setting is only required for MATLAB.Sample Rate
            % setting in simulink is used to set the ODR of sensors. In
            % Simulink, ODR for the units will be directly set as specified
            % from the mask.
            if(~obj.isSimulink)
                try
                    checkPropertyAvailablity(obj,'SampleRate');
                    value = setSampleRateHook(obj,value);
                    validateattributes(value,{'numeric'}, ...
                        {'real','positive','scalar', ...
                        '>=',obj.MinSampleRate,'<=',obj.MaxSampleRate},'','SampleRate');
                    if(obj.MLStreamingSupported == 1)
                        % The target side calculation for SampleRate
                        % requires SampleRate in seconds, inverting a
                        % integer value will round the numbers resulting in
                        % loss of precision
                        obj.DummySampleRate = double(value);
                    else
                        obj.DummySampleRate = 100;
                    end
                catch ME
                    throwAsCaller(ME);
                end
                setODRImpl(obj);
            end
        end
        
        function value = get.SampleRate(obj)
            % get method is defined for SampleRate since it is a dependent
            % property
            value = obj.DummySampleRate;
        end
        
        function set.Parent(obj, parent)
            if isa(parent, 'matlabshared.sensors.CommonSensorUtilities') &&...
                    isa(parent,'matlabshared.sensors.simulink.internal.TargetI2CSensorUtilitiesDeviceBased')||...
                    isa(parent, 'matlabshared.sensors.I2CSensorUtilities') ||...
                    isa(parent, 'matlabshared.sensors.SPISensorUtilities') ||...
                    isa(parent, 'matlabshared.hwsdk.controller') &&...
                    isa(parent, 'matlabshared.i2c.controller')
                obj.Parent = parent;
            else
                error(message('matlab_sensors:general:invalidHwObjSensor'));
            end
        end
    end
    
    methods(Access = protected)
        % Parses sensor Arguments which are common for both sensorUnit
        % and sensorBoard. The function returns a structure which has
        % parsed arguments
        
        function parserObj = parseSensorArguments(obj,varargin)
            if(nargin == 1)
                error(message('matlab_sensors:general:invalidHwObjSensor'));
            end
            obj.Parent = varargin{1};
            % Check if target supports streaming
            setIsStreamingSupported(obj);
%             [sampleRate,spf,readMode,outputFormat, timeFormat] = getSensorPropertyDefaultValue(obj);
            parserObj = inputParser;
            parserObj.CaseSensitive = 0;
            parserObj.PartialMatching = 1;
            % This parameters are only relevent for streaming
            if obj.MLStreamingSupported
                addParameter(parserObj, 'SampleRate',obj.DefaultSampleRate);
                addParameter(parserObj, 'SamplesPerRead',obj.DefaultSamplesPerRead);
                addParameter(parserObj, 'ReadMode', obj.DefaultReadMode);
                addParameter(parserObj, 'OutputFormat',obj.DefaultOutputFormat);
                addParameter(parserObj, 'TimeFormat',obj.DefaultTimeFormat);
            end
            addParameter(parserObj, 'I2CAddress',[]);
            addParameter(parserObj, 'SPIChipSelectPin',[]);
            addParameter(parserObj,'Bus',0);
            parse(parserObj, varargin{2:end});
        end
        
        function [sampleRate,spf,readMode,outputFormat, timeFormat] = getSensorPropertyDefaultValue(~)
            sampleRate = 100;
            spf= 10;
            readMode = 'latest';
            outputFormat = 'timetable';
            timeFormat = 'datetime';
        end

        function checkStreamingValidity(obj)
            try
                if ~isa(obj.Parent, 'matlabshared.sensors.MultiStreamingUtilities')
                    error(message('matlab_sensors:general:streamingNotSupportedOnHardware','read', class(obj.Parent)));
                end
                % TraceOn should be false to enable streaming
                if matlabshared.sensors.isTraceEnabled(obj.Parent)
                    error(message('matlab_sensors:general:unSupportedCommandLogs','sensors'))
                end
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function sampleRate = setSampleRateHook(~,value)
            sampleRate = value;
        end
        
        function setPropertiesWithStreamingInfoHook(obj,props)
%             If it is MATLAB ondemand
            if(~obj.MLStreamingSupported && ~obj.isSimulink)
                setODRImpl(obj);
            elseif ~obj.isSimulink
                obj.SampleRate = props.SampleRate;
            end
        end
        
        function value = getSamplesAvailableImpl(obj)
            if ~obj.MLStreamingSupported
                value = 0;
                return;
            end
            if(~isempty(obj.UniqueIds))
                value = getPacketsAvailable(obj.Parent.getProtocolObject(), obj.UniqueIds);
            else
                value = 0;
            end
        end
        
        function methodsToDisplay(obj)
            % get the built in methods
            methodNames = builtin('methods', obj);
            % remove unwanted methods
            unwantedMethods = {'addlistener','ge','clone','gt','lt','eq','isLocked','ne','reset','findobj','isvalid','notify',...
                'step','findprop','le','listener',class(obj)};
            if(~obj.MLStreamingSupported)
                unwantedMethods = [unwantedMethods, {'read'}, {'flush'}, {'release'},{'stop'}];
            end
            for i=1:length(unwantedMethods)
                index = strcmp(unwantedMethods{i}, methodNames);
                methodNames(index) = [];
            end
            % Calculate the longest base method name.
            maxLength = max(cellfun('length', methodNames));
            % Calculate spacing information.
            maxColumns = floor(80/maxLength);
            maxSpacing = 2;
            numOfRows = ceil(length(methodNames)/maxColumns);
            % Reshape the methods into a numOfRows-by-maxColumns matrix.
            numToPad = (maxColumns * numOfRows) - length(methodNames);
            methodNames = reshape([methodNames; repmat({' '},[numToPad 1])], numOfRows, maxColumns);
            % Print out the methods.
            for i = 1:numOfRows
                out = '';
                for j = 1:maxColumns
                    m = methodNames{i,j};
                    out = [out sprintf([m blanks(maxLength + maxSpacing - length(m))])]; %#ok<AGROW>
                end
                fprintf([out '\n']);
            end
        end
        
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            obj.showProperties;
            name = inputname(1);
            out  = ['Show <a href="matlab:showAllProperties(' name ')" style="font-weight:bold">all properties</a>',' <a href="matlab:showFunctions(' name ')" style="font-weight:bold">all functions</a>'];
            if ~isempty(out)
                disp(out);
            end
            fprintf('\n');
        end
    end
    
    methods(Hidden)
        function delete(obj)
            if(isvalid(obj) || ~isempty(obj))
                if(isLocked(obj))
                    release(obj)
                end
                obj.StreamingObjRegister = [];
            end
        end
        
        function showFunctions(obj)
            methodsToDisplay(obj);
        end
        
        function showSensorProperties(~)
            % Hook to display any sensor specific properties.
        end
    end
    
    methods (Static,Hidden)
        function varargout= isSensorBoard(ops,varargin)
            % sensor Board has multiple sensor units. This property avoids
            % multiple call to the same functions
            persistent flag;
            if(isempty(flag))
                flag = 0;
            end
            switch ops
                case 'set'
                    flag = varargin{1};
                case 'get'
                    varargout{1} = flag;
            end
        end
    end
end