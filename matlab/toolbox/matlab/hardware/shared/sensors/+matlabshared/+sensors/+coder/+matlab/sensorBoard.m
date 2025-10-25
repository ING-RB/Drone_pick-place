classdef (Hidden) sensorBoard < matlabshared.sensors.coder.matlab.sensorBase
   %Parent class for sensor with multiple dies( multiple I2CAddress).Coder
   %class
    
   %   Copyright 2020-2021 The MathWorks, Inc.
    
    %#codegen
    
    properties(Abstract, Access = public, Hidden)
        % Holds the sensorUnit objects in a cell array
        SensorObjects;
    end
    
    properties(Abstract, Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        % Number of sensorUnit objects stored in SensorObjects property
        NumSensorUnits
    end
    
    properties(Access = protected)
        LastReadTime = 0;
        StartTime;
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
    
    methods
        function obj = sensorBoard(varargin)
            obj@matlabshared.sensors.coder.matlab.sensorBase(varargin{:});
        end
    end
    
    methods(Access = protected)
        function init(obj, varargin)
            % If the sensor class is called with no arguments, error must
            % be thrown
            narginchk(2,inf);
            obj.Parent = varargin{1};
            % Including all possible parameters both supported and
            % unsupported. For unsupported parameters error will be thrown
            % from sensorUnit
            parms = struct('I2CAddress', uint32(0), 'Bus', uint32(0),...
                'SampleRate', uint32(0), 'SamplesPerRead', uint32(0),...
                'ReadMode', uint32(0),...
                'OutputFormat', uint32(0), 'TimeFormat', uint32(0));
            poptions = struct('CaseSensitivity',false, 'PartialMatching','unique', ...
                'StructExpand',false);
            pstruct = coder.internal.parseParameterInputs(parms,poptions,varargin{2:end});
            %  'ReadMode', 'OutputFormat', 'SamplesPerRead' and
            % 'TimeFormat' are not supported for code generation
            coder.internal.errorIf(pstruct.ReadMode ~= 0, 'matlab_sensors:general:propertyValueFixedCodegen','ReadMode', 'latest');
            coder.internal.errorIf(pstruct.OutputFormat ~= 0, 'matlab_sensors:general:propertyValueFixedCodegen','OutputFormat', 'matrix');
            coder.internal.errorIf(pstruct.TimeFormat ~= 0, 'matlab_sensors:general:propertyValueFixedCodegen','TimeFormat', 'duration');
            coder.internal.errorIf(pstruct.SamplesPerRead ~= 0, 'matlab_sensors:general:propertyValueFixedCodegen','SamplesPerRead', '1');
            if pstruct.I2CAddress ~= 0
                I2CAddr = coder.internal.getParameterValue(pstruct.I2CAddress, {}, varargin{2:end});
                coder.internal.assert(numel(I2CAddr) == obj.NumSensorUnits,...
                    'matlab_sensors:general:incorrectNumI2CAddresses', obj.NumSensorUnits);
            end
            % Create sensorUnit objects and store them in SensorObjects
            % property
            createSensorUnitsImpl(obj,varargin{:});
            obj.Bus = obj.SensorObjects{1}.Bus;
            numSensorUnits = numel(obj.SensorObjects);
            address = zeros(1,numSensorUnits);
            for i = 1:numSensorUnits
                address(i) = obj.SensorObjects{i}.Device.I2CAddress;
            end
            obj.I2CAddress = double(address);
            obj.SampleRate = coder.internal.getParameterValue(pstruct.SampleRate, obj.DefaultSampleRate, varargin{2:end});
        end
        
        function varargout = stepImpl(obj)
            % For each sensorUnit object hold by SensorObjects property,
            % find the number of outputs. Return all of them and add
            % timestamp at the end if required.
            totalOutputs = 0;
            for i = 1:obj.NumSensorUnits
                totalOutputs = totalOutputs + numel(obj.SensorObjects{i}.DoF);
            end
            % Check the number of output arguments. last argument is
            % timestamp
            nargoutchk(0, totalOutputs + 1);
            currentIndex = 0;
            for k = 1:obj.NumSensorUnits
                localOutputs = cell(1, numel(obj.SensorObjects{k}.DoF));
                [localOutputs{:}] = obj.SensorObjects{k}.step();
                for j = 1:numel(obj.SensorObjects{k}.DoF)
                    varargout{currentIndex + j} = localOutputs{j};
                end
                currentIndex = currentIndex + numel(obj.SensorObjects{k}.DoF);
            end
            obj.SamplesRead = obj.SamplesRead + obj.SamplesPerRead;
            % To avoid unneccessary function call on hardware, get
            % timestamp from target only if it is requested.
            if nargout == totalOutputs + 1
                timestamp = getCurrentTime(obj.Parent);
                varargout{totalOutputs + 1} = timestamp;
            end
        end
        
        function resetImpl(obj)
            obj.SamplesRead = 0;
        end
        
        function releaseImpl(obj)
            % release of sensor units is called to unlock them.
            for i = 1:numel(obj.SensorObjects)
                release(obj.SensorObjects{i});
            end
            obj.SamplesRead = 0;
        end
        
        function s = infoImpl(~)
            % Info is not supported for code generation
            s = [];
            coder.internal.errorIf(true, 'matlab_sensors:general:unsupportedFunctionSensorCodegen', 'info');
        end
    end
    
    methods(Access = public)
        function varargout = read(obj)
            [varargout{:}] = step(obj);
        end
        function flush(obj)
            % flush(imu);
            % Equivalent to the System object 'reset' method.
            % flush(imu) resets 'SamplesRead'.
            reset(obj);
        end
        
        function stop(obj)
            % stop(imu);
            % Equivalent to the System object 'release' method.
            % stop(imu), unlocks the system objects
            release(obj);
        end
    end
    methods(Access = protected)
        function setODRImpl(obj)
            if(~isempty(obj.SensorObjects))
                for i = 1:numel(obj.SensorObjects)
                    obj.SensorObjects{i}.SampleRate = obj.SampleRate;
                end
            end
        end
        
        function num = getNumOutputsImpl(obj)
            % last output is timestamp
            num = 1;
            for i = 1:obj.NumSensorUnits
                num = num + numel(obj.SensorObjects{i}.DoF);
            end
        end
    end
end