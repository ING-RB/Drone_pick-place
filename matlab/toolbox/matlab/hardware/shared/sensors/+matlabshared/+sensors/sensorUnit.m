classdef (Hidden) sensorUnit < matlabshared.sensors.sensorBase
    %Parent class for sensor with single dye (single I2CAddress)

    %   Copyright 2018-2023 The MathWorks, Inc.

    properties(SetAccess = protected, GetAccess = public, Hidden)
        DataNames = [];
    end

    properties(Hidden)
        Device;
        % Flag to  differentiate between readRegister calls during streaming
        % configuration and actual streaming operations.
        OnDemandFlag = 1;
    end

    properties(Access = protected)
        startTime;
        LastReadTime = 0;
        BusI2CDriver;
    end

    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface})
        showSensorPropertiesPosition='top';
    end

   properties(Abstract, Access = protected, Constant)
        SupportedInterfaces;
    end

    properties(Access = protected, Hidden)
        % Number of samples in one frame sent by the target can be
        % different from the SamplesPerRead given by the user.
        TargetSamplesPerFrame = 1;
    end

    properties(Abstract, Nontunable, Hidden)
        DoF;
    end

    properties(Access = private)
        TimeTable;
    end

    methods(Abstract, Access = protected)
        initDeviceImpl(obj) % for initialization which is common to all the sensors on the device (Example: powering up the mag unit in MPU9250)
        initSensorImpl(obj) % for individual sensor inits
        getMeasurementDataNames(obj);
        data = convertSensorDataImpl(obj); % to convert the raw bytes obtained while 'peeking' the values from IO Protocol buffer
        data = readSensorDataImpl(obj);
    end

    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % During code generation, the current class will be replaced by
            % the following class
            name = 'matlabshared.sensors.coder.matlab.sensorUnit';
        end
    end

    methods(Sealed, Access = protected)
        function obj = sensorUnit(varargin)
            obj@matlabshared.sensors.sensorBase(varargin{:});
        end
        
        function init(obj, varargin)
            try
                parserObj = parseSensorArguments(obj,varargin{:});
                parsedResults = parserObj.Results;

                if ismember(obj.SupportedInterfaces,'SPI')
                    if any(ismember(parserObj.UsingDefaults,'SPIChipSelectPin') == 1)
                        error(message('matlab_sensors:general:mandatoryNVPairSPIChipSelect'));
                    end
                    matlabshared.sensors.SPIsensorDevice.validateSPISensorArguments(parsedResults);
                    obj.Device = matlabshared.sensors.SPIsensorDevice(obj,obj.SPIMode,parsedResults);
                elseif ismember(obj.SupportedInterfaces,'I2C')
                    matlabshared.sensors.I2CsensorDevice.validateI2CSensorArguments(parsedResults);
                    obj.Device = matlabshared.sensors.I2CsensorDevice(obj,obj.isSimulink,parserObj,varargin{1},obj.I2CAddressList);
                end

                obj.Device.OnDemandFlag = 1;

                isSensorBoard = matlabshared.sensors.sensorBase.isSensorBoard('get');

                initDeviceImpl(obj);
                initSensorImpl(obj);

                if ~obj.isSimulink
                    obj.DataNames = getMeasurementDataNames(obj);
                end

                setPropertiesWithStreamingInfo(obj,parserObj.Results,isSensorBoard);
                % % If the target supports streaming add listener, for
                % % sensorBoards, listener is added in the sensorBoard class
                if isa(obj.Parent,'matlabshared.sensors.MultiStreamingUtilities') && ~isSensorBoard
                    obj.StreamingObjRegister = event.proplistener(obj.Parent, obj.Parent.findprop( 'RegisterStreamingObjectsEvent'), 'PostSet',  @(~, ~)(obj.Parent.registerStreamingObjects(obj)));
                end
            catch ME
                throwAsCaller(ME)
            end
        end

        function setupImpl(obj)
            try
                checkStreamingValidity(obj);
                if  ~matlabshared.sensors.sensorBase.isSensorBoard('get')
                    if obj.Parent.isStreaming
                        error(message('matlab_sensors:general:streamingInProgress'));
                    else
                        try
                            %  This check is required so that registration and
                            %  calling setup of all sensors happen only once.
                            % Calling the setup of an object locks the object,
                            % for multistreaming, if one object is locked, lock
                            % all other sensor objects as well
                            if  ~obj.Parent.SensorsRegistered
                                obj.Parent.RegisterStreamingObjectsEvent = 1; % Trigger the listeners, which will register all the sensor objects
                                obj.Parent.SensorsRegistered = true; % Once all the sensors are registered, make this flag true
                                startStreamingAllObjects(obj.Parent,obj);
                                dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.Streaming); %Collect DDUX data for sensors (MATLAB). Streaming mode.
                                % Once the streaming starts unregister all the objects registered
                                unRegisterStreamingObjects(obj.Parent);
                            end
                        catch ME
                            unRegisterStreamingObjects(obj.Parent);
                            throwAsCaller(ME);
                        end
                    end
                end
                obj.timerVal = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss Z');
                obj.startTime = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
            catch ME
                throwAsCaller(ME);
            end
        end

        function varargout = stepImpl(obj)
            try
                index = 1;
                timeNow = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss Z');
                if(isequal(lower(string(obj.ReadMode)),'latest'))
                    % if obj.ToleranceTime has elapsed between 2 calls to
                    % 'step' or between a step and a reset, then clear the
                    % transport buffer and count the number of points trashed.
                    % This is done only for 'latest' buffering mode.
                    if((seconds(timeNow - obj.timerVal) > obj.ToleranceTime))
                        if(matlabshared.sensors.sensorBase.isSensorBoard('get')== 0)
                            matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:hostBuffersFlushed');
                        end
                        clearTransportBuffer(obj.Parent.getProtocolObject());
                    end
                end
                [data,~,timestamp] = readSensorDataImpl(obj);
                % timeStamp is a row vector
                time = timestamp';
                numOverrunSamplesSinceLastRead = calculateOverrun(obj,time);
                if(isequal(lower(string(obj.OutputFormat)),'timetable'))
                    for i = 1:numel(obj.DoF)
                        obj.timeTableOutput.(obj.DataNames{i}) = data(:,index:index+obj.DoF(i)-1);
                        index = index + obj.DoF(i);
                    end
                    if(~isequal(time,-1))
                        if(isequal(lower(string(obj.TimeFormat)),'duration'))
                            obj.timeTableOutput.Properties.RowTimes = duration(seconds(time));
                        else
                            % time format is datetime
                            obj.timeTableOutput.Properties.RowTimes = datetime(obj.startTime) + seconds(time);
                        end
                    end
                    varargout{1} = obj.timeTableOutput;
                    if(nargout>1)
                        varargout{2} = numOverrunSamplesSinceLastRead;
                    end
                else
                    % Output format is matrix
                    varargout = cell(1,numel(obj.DoF)+2);
                    index = 1;
                    for i = 1:numel(obj.DoF)
                        varargout{i} = data(:,index:index+obj.DoF(i)-1);
                        index = index + obj.DoF(i);
                    end
                    if(nargout>numel(obj.DoF))
                        if(isequal(lower(string(obj.TimeFormat)),'duration'))
                            varargout{i+1} = duration(seconds(time));
                        else
                            % time format is datetime
                            varargout{i+1} = datetime(obj.startTime) + seconds(time);
                        end
                        varargout{i+2} = numOverrunSamplesSinceLastRead;
                    end
                end
                obj.SamplesRead = obj.SamplesRead + obj.SamplesPerRead;
                obj.timerVal = timeNow;
            catch ME
                throwAsCaller(ME);
            end
        end

        function resetImpl(obj)
            % Clear all data stored in IO Protocol buffers as well as those
            % waiting in the transport layer buffer to be picked up.
            try
                if ~isa(obj.Parent, 'matlabshared.sensors.MultiStreamingUtilities')
                    return;
                end
                flushBuffers(obj.Parent.getProtocolObject());
                obj.SamplesRead = 0;
                obj.SamplesAvailable = 0;
            catch ME
                throwAsCaller(ME);
            end
        end

        function releaseImpl(obj)
            % checking if sensor unit is being created from sensorBoard.This
            % is to avoid duplicate calls to releaseAllStreamingAllObjects.
            try
                if ~isa(obj.Parent, 'matlabshared.sensors.MultiStreamingUtilities')
                    return;
                end
                if(~matlabshared.sensors.sensorBase.isSensorBoard('get'))
                    if  obj.Parent.SensorsRegistered == false
                        % Listener is attached with RegisterObjects
                        % property. Trigger this only once when no
                        % sensors are registerd
                        obj.Parent.RegisterStreamingObjectsEvent = 1; % Trigger the listeners
                        obj.Parent.SensorsRegistered = true;
                        releaseAllStreamingObjects(obj.Parent,obj);
                        unRegisterStreamingObjects(obj.Parent);
                    end
                end
                obj.OnDemandFlag = 1;
                obj.Device.OnDemandFlag = 1;
                obj.UniqueIds = [];
                obj.UniqueIds = [];
                obj.LastReadTime = 0;
            catch ME
                throwAsCaller(ME);
            end
        end

        function numOverrunSamplesSinceLastRead = calculateOverrun(obj,timeStamp)
            % 1/SampleRate difference is expected between consecutive
            % frames
            numOverrunSamplesSinceLastRead = round(abs(timeStamp(1) -  (obj.LastReadTime + 1/obj.SampleRate))*obj.SampleRate);
            obj.LastReadTime = timeStamp(end);
        end
    end

    methods(Sealed, Access = public)
        function varargout = read(obj)
            %   [Data, overrun] = read(imu); Reads data from the sensor.
            %
            %   'Data' is 'timetable' with fields 'Time' and those
            %   corresponding to the physical quantities that the sensor measures
            %   if 'OutputFormat' is 'timetable'. 'overrun' gives the number of
            %   samples dropped since last read. 'overrun' is always zero if
            %   'ReadMode' is 'oldest', since no samples are dropped in this mode.
            %
            %   If 'OutputFormat' is 'matrix', 'read' returns matrix outputs
            %   for all the physical quantities that the sensor measures.
            %   'Time will be a column vector. For example, for an IMU
            %   sensor with accelerometer and gyroscope, the read output in 'matrix'
            %   format is given by,
            %
            %   [accel, angVel, timeStamp, overrun] = read(imu);
            try
                if(isequal(lower(string(obj.OutputFormat)),'timetable'))
                    nargoutchk(0,2) %overrun and timetable
                    [data, overrun] = step(obj);
                    varargout{1} = data;
                    if(nargout>1)
                        varargout{2} = overrun;
                    end
                else
                    nargoutchk(0,numel(obj.DoF)+2)%+2 is for overrun and time
                    varargout = cell(1,numel(obj.DoF)+2);%+2 is for overrun and time
                    [varargout{:}] = step(obj);
                end
            catch ME
                throwAsCaller(ME);
            end
        end
    end

    methods(Access = protected)
      
