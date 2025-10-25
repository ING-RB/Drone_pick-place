classdef bno055 < sensors.internal.BNO055Base
    % codegen redirect class for bno055
    
    %   Copyright 2020 The MathWorks, Inc
    
    %#codegen
    properties(GetAccess = public,SetAccess = immutable)
        OperatingMode = 'ndof';
    end
    
    properties(Nontunable, Hidden)
        DoF;
        OperatingModeEnum = matlabshared.sensors.internal.BNO055OperatingMode.ndof;
    end
    
    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x28,0x29];
    end

     properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    methods(Access = public)
        function obj = bno055(varargin)
            % At least one parameter must be passed
            narginchk(1,inf);
            parms = struct('I2CAddress', uint32(0), 'Bus', uint32(0),...
                'SampleRate', uint32(0), 'SamplesPerRead', uint32(0),...
                'ReadMode', uint32(0),...
                'OutputFormat', uint32(0), 'TimeFormat', uint32(0),'OperatingMode',uint32(0));
            poptions = struct('CaseSensitivity',false, 'PartialMatching','unique', ...
                'StructExpand',false);
            pstruct = coder.internal.parseParameterInputs(parms,poptions,varargin{2:end});
            coder.internal.errorIf(pstruct.ReadMode ~= 0, 'matlab_sensors:general:propertyValueFixedCodegen','ReadMode', 'latest');
            coder.internal.errorIf(pstruct.OutputFormat ~= 0, 'matlab_sensors:general:propertyValueFixedCodegen','OutputFormat', 'matrix');
            coder.internal.errorIf(pstruct.TimeFormat ~= 0, 'matlab_sensors:general:propertyValueFixedCodegen','TimeFormat', 'duration');
            coder.internal.errorIf(pstruct.SamplesPerRead ~= 0, 'matlab_sensors:general:propertyValueFixedCodegen','SamplesPerRead', '1');
            mode = coder.internal.getParameterValue(pstruct.OperatingMode, 'ndof', varargin{2:end});
            coder.extrinsic('validatestring');
            validatedMode = coder.const(validatestring(mode,obj.SupportedModes));
            obj.OperatingMode = coder.const(validatedMode);
            obj.OperatingModeEnum = coder.const(obj.getEnumValue(validatedMode));
            bus = coder.internal.getParameterValue(pstruct.Bus, [], varargin{2:end});
            I2CAddressArray = coder.const(coder.internal.getParameterValue(pstruct.I2CAddress, obj.I2CAddressList(1), varargin{2:end}));
            sampleRate = coder.internal.getParameterValue(pstruct.SampleRate, 100, varargin{2:end});
            if nargin>=1
                if isempty(bus)
                    params = {varargin{1}, 'I2CAddress', I2CAddressArray,'SampleRate',sampleRate};
                else
                    params = {varargin{1}, 'I2CAddress', I2CAddressArray,'SampleRate',sampleRate,'Bus',bus};
                end
            else
                params = {};
            end
            obj.init(params{:});
        end
        
        function [status,varargout] = readCalibrationStatus(obj)
            coder.internal.errorIf(~coder.internal.isAmbiguousTypes()&& obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.amg,'matlab_sensors:general:unsupportedFunctionBNO055','readCalibrationStatus','amg','ndof');
            nargoutchk(0,2);
            status = struct('System',0,'Accelerometer',0,'Gyroscope',0,'Magnetometer',0);
            if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof
                valRead = readCalibrationStatusInternal(obj);
                status = struct('System', valRead(1),'Accelerometer', valRead(2),'Gyroscope', valRead(3),'Magnetometer',valRead(4));
            end
            if nargout == 2
                % Avoid unecceserry calls to hardware. Only if 2 arguments are requested,return timestamp
                if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof
                    varargout{1} = getCurrentTime(obj.Parent);
                else
                    varargout{1} = 0;
                end
            end
        end
        
        function [data,timestamp] = readOrientation(obj)
            coder.internal.errorIf(~coder.internal.isAmbiguousTypes()&& obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.amg,'matlab_sensors:general:unsupportedFunctionBNO055','readOrientation','amg','ndof');
            data = [0,0,0];
            timestamp = 0;
            if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof
                valRead = readCalibrationStatusInternal(obj);
                if all(valRead)
                    [data,timestamp] =  readOrientation@matlabshared.sensors.Orientation(obj);
                end
            end
        end
    end
    
    methods(Access = protected)
        function s = infoImpl(~)
            % Info is not supported for code generation.
            s = [];
            coder.internal.errorIf(true, 'matlab_sensors:general:unsupportedFunctionSensorCodegen', 'info');
        end
        
        function sampleRate = setSampleRateHook(obj,value)
            sampleRate = obj.NdofSampleRate; % Default SampleRate
            if coder.const(obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof && value(1)~=obj.NdofSampleRate)
                 coder.internal.compileWarning('matlab_sensors:general:unsupportedSampleRate');
            else
            if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.amg
                sampleRate = value;
            end
            end
        end
    end
    
    methods(Access = private)
        function enumMode = getEnumValue(obj,mode)
            switch mode
                case 'ndof'
                    % enum value for ndof
                    val = matlabshared.sensors.internal.BNO055OperatingMode.ndof;
                    obj.DoF = coder.const([3;3;3;3]);
                case 'amg'
                    % enum value for amg
                    val = matlabshared.sensors.internal.BNO055OperatingMode.amg;
                    obj.DoF = coder.const([3;3;3]);
                otherwise
                    val = matlabshared.sensors.internal.BNO055OperatingMode.ndof;
                    obj.DoF = coder.const([3;3;3;3]);
            end
            enumMode = matlabshared.sensors.internal.BNO055OperatingMode(val);
        end
    end
end