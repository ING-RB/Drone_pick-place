classdef (Hidden) sensorBase < matlabshared.sensors.coder.matlab.sensorInterface
  %Parent class for sensorUnit and sensorBoard (coder class)
  
    %   Copyright 2020-2021 The MathWorks, Inc.
    
    %#codegen
    
    properties(Nontunable)
        %   SampleRate Sensor sample rate
        %   Specify the sampling rate of the input sensor data in Hertz as
        %   a finite numeric scalar.
        SampleRate double;
    end
    
    properties(SetAccess = protected, GetAccess = public,Hidden)
        Parent; % This is the hardware object
    end

    properties(Abstract, Access = protected, Constant)
        SupportedInterfaces;
    end
    
    properties(Abstract, Access = protected)
        LastReadTime;
        StartTime;
    end
    
    % properties(SetAccess = protected,Nontunable)
    %     Bus;
    %     I2CAddress;
    %     Interface = 'I2C';
    % end
    
    properties(Access = protected,Nontunable)
        isSimulink = 0;
        DefaultSampleRate = 100;
    end
    
    methods(Abstract, Access = protected)
        setODRImpl(obj);
    end
    
    methods
        function obj = sensorBase(varargin)
             if nargin>=1
                parent = varargin{1};
                if isa(parent,'matlabshared.sensors.simulink.internal.TargetI2CSensorUtilities') || isa(parent,'matlabshared.sensors.simulink.internal.TargetSPISensorUtilities') || isa(parent,'matlabshared.sensors.simulink.internal.TargetI2CSensorUtilitiesDeviceBased')
                    obj.isSimulink = 1;
                end
            end
        end
        
        function set.SampleRate(obj, value)
            if(~obj.isSimulink)
                value = setSampleRateHook(obj,value);
                validateattributes(value,{'numeric'}, ...
                    {'real','positive','scalar'},'','SampleRate');
                obj.SampleRate = value;
                setODRImpl(obj);
            end
        end
        
        function set.Parent(obj, parent)
            % Check whether the passed device is a HWSDK device or if it is
            % inherited from the abstract hardware class provided by sensor
            % codegen infrastructure
            % Add SPI also when supported
            coder.internal.assert(isa(parent, 'matlabshared.sensors.coder.matlab.SensorCodegenUtilities') ||...
                 isa(parent,'matlabshared.sensors.simulink.internal.TargetI2CSensorUtilitiesDeviceBased')||...
                (isa(parent, 'matlabshared.sensors.coder.matlab.I2CSensorUtilities') ||...
                isa(parent, 'matlabshared.sensors.coder.matlab.SPISensorUtilities') ||...
                isa(parent, 'matlabshared.coder.i2c.controller'))...
                ,'matlab_sensors:general:invalidHwObjSensor');
            obj.Parent = parent;
        end
    end
    methods(Access = protected)
        function sampleRate = setSampleRateHook(~,value)
            sampleRate = value;
        end
    end
end