function num = getNumOutputsImpl(obj)
            % This function is required for supporting code generation,
            % where it is mandatory to define the number of outputs of a
            % system object during object creation
            if coder.target('MATLAB')
                if(isequal(lower(string(obj.OutputFormat)),'timetable'))
                    num = 2;
                else
                    % 'OutputFormat' -> Matrix
                    num = numel(obj.DoF)+2;
                end
            else
                % For code generation and mex function creation, it returns
                % timestamp but no overrun.
                num = numel(obj.DoF) + 1;
            end
        end

        function [data,status,timestamp] = readRegisterData(obj, DataRegister, numBytes, precision)
            if(isequal(obj.OnDemandFlag,1))
                % during streaming configuration, call 'readRegister' which
                % performs a number of validation checks.
                data = readRegister(obj.Device, DataRegister, numBytes, precision);
                status = [];
                timestamp = [];
            else
                % these validation checks can be skipped during streaming
                % for speed enhancement reasons.
                % Arduino Bus IDs are 0 and 1.
                [data,status,timestamp] = registerI2CRead(obj.Device.I2CDriverObj, obj.Parent.getProtocolObject(), obj.BusI2CDriver, obj.Device.I2CAddress, DataRegister, numBytes);
            end
        end

        function setSPFImpl(obj)
            %The number of rows in timetable changes as per SamplesPerRead
            createTimeTableImpl(obj);
        end

        function setReadModeImpl(~)
        end

        function setOutputFormatImpl(~)
        end

        function setTimeFormatImpl(~)
        end

        function createTimeTableImpl(obj)
            obj.timeTableOutput = timetable('Size',[obj.SamplesPerRead,numel(obj.DoF)],'VariableTypes',repmat({'double'},1,numel(obj.DoF)),'RowTimes',duration(seconds(zeros(obj.SamplesPerRead,1))));
            obj.timeTableOutput.Properties.VariableNames = obj.DataNames;
        end
    end

    methods(Access = public, Hidden)
        function showProperties(obj)
            % Display sensor specific properties
            if strcmpi(obj.showSensorPropertiesPosition,'top')
                showSensorProperties(obj);
            end

            obj.Device.showProperties(false);
            
            if obj.MLStreamingSupported
                fprintf('            SampleRate: %d (samples/s)\n',obj.SampleRate);
                fprintf('        SamplesPerRead: %d\t \n',obj.SamplesPerRead);
                fprintf('              ReadMode: "%s"\t \n',obj.ReadMode);
                fprintf('           SamplesRead: %d\t \n',obj.SamplesRead);
                fprintf('      SamplesAvailable: %d\t \n\n',obj.SamplesAvailable);
            end

            if strcmpi(obj.showSensorPropertiesPosition,'bottom')
                showSensorProperties(obj);
            end
        end

        function showAllProperties(obj)
            % Display sensor specific properties
            if strcmpi(obj.showSensorPropertiesPosition,'top')
                showSensorProperties(obj);
            end

            obj.Device.showProperties(true);

            if obj.MLStreamingSupported
                fprintf('            SampleRate: %d (samples/s)\n',obj.SampleRate);
                fprintf('        SamplesPerRead: %d\t \n',obj.SamplesPerRead);
                fprintf('              ReadMode: "%s"\t \n',obj.ReadMode);
                fprintf('           SamplesRead: %d\t \n',obj.SamplesRead);
                fprintf('      SamplesAvailable: %d\t \n',obj.SamplesAvailable);
                fprintf('          OutputFormat: "%s"\t \n',obj.OutputFormat);
                fprintf('            TimeFormat: "%s"\t \n\n',obj.TimeFormat);
            end
            if strcmpi(obj.showSensorPropertiesPosition,'bottom')
                showSensorProperties(obj);
            end
        end

        function varargout = readLatestFrame(obj,varargin)
            %Error out if dataName is not available in the latest data frame
            if nargin>1 && ~any(strcmpi(getMeasurementDataNames(obj),varargin{1}))
                error(message('matlab_sensors:general:unsupportedFunctionCallWhileStreaming',varargin{1}));
            end
            protocolObj = obj.Parent.getProtocolObject();
            flushBuffers(protocolObj);
            [dataOut,status]=peekBuffer(protocolObj,obj.UniqueIds);
            if(any(status))
                error(message('matlab_sensors:general:dataNotReceivedOnDemand'));
            end
            % peek returns raw sensor data bytes. So convert them
            % to proper sensor readings.
            dataOut =  convertSensorDataImpl(obj, dataOut);
            tt = createTimeTableAndDisplay(obj, dataOut);
            varargout{1}=tt;
        end

        function recordStreamingRequest(obj)
            protocolObj = obj.Parent.getProtocolObject();
            setIOProtocolReadMode(protocolObj, string(obj.ReadMode));
            uniqueIdsBeforeConfig = protocolObj.StoredUniqueId;
            % configure for streaming
            try
                readSensorDataImpl(obj);
            catch ME
                stopConfigureStreaming(protocolObj);
                obj.OnDemandFlag = 0;
                obj.Device.OnDemandFlag = 0;
                throwAsCaller(ME);
            end
            obj.OnDemandFlag = 0;
            obj.Device.OnDemandFlag = 0;
            setRate(protocolObj,1/obj.SampleRate);
            % Set the SPF value in IO Protocol.
            setSPFiOProtocol(protocolObj, obj.TargetSamplesPerFrame);
            uniqueIdsAfterConfig = protocolObj.StoredUniqueId;
            % Find new uniqueIDs added
            obj.UniqueIds = setdiff(uniqueIdsAfterConfig, uniqueIdsBeforeConfig);
            hostSPF = obj.SamplesPerRead * ones(1,numel(obj.UniqueIds));
            setHostSamplesPerFrame(protocolObj, hostSPF);
        end
    end

    methods(Access = private)
        function tt = createTimeTableAndDisplay(obj, data)
            tt = timetable('Size',[1,numel(obj.DoF)],'VariableTypes',repmat({'double'},1,numel(obj.DoF)),'RowTimes',datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS'));
            tt.Properties.VariableNames = obj.DataNames;
            index = 1;
            for i = 1:numel(obj.DoF)
                tt.(obj.DataNames{i}) = data(end,index:index+obj.DoF(i)-1);
                index = index + obj.DoF(i);
            end
        end
    end
end