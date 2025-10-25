classdef LSM6DSRAnd6DSOBlockBase < matlabshared.sensors.simulink.internal.LSM6BlockBase
 % Base class for LSM6DSO and LSM6DSR. Common features in masks for both the sensors are added here
 
 %   Copyright 2020-2022 The MathWorks, Inc.
    %#codegen
    properties(Nontunable)
        AccelerometerRange = '+/- 2g';
        AccelerometerODR = '12.5 Hz';
        AccelSelectCompositeFilter = 'No filter';
        AccelLPF2BW = 'ODR/4';
        AccelHPFBW = 'ODR/4';
        GyroscopeODR = '12.5 Hz';
        GyroHPFBW = '0.016 Hz';
        GyroLPFBWMode = '0';
    
       EnableGyroHPF (1, 1) logical = false;
       EnableGyroLPF (1, 1) logical = false;
    end
        
    properties(Hidden, Constant)
        AccelerometerRangeSet = matlab.system.StringSet({'+/- 2g', '+/- 4g', '+/- 8g', '+/- 16g'})
        GyroscopeODRSet = matlab.system.StringSet({'12.5 Hz', '26 Hz', '52 Hz', '104 Hz', '208 Hz', '416 Hz', '833 Hz', '1666 Hz','3332 Hz', '6664 Hz'});
        AccelerometerODRSet = matlab.system.StringSet({'12.5 Hz', '26 Hz', '52 Hz', '104 Hz', '208 Hz', '416 Hz', '833 Hz', '1666 Hz', '3332 Hz', '6664 Hz'})
        AccelSelectCompositeFilterSet = matlab.system.StringSet({'No filter', 'High pass filter', 'Low pass filter'});
        AccelLPF2BWSet = matlab.system.StringSet({'ODR/4', 'ODR/10', 'ODR/20', 'ODR/45','ODR/100', 'ODR/200', 'ODR/400', 'ODR/800'})
        AccelHPFBWSet = matlab.system.StringSet({'ODR/4', 'ODR/10', 'ODR/20', 'ODR/45','ODR/100', 'ODR/200', 'ODR/400', 'ODR/800'})
        GyroHPFBWSet = matlab.system.StringSet({'0.016 Hz', '0.065 Hz', '0.260 Hz', '1.04 Hz'});
        GyroLPFBWModeSet = matlab.system.StringSet({'0', '1', '2', '3','4','5','6','7'});
    end
    
    methods(Access = protected)        
        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "AccelerometerRange"
                    flag = ~obj.IsActiveAcceleration;
                case "AccelerometerODR"
                    flag = ~obj.IsActiveAcceleration;
                case "AccelSelectCompositeFilter"
                    flag = ~obj.IsActiveAcceleration;
                case "AccelLPF2BW"
                    flag = ~(obj.IsActiveAcceleration && strcmpi(obj.AccelSelectCompositeFilter, "Low pass filter"));
                case "AccelHPFBW"
                    flag = ~(obj.IsActiveAcceleration && strcmpi(obj.AccelSelectCompositeFilter, "High pass filter"));
                case "GyroscopeRange"
                    flag = ~obj.IsActiveAngularRate;
                case "GyroscopeODR"
                    flag = ~obj.IsActiveAngularRate;
                case "EnableGyroHPF"
                    flag = ~obj.IsActiveAngularRate;
                case "GyroHPFBW"
                    flag = ~(obj.IsActiveAngularRate&& obj.EnableGyroHPF);
                case "EnableGyroLPF"
                    flag = ~obj.IsActiveAngularRate;
                case "GyroLPFBWMode"
                    flag = ~(obj.IsActiveAngularRate && obj.EnableGyroLPF);
            end
        end
    end
    
    methods(Access = protected, Static)  
        function groups = getPropertyGroupsImpl
            main = matlabshared.sensors.simulink.internal.LSM6BlockBase.getPropertyGroupsImpl();
 
            % Accelerometer settings
            accelRange = matlab.system.display.internal.Property('AccelerometerRange','Description', 'Full scale range');
            accelODR = matlab.system.display.internal.Property('AccelerometerODR','Description', 'Output data rate (ODR)');
            accelSelectCompositeFilter = matlab.system.display.internal.Property('AccelSelectCompositeFilter', 'Description', 'Select composite filter');
            accelLPF2BW = matlab.system.display.internal.Property('AccelLPF2BW', 'Description', 'Low pass filter bandwidth');
            accelHPFBW = matlab.system.display.internal.Property('AccelHPFBW','Description', 'High pass filter bandwidth');
            accelSection = matlab.system.display.Section(...
                'Title', 'Accelerometer', ...
                'PropertyList', {accelRange, accelODR, accelSelectCompositeFilter, accelLPF2BW, accelHPFBW});%,'SectionType', matlab.system.display.SectionType.collapsiblepanel);
            
            % Gyroscope settings
            gyroRange = matlab.system.display.internal.Property('GyroscopeRange', 'Description', 'Full scale range');
            gyroODR = matlab.system.display.internal.Property('GyroscopeODR', 'Description', 'Output data rate (ODR)');
            gyroEnableGyroHPF = matlab.system.display.internal.Property('EnableGyroHPF','Description', 'Enable high pass filter');
            gyroHPFBW = matlab.system.display.internal.Property('GyroHPFBW', 'Description', 'High pass filter bandwidth');
            gyroEnableGyroLPF  = matlab.system.display.internal.Property('EnableGyroLPF','Description', 'Enable low pass filter');
            gyroLPFBWMode = matlab.system.display.internal.Property('GyroLPFBWMode', 'Description', 'Low pass filter bandwidth mode');
            gyroSection = matlab.system.display.Section(...
                'Title', 'Gyroscope', ...
                'PropertyList', {gyroRange, gyroODR, gyroEnableGyroHPF, gyroHPFBW, gyroEnableGyroLPF, gyroLPFBWMode});
                 advanced = matlab.system.display.SectionGroup('Title','Advanced', ...
                 'Sections',[accelSection,gyroSection]);
             groups = [main,advanced];
        end
    end
end