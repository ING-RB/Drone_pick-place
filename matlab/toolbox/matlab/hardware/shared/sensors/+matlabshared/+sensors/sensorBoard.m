classdef (Hidden) sensorBoard < matlabshared.sensors.sensorBase
    %Parent class for sensor with multiple dies( multiple I2CAddress)
    
    %   Copyright 2018-2023 The MathWorks, Inc.
    
    properties(Abstract, Access = public, Hidden)
        SensorObjects;
    end
    
    properties(Abstract, Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        NumSensorUnits
    end
    
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate
        MaxSampleRate
    end
    
    properties(Access = private)
        TotalOutputs = 0;
        DataNames = [];
    end

    properties(Hidden)
        Device;
    end
    
    properties(Access = protected)
        numOverrunSamplesPrevRead = 0;
    end
    
    methods(Abstract, Access = protected)
        obj = createSensorUnitsImpl(obj,varargin);
    end

     properties(Access=protected)
        Bus;
        I2CAddress;
        Interface = 'I2C';
        BitRate = 100000;
        SDAPin = '';
        SCLPin = '';
    end
    
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % During code generation, the current class will be replaced by
            % the following class
            name = 'matlabshared.sensors.coder.matlab.sensorBoard';
        end
    end
    
    methods(Access = protected)
        function obj = sensorBoard(varargin)
            obj@matlabshared.sensors.sensorBase(varargin{:});
        end
        
        function init(obj, varargin)
            try
                parserObj = parseSensorArguments(obj,varargin{:});
                %  This function is to avoid duplicate registration of
                %  sensor Units
                matlabshared.sensors.sensorBase.isSensorBoard('set',1);
                validateI2CAddresses(obj,parserObj);
                createSensorUnitsImpl(obj,varargin{:});
                minVal = 0;
                maxVal = Inf;
                obj.DataNames = cell(1,numel(obj.SensorObjects));
                for i = 1:numel(obj.SensorObjects)
                    if(obj.SensorObjects{i}.MinSampleRate > minVal)
                        minVal = obj.SensorObjects{i}.MinSampleRate;
                    end
                    if(obj.SensorObjects{i}.MaxSampleRate < maxVal)
                        maxVal = obj.SensorObjects{i}.MaxSampleRate;
                    end
                    obj.TotalOutputs =  obj.TotalOutputs + numel(obj.SensorObjects{i}.DoF);
                    obj.I2CAddress(i) = obj.SensorObjects{i}.Device.I2CAddress;
                    obj.DataNames{i} = obj.SensorObjects{i}.DataNames;
                end
                obj.Bus = obj.SensorObjects{1}.Device.Bus;
                obj.BitRate = obj.SensorObjects{1}.Device.BitRate;
                obj.SDAPin = obj.SensorObjects{1}.Device.SDAPin;
                obj.SCLPin = obj.SensorObjects{1}.Device.SCLPin;
                obj.MinSampleRate = minVal;
                obj.MaxSampleRate = maxVal;
                if(obj.MaxSampleRate < obj.MinSampleRate)
                    error(message('matlab_sensors:general:invalidSampleRateRange'));
                end
                setPropertiesWithStreamingInfo(obj,parserObj.Results);
                % If the target supports streaming add listener
                if isa(obj.Parent,'matlabshared.sensors.MultiStreamingUtilities')
                    obj.StreamingObjRegister = event.proplistener(obj.Parent, obj.Parent.findprop( 'RegisterStreamingObjectsEvent'), 'PostSet',  @(~, ~)(obj.Parent.registerStreamingObjects(obj)));
                end
            catch ME
                matlabshared.sensors.sensorBase.isSensorBoard('set',0);
                throwAsCaller(ME);
            end
            matlabshared.sensors.sensorBase.isSensorBoard('set',0);
        end
        
        function setupImpl(obj)
            try
                checkStreamingValidity(obj)
                if obj.Parent.isStreaming
                    error(message('matlab_sensors:general:streamingInProgress'));
                else
                    %  This check is required so that registration and
                    %  calling setup of all sensors happen only once.
                    % Calling the setup of an object locks the object,
                    % for multistreaming, if one object is locked, lock
                    % all other sensor objects as well
                    matlabshared.sensors.sensorBase.isSensorBoard('set',1);
                    try
                        if ~obj.Parent.SensorsRegistered
                            obj.Parent.RegisterStreamingObjectsEvent = 1; % Trigger the listeners, which will register all the sensor objects
                            obj.Parent.SensorsRegistered = true; % Once all the sensors are registered, make this flag true
                            startStreamingAllObjects(obj.Parent,obj);
                            dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.Streaming); %Collect DDUX data for sensors (MATLAB). Streaming mode.
                            % Once the streaming starts unregister all the objects registered
                            unRegisterStreamingObjects(obj.Parent);
                        end
                        try
                            for i = 1:numel(obj.SensorObjects)
                                setup(obj.SensorObjects{i})
                            end
                        catch ME
                            for i = 1:numel(obj.SensorObjects)
                                release(obj.SensorObjects{i});
                            end
                            throwAsCaller(ME);
                        end
                    catch ME
                        obj.UniqueIds = [];
                        unRegisterStreamingObjects(obj.Parent);
                        matlabshared.sensors.sensorBase.isSensorBoard('set',0);
                        throwAsCaller(ME);
                    end
                end
            catch ME
                throwAsCaller(ME);
            end
            obj.timerVal = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss Z');
            matlabshared.sensors.sensorBase.isSensorBoard('set',0);
        end
        
        function varargout = stepImpl(obj)
            try
                matlabshared.sensors.sensorBase.isSensorBoard('set',1);
                if(isequal(lower(string(obj.ReadMode)),'latest'))
                    timeNow = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss Z');
                    % if obj.ToleranceTime has elapsed between 2 calls to
                    % 'step' or between a step and a reset, then clear the
                    % transport buffer and count the number of points trashed.
                    % This is done only for 'latest' buffering mode.
                    if((seconds(timeNow - obj.timerVal) > obj.ToleranceTime))
                        matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:hostBuffersFlushed');
                    end
                    obj.timerVal = timeNow;
                end
                if(isequal(lower(string(obj.OutputFormat)),'timetable'))
                    varargout = cell(1,2); % timetable and overruns
                    for i = 1:numel(obj.SensorObjects)
                        try
                            [tt,overruns] = step(obj.SensorObjects{i});
                            if(i == 1)
                                % store the timestamp of timetable returned by one
                                % of the sensor Unit.This will be the RowTimes of final timetable Output
                                RowTimes = tt.Properties.RowTimes;
                                if(nargout>1)
                                    varargout{2} = overruns;
                                end
                            end
                            % make all the RowTimes of timetable zeros.For
                            % horizontal appending of timetable, the time
                            % property needs to be same.
                            tt.Properties.RowTimes = seconds(zeros(obj.SamplesPerRead,1));
                            obj.timeTableOutput = [obj.timeTableOutput tt];
                        catch ME
                            obj.timeTableOutput = [];
                            throwAsCaller(ME)
                        end
                    end
                    obj.timeTableOutput.Properties.RowTimes = RowTimes;
                    varargout{1} = obj.timeTableOutput;
                    obj.timeTableOutput = [];
                else
                    % output format is matrix
                    index = 1;
                    % +2 is for overrun and time
                    varargout = cell(1,obj.TotalOutputs+2);
                    for i = 1:numel(obj.SensorObjects)
                        outputCell = cell(1, numel(obj.SensorObjects{i}.DoF));
                        [outputCell{:},timestamp, overrun] = step(obj.SensorObjects{i});
                        if(i == 1)
                            time = timestamp;
                            numOverrunSamplesSinceLastRead = overrun;
                        end
                        for j = 1:numel(outputCell)
                            varargout{index} = outputCell{j};
                            index = index + 1;
                        end
                    end
                    if(nargout>obj.TotalOutputs)
                        varargout{index} = time;
                        varargout{index+1} = numOverrunSamplesSinceLastRead;
                    end
                end
                obj.SamplesRead = obj.SamplesRead + obj.SamplesPerRead;
                matlabshared.sensors.sensorBase.isSensorBoard('set',0);
            catch ME
                matlabshared.sensors.sensorBase.isSensorBoard('set',0);
                throwAsCaller(ME);
            end
        end
        
        function resetImpl(obj)
            try
                if ~isa(obj.Parent, 'matlabshared.sensors.MultiStreamingUtilities')
                    return;
                end
                protocolObj = obj.Parent.getProtocolObject();
                setIgnoreOnetimeConfig(protocolObj, 0); % to make sure that this flushBuffers command is executed
                flushBuffers(protocolObj);
                for i = 1:numel(obj.SensorObjects)
                    reset(obj.SensorObjects{i});
                end
                obj.SamplesRead = 0;
                obj.SamplesAvailable = 0;
            catch ME
                throwAsCaller(ME);
            end
        end
        
        function releaseImpl(obj)
            try
                matlabshared.sensors.sensorBase.isSensorBoard('set',1);
                if  obj.Parent.SensorsRegistered == false
                    % Listener is attached with RegisterObjects
                    % property. Trigger this only once when no
                    % sensors are registerd
                    obj.Parent.RegisterStreamingObjectsEvent = 1; % Trigger the listeners
                    obj.Parent.SensorsRegistered = true;
                    releaseAllStreamingObjects(obj.Parent,obj);
                    unRegisterStreamingObjects(obj.Parent);
                end
                % release of sensor units is called to unlock them.
                for i = 1:numel(obj.SensorObjects)
                    release(obj.SensorObjects{i});
                end
                matlabshared.sensors.sensorBase.isSensorBoard('set',0);
                obj.UniqueIds = [];
                obj.numOverrunSamplesPrevRead = 0;
            catch ME
                matlabshared.sensors.sensorBase.isSensorBoard('set',0);
                throwAsCaller(ME);
            end
        end
    end
    
    methods(Access = public)
        function varargout = read(obj)
            % [Data, overrun] = read(imu); Reads data from the sensor.
            %
            % 'Data' is 'timetable' with fields 'Time' and those
            % corresponding to the physical quantities that the sensor measures
            % if 'OutputFormat' is 'timetable'. 'overrun' gives the number of
            % samples dropped since last read. 'overrun' is always zero if
            % 'ReadMode' is 'oldest', since no samples are dropped in this mode.
            %
            % If 'OutputFormat' is 'matrix', 'read' returns matrix outputs
            % for all the physical quantities that the sensor measures.
            % 'Time will be a column vector. For example, for an IMU
            % sensor, the read output in 'matrix' format is given by,
            %
            % [accel, angVel, magField, timeStamp, overrun] = read(imu);
            %
            try
                if(isequal(lower(string(obj.OutputFormat)),'timetable'))
                    nargoutchk(0,2) % for timetable and overrun
                    varargout = cell(1,2); % for timetable and overrun
                    [data, overrun] = step(obj);
                    varargout{1} = data;
                    if(nargout>1)
                        varargout{2} = overrun;
                    end
                else
                    nargoutchk(0,obj.TotalOutputs+2) %is for overrun and time
                    varargout = cell(1,obj.TotalOutputs+2); % +2 for time and overrun
                    [varargout{:}] = step(obj);
                end
            catch ME
                throwAsCaller(ME);
            end
        end
    end
    
    methods(Access = protected)
        function validateI2CAddresses(obj,parserObj)
            if ~any(contains(parserObj.UsingDefaults,'I2CAddress'))
                givenI2CAddress = parserObj.Results.I2CAddress;
                validateattributes(givenI2CAddress,{'numeric','cell','string','char'},{'nonempty'},'','I2CAddress')
                if(~isequal(numel(givenI2CAddress),obj.NumSensorUnits))
                    % if number of i2c addresses given is not equal to the
                    % number of sensor units held by the board.
                    error(message('matlab_sensors:general:incorrectNumI2CAddresses',num2str(obj.NumSensorUnits)));
                end
            end
        end
        
        function setODRImpl(obj)
            if(~isempty(obj.SensorObjects))
                for i = 1:numel(obj.SensorObjects)
                    obj.SensorObjects{i}.SampleRate = obj.SampleRate;
                end
            end
        end
        
        function num = getNumOutputsImpl(obj)
            % This function is required for supporting code generation,
            % where it is mandatory to define the number of outputs of a
            % system object during object creation
            if coder.target('MATLAB')
                num = 2;
                if(isequal(lower(string(obj.OutputFormat)),'timetable'))
                    % It returns timetable and overrun
                else
                    % 'OutputFormat' --> 'matrix'
                    % It returns data from individual sensorUnit objects
                    % and appends timestamp and overrun
                    for i = 1:obj.NumSensorUnits
                        num = num + numel(obj.SensorObjects{i}.DoF);
                    end
                end
            else
                % For code generation and mex function creation, it returns
                % timestamp but no overrun.
                num = 1;
                for i = 1:obj.NumSensorUnits
                    num = num + numel(obj.SensorObjects{i}.DoF);
                end
            end
        end
        
        function setSPFImpl(obj)
            try
                if(~isempty(obj.SensorObjects))
                    for i = 1:numel(obj.SensorObjects)
                        obj.SensorObjects{i}.SamplesPerRead = obj.SamplesPerRead;
                    end
                end
            catch ME
                throwAsCaller(ME);
            end
        end
        function setReadModeImpl(obj)
            if(~isempty(obj.SensorObjects))
                for i = 1:numel(obj.SensorObjects)
                    obj.SensorObjects{i}.ReadMode = obj.ReadMode;
                end
            end
        end
        function s = infoImpl(obj)
            count = 1;
            for i = 1:numel(obj.SensorObjects)
                fieldNames = fields(obj.SensorObjects{i}.info());
                for j = count:numel(fieldNames)
                    s.(fieldNames{j}) = obj.SensorObjects{i}.info().(fieldNames{j});
                end
            end
        end
        function setOutputFormatImpl(obj)
            for i = 1:numel(obj.SensorObjects)
                obj.SensorObjects{i}.OutputFormat = string(obj.OutputFormat);
            end
        end
        function setTimeFormatImpl(obj)
            for i = 1:numel(obj.SensorObjects)
                obj.SensorObjects{i}.TimeFormat = string(obj.TimeFormat);
            end
        end
        function createTimeTableImpl(obj)
            obj.timeTableOutput = timetable;
        end
    end
    
    methods(Access = public, Hidden)
        function showProperties(obj)
            % Display sensor specific properties
            showSensorProperties(obj);
            obj.SensorObjects{1}.Device.Parent.showI2CProperties(obj.SensorObjects{1}.Device.Device.Interface, obj.I2CAddress, obj.Bus, obj.SensorObjects{1}.Device.Device.SCLPin, obj.SensorObjects{1}.Device.Device.SDAPin, obj.SensorObjects{1}.Device.Device.BitRate, false);
            if obj.MLStreamingSupported
                fprintf('            SampleRate: %d (samples/s)\n',obj.SampleRate);
                fprintf('        SamplesPerRead: %d\t \n',obj.SamplesPerRead);
                fprintf('              ReadMode: "%s"\t \n',obj.ReadMode);
                fprintf('           SamplesRead: %d\t \n',obj.SamplesRead);
                fprintf('      SamplesAvailable: %d\t \n\n',obj.SamplesAvailable);
            end
        end
        
        function showAllProperties(obj)
            % Display sensor specific properties
            showSensorProperties(obj);
            obj.SensorObjects{1}.Device.Parent.showI2CProperties(obj.SensorObjects{1}.Device.Device.Interface, obj.I2CAddress, obj.Bus, obj.SensorObjects{1}.Device.Device.SCLPin, obj.SensorObjects{1}.Device.Device.SDAPin, obj.SensorObjects{1}.Device.Device.BitRate, true);
            if obj.MLStreamingSupported
                fprintf('            SampleRate: %d (samples/s)\n',obj.SampleRate);
                fprintf('        SamplesPerRead: %d\t \n',obj.SamplesPerRead);
                fprintf('              ReadMode: "%s"\t \n',obj.ReadMode);
                fprintf('           SamplesRead: %d\t \n',obj.SamplesRead);
                fprintf('      SamplesAvailable: %d\t \n',obj.SamplesAvailable);
                fprintf('          OutputFormat: "%s"\t \n',obj.OutputFormat);
                fprintf('            TimeFormat: "%s"\t \n\n',obj.TimeFormat);
            end
        end
        
        function recordStreamingRequest(obj)
            setIOProtocolReadMode(obj.Parent.getProtocolObject(), obj.ReadMode);
            for i = 1:numel(obj.SensorObjects)
                recordStreamingRequest(obj.SensorObjects{i});
                obj.UniqueIds = [obj.UniqueIds; obj.SensorObjects{i}.UniqueIds];
            end
        end
    end
end