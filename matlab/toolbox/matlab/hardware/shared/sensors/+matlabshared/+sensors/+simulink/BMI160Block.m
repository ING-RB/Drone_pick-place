classdef BMI160Block < matlabshared.sensors.simulink.internal.SensorBlockBase...
        & matlabshared.sensors.simulink.internal.I2CSensorBase
    %Simulink Block class for BMI160 .
    %<a href="https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmi160-ds000.pdf">Device Datasheet</a>
    %Copyright 2021-2023 The MathWorks, Inc.

    %#codegen
    properties(Access = protected, Constant)
        SensorName = "BMI160";
    end

    properties(Nontunable)
        I2CModule = '';
        I2CAddress = '0x69';
        MagnetometerI2CAddress(1,:) char {matlab.system.mustBeMember(MagnetometerI2CAddress,{'0x10', '0x11','0x12','0x13'})} = '0x13';
        AccelerationRange(1,:) char {matlab.system.mustBeMember(AccelerationRange,{'+/- 2g', '+/- 4g', '+/- 8g','+/- 16g'})} = '+/- 2g';
        AccelerometerODR(1,:) char {matlab.system.mustBeMember(AccelerometerODR,{'12.5 Hz','25 Hz','50 Hz','100 Hz','200 Hz','400 Hz','800 Hz','1600 Hz'})} = '12.5 Hz';
        GyroscopeRange(1,:) char {matlab.system.mustBeMember(GyroscopeRange,{'125 dps','250 dps','500 dps','1000 dps','2000 dps'})} = '125 dps';
        GyroscopeODR(1,:) char {matlab.system.mustBeMember(GyroscopeODR,{'25 Hz','50 Hz','100 Hz','200 Hz','400 Hz','800 Hz','1600 Hz','3200 Hz'})} = '25 Hz';
        MagnetometerODR(1,:) char {matlab.system.mustBeMember(MagnetometerODR,{'0.78125 Hz','1.5625 Hz','3.125 Hz','6.25 Hz','12.5 Hz','25 Hz','50 Hz','100 Hz','200 Hz','400 Hz','800 Hz'})} = '25 Hz';
        AccelerometerFilterMode(1,:) char {matlab.system.mustBeMember(AccelerometerFilterMode,{'Normal','OSR2','OSR4'})} = 'Normal';
        GyroscopeFilterMode(1,:) char {matlab.system.mustBeMember(GyroscopeFilterMode,{'Normal','OSR2','OSR4'})} = 'Normal';
        InterruptPinAnyMotion(1,:) char {matlab.system.mustBeMember(InterruptPinAnyMotion,{'INT1','INT2'})} = 'INT1';
        InterruptPinDoubleTap(1,:) char {matlab.system.mustBeMember(InterruptPinDoubleTap,{'INT1','INT2'})} = 'INT1';
        InterruptPinHighG(1,:) char {matlab.system.mustBeMember(InterruptPinHighG,{'INT1','INT2'})} = 'INT1';
        InterruptPinSlowMotion(1,:) char {matlab.system.mustBeMember(InterruptPinSlowMotion,{'INT1','INT2'})} = 'INT1';
        InterruptPinDataReady(1,:) char {matlab.system.mustBeMember(InterruptPinDataReady,{'INT1','INT2'})} = 'INT1';
        InterruptPinFifo(1,:) char {matlab.system.mustBeMember(InterruptPinFifo,{'INT1','INT2'})} = 'INT1';
        InterruptPinFlat(1,:) char {matlab.system.mustBeMember(InterruptPinFlat,{'INT1','INT2'})} = 'INT1';
        InterruptPinSingleTap(1,:) char {matlab.system.mustBeMember(InterruptPinSingleTap,{'INT1','INT2'})} = 'INT1';
        DataType(1,:) char {matlab.system.mustBeMember(DataType,{'single','double'})} = 'single';
        AnyMotionTimeThreshold(1,:) char {matlab.system.mustBeMember(AnyMotionTimeThreshold,{'1','2','3','4'})} = '1';
        AnyMotionAmplitudeThreshold2g = 0.1;
        AnyMotionAmplitudeThreshold4g = 0.1;
        AnyMotionAmplitudeThreshold8g = 0.1;
        AnyMotionAmplitudeThreshold16g = 0.1;
        SingleTapQuietTimeThreshold(1,:) char {matlab.system.mustBeMember(SingleTapQuietTimeThreshold,{'30 ms','20 ms'})} = '30 ms';
        SingleTapShockTimeThreshold(1,:) char {matlab.system.mustBeMember(SingleTapShockTimeThreshold,{'50 ms','75 ms'})} = '50 ms';
        SingleTapAmplitudeThreshold2g = 0.1;
        SingleTapAmplitudeThreshold4g = 0.1;
        SingleTapAmplitudeThreshold8g = 0.2;
        SingleTapAmplitudeThreshold16g = 0.3;
        DoubleTapDurationTimeThreshold(1,:) char {matlab.system.mustBeMember(DoubleTapDurationTimeThreshold,{'50 ms','100 ms','150 ms','200 ms','250 ms','375 ms','500 ms','700 ms'})} = '50 ms';
        FlatThetaThreshold =5;
        FlatTimeThreshold(1,:) char {matlab.system.mustBeMember(FlatTimeThreshold,{'0 ms','640 ms','1280 ms','2560 ms'})} = '640 ms';
        SlowMotionTimeThreshold(1,:) char {matlab.system.mustBeMember(SlowMotionTimeThreshold,{'1','2','3','4'})} = '1';
        SlowMotionAmplitudeThreshold2g = 0.1;
        SlowMotionAmplitudeThreshold4g = 0.1;
        SlowMotionAmplitudeThreshold8g = 0.1;
        SlowMotionAmplitudeThreshold16g = 0.1;
        HighGTimeThreshold = 2.5;
        HighGAmplitudeThreshold2g = 0.1;
        HighGAmplitudeThreshold4g = 0.1;
        HighGAmplitudeThreshold8g = 0.1;
        HighGAmplitudeThreshold16g = 0.1;
        FifoMode(1,:) char {matlab.system.mustBeMember(FifoMode,{'Full Buffer','Water Mark'})} = 'Full Buffer';
        FifoWaterMarkThreshold = '';
    end

    properties(Hidden, Constant)
        I2CAddressSet = matlab.system.StringSet({'0x69','0x68'});
    end

    properties(Nontunable, Access = protected)
        I2CBus
    end

    properties(Access = protected)
        PeripheralType = 'I2C'
    end

    properties(Nontunable)
        IsActiveGyro (1, 1) logical = true;
        IsActiveAccel (1, 1) logical = true;
        IsActiveMag (1, 1) logical = true;
        IsActiveTemperature (1, 1) logical = false;
        IsAccelStatus (1, 1) logical = false;
        IsGyroStatus (1, 1) logical = false;
        IsMagStatus (1, 1) logical = false;
        IsEnableAccelLowPassFilter (1, 1) logical = false;
        IsEnableGyroLowPassFilter (1, 1) logical = false;
        IsActiveInterrupt (1, 1) logical = false;
        IsAnyMotion (1, 1) logical = false;
        IsSingleTap (1, 1) logical = false;
        IsDoubleTap (1, 1) logical = false;
        IsFlatDetection (1, 1) logical = false;
        IsHighGDetection (1, 1) logical = false;
        IsSlowMotion (1, 1)logical = false;
        IsDataReady (1, 1) logical = false;
        IsFifo (1, 1)logical = false;
        EnableSecondaryMag (1, 1) logical = true;
        IsIntSource (1, 1) logical = false;
        IsTapEventSource (1, 1) logical = false;
        IsAnyMotionEventSource (1, 1) logical = false;
        IsHighGEventSource (1, 1) logical = false;
    end

    methods(Access = protected)
        function out = getActiveOutputsImpl(obj)
            out = cell(1,obj.IsActiveGyro + obj.IsActiveAccel+(obj.IsActiveMag && obj.EnableSecondaryMag)+obj.IsActiveTemperature+(obj.IsAccelStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection ||obj.IsDataReady))+(obj.IsGyroStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion ||obj.IsFlatDetection || obj.IsDataReady))+(obj.IsMagStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection || obj.IsDataReady) && obj.EnableSecondaryMag)+(obj.IsIntSource && (obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection || obj.IsDataReady))+(obj.IsTapEventSource && (obj.IsSingleTap|| obj.IsDoubleTap) && obj.IsIntSource && obj.IsActiveAccel)+(obj.IsAnyMotionEventSource && obj.IsAnyMotion && obj.IsIntSource && obj.IsActiveAccel) +(obj.IsHighGEventSource && obj.IsHighGDetection && obj.IsIntSource && obj.IsActiveAccel));
            count = 1;
            if obj.IsActiveAccel
                objAccel=matlabshared.sensors.simulink.internal.Acceleration;
                if strcmp(obj.DataType,'single')
                    objAccel.OutputDataType = 'single';
                end
                out{count} = objAccel;
                count = count + 1;
            end

            if obj.IsActiveGyro
                objGyro = matlabshared.sensors.simulink.internal.AngularVelocity;
                if strcmp(obj.DataType,'single')
                    objGyro.OutputDataType = 'single';
                end
                out{count} = objGyro;
                count = count + 1;
            end

            if obj.IsActiveMag && obj.EnableSecondaryMag
                objMag = matlabshared.sensors.simulink.internal.MagneticField;
                if strcmp(obj.DataType,'single')
                    objMag.OutputDataType = 'single';
                end
                out{count} = objMag;
                count = count + 1;
            end

            if obj.IsActiveTemperature
                objTemp = matlabshared.sensors.simulink.internal.Temperature;
                if strcmp(obj.DataType,'single')
                    objTemp.OutputDataType = 'single';
                end
                out{count} = objTemp;
                count = count + 1;
            end

            if obj.IsAccelStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection ||obj.IsDataReady)
                out{count} =matlabshared.sensors.simulink.internal.AccelerationStatus;
                count = count + 1;
            end

            if obj.IsGyroStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection || obj.IsDataReady )
                out{count} =matlabshared.sensors.simulink.internal.AngularRateStatus;
                count = count + 1;
            end

            if obj.IsMagStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection || obj.IsDataReady) && obj.EnableSecondaryMag
                out{count} =matlabshared.sensors.simulink.internal.MagneticFieldStatus;
            end

            if obj.IsIntSource && (obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection || obj.IsDataReady)
                out{count} =matlabshared.sensors.simulink.internal.InterruptSource;
                count = count + 1;
            end

            if obj.IsTapEventSource && (obj.IsSingleTap || obj.IsDoubleTap) && obj.IsIntSource && obj.IsActiveAccel
                out{count} =matlabshared.sensors.simulink.internal.TapEventSource;
                count = count + 1;
            end

            if obj.IsHighGEventSource && (obj.IsHighGDetection) && obj.IsIntSource && obj.IsActiveAccel
                out{count} =matlabshared.sensors.simulink.internal.HighGEventSource;
                count = count + 1;
            end

            if obj.IsAnyMotionEventSource && (obj.IsAnyMotion) && obj.IsIntSource && obj.IsActiveAccel
                out{count} =matlabshared.sensors.simulink.internal.AnyMotionEventSource;
            end
        end

        function createSensorObjectImpl(obj)
            switch obj.AccelerationRange
                case '+/- 2g'
                    obj.SensorObject = bmi160(obj.HwUtilityObject, ...
                        'Bus',obj.I2CBus,'I2CAddress',obj.I2CAddress,'MagnetometerI2CAddress',obj.MagnetometerI2CAddress,'IsActiveMag',obj.IsActiveMag,'IsActiveGyro',obj.IsActiveGyro,'GyroscopeRange',obj.GyroscopeRange,'GyroscopeODR',obj.GyroscopeODR,'IsActiveAccel',obj.IsActiveAccel,'AccelerometerRange',obj.AccelerationRange,'AccelerometerODR',obj.AccelerometerODR,'AccelerometerFilterMode',obj.AccelerometerFilterMode,'GyroscopeFilterMode',obj.GyroscopeFilterMode,'IsAccelStatus',obj.IsAccelStatus,'IsGyroStatus',obj.IsGyroStatus,'IsMagStatus',obj.IsMagStatus,'EnableSecondaryMag',obj.EnableSecondaryMag,'IsAnyMotion',obj.IsAnyMotion,'IsSingleTap',obj.IsSingleTap,'IsDoubleTap',obj.IsDoubleTap,'IsHighGDetection',obj.IsHighGDetection,'IsSlowMotion',obj.IsSlowMotion,'IsFlatDetection',obj.IsFlatDetection,'IsDataReady',obj.IsDataReady,'IsActiveTemperature',obj.IsActiveTemperature,'MagnetometerODR',obj.MagnetometerODR,'InterruptPinAnyMotion',obj.InterruptPinAnyMotion,'InterruptPinSingleTap',obj.InterruptPinSingleTap,'InterruptPinDoubleTap',obj.InterruptPinDoubleTap,'InterruptPinHighG',obj.InterruptPinHighG,'InterruptPinSlowMotion',obj.InterruptPinSlowMotion,'InterruptPinFlat',obj.InterruptPinFlat,'InterruptPinDataReady',obj.InterruptPinDataReady,'AnyMotionTimeThreshold',obj.AnyMotionTimeThreshold,'AnyMotionAmplitudeThreshold',obj.AnyMotionAmplitudeThreshold2g,'SingleTapQuietTimeThreshold',obj.SingleTapQuietTimeThreshold,'SingleTapShockTimeThreshold',obj.SingleTapShockTimeThreshold,'SingleTapAmplitudeThreshold',obj.SingleTapAmplitudeThreshold2g,'DoubleTapDurationTimeThreshold',obj.DoubleTapDurationTimeThreshold,'SlowMotionTimeThreshold',obj.SlowMotionTimeThreshold,'SlowMotionAmplitudeThreshold',obj.SlowMotionAmplitudeThreshold2g,'HighGTimeThreshold',obj.HighGTimeThreshold,'HighGAmplitudeThreshold',obj.HighGAmplitudeThreshold2g,'FlatThetaThreshold',obj.FlatThetaThreshold,'FlatTimeThreshold',obj.FlatTimeThreshold,'DataType',obj.DataType);
                case '+/- 4g'
                    obj.SensorObject = bmi160(obj.HwUtilityObject, ...
                        'Bus',obj.I2CBus,'I2CAddress',obj.I2CAddress,'MagnetometerI2CAddress',obj.MagnetometerI2CAddress,'IsActiveMag',obj.IsActiveMag,'IsActiveGyro',obj.IsActiveGyro,'GyroscopeRange',obj.GyroscopeRange,'GyroscopeODR',obj.GyroscopeODR,'IsActiveAccel',obj.IsActiveAccel,'AccelerometerRange',obj.AccelerationRange,'AccelerometerODR',obj.AccelerometerODR,'AccelerometerFilterMode',obj.AccelerometerFilterMode,'GyroscopeFilterMode',obj.GyroscopeFilterMode,'IsAccelStatus',obj.IsAccelStatus,'IsGyroStatus',obj.IsGyroStatus,'IsMagStatus',obj.IsMagStatus,'EnableSecondaryMag',obj.EnableSecondaryMag,'IsAnyMotion',obj.IsAnyMotion,'IsSingleTap',obj.IsSingleTap,'IsDoubleTap',obj.IsDoubleTap,'IsHighGDetection',obj.IsHighGDetection,'IsSlowMotion',obj.IsSlowMotion,'IsFlatDetection',obj.IsFlatDetection,'IsDataReady',obj.IsDataReady,'IsActiveTemperature',obj.IsActiveTemperature,'MagnetometerODR',obj.MagnetometerODR,'InterruptPinAnyMotion',obj.InterruptPinAnyMotion,'InterruptPinSingleTap',obj.InterruptPinSingleTap,'InterruptPinDoubleTap',obj.InterruptPinDoubleTap,'InterruptPinHighG',obj.InterruptPinHighG,'InterruptPinSlowMotion',obj.InterruptPinSlowMotion,'InterruptPinFlat',obj.InterruptPinFlat,'InterruptPinDataReady',obj.InterruptPinDataReady,'AnyMotionTimeThreshold',obj.AnyMotionTimeThreshold,'AnyMotionAmplitudeThreshold',obj.AnyMotionAmplitudeThreshold4g,'SingleTapQuietTimeThreshold',obj.SingleTapQuietTimeThreshold,'SingleTapShockTimeThreshold',obj.SingleTapShockTimeThreshold,'SingleTapAmplitudeThreshold',obj.SingleTapAmplitudeThreshold4g,'DoubleTapDurationTimeThreshold',obj.DoubleTapDurationTimeThreshold,'SlowMotionTimeThreshold',obj.SlowMotionTimeThreshold,'SlowMotionAmplitudeThreshold',obj.SlowMotionAmplitudeThreshold4g,'HighGTimeThreshold',obj.HighGTimeThreshold,'HighGAmplitudeThreshold',obj.HighGAmplitudeThreshold4g,'FlatThetaThreshold',obj.FlatThetaThreshold,'FlatTimeThreshold',obj.FlatTimeThreshold,'DataType',obj.DataType);
                case '+/- 8g'
                    obj.SensorObject = bmi160(obj.HwUtilityObject, ...
                        'Bus',obj.I2CBus,'I2CAddress',obj.I2CAddress,'MagnetometerI2CAddress',obj.MagnetometerI2CAddress,'IsActiveMag',obj.IsActiveMag,'IsActiveGyro',obj.IsActiveGyro,'GyroscopeRange',obj.GyroscopeRange,'GyroscopeODR',obj.GyroscopeODR,'IsActiveAccel',obj.IsActiveAccel,'AccelerometerRange',obj.AccelerationRange,'AccelerometerODR',obj.AccelerometerODR,'AccelerometerFilterMode',obj.AccelerometerFilterMode,'GyroscopeFilterMode',obj.GyroscopeFilterMode,'IsAccelStatus',obj.IsAccelStatus,'IsGyroStatus',obj.IsGyroStatus,'IsMagStatus',obj.IsMagStatus,'EnableSecondaryMag',obj.EnableSecondaryMag,'IsAnyMotion',obj.IsAnyMotion,'IsSingleTap',obj.IsSingleTap,'IsDoubleTap',obj.IsDoubleTap,'IsHighGDetection',obj.IsHighGDetection,'IsSlowMotion',obj.IsSlowMotion,'IsFlatDetection',obj.IsFlatDetection,'IsDataReady',obj.IsDataReady,'IsActiveTemperature',obj.IsActiveTemperature,'MagnetometerODR',obj.MagnetometerODR,'InterruptPinAnyMotion',obj.InterruptPinAnyMotion,'InterruptPinSingleTap',obj.InterruptPinSingleTap,'InterruptPinDoubleTap',obj.InterruptPinDoubleTap,'InterruptPinHighG',obj.InterruptPinHighG,'InterruptPinSlowMotion',obj.InterruptPinSlowMotion,'InterruptPinFlat',obj.InterruptPinFlat,'InterruptPinDataReady',obj.InterruptPinDataReady,'AnyMotionTimeThreshold',obj.AnyMotionTimeThreshold,'AnyMotionAmplitudeThreshold',obj.AnyMotionAmplitudeThreshold8g,'SingleTapQuietTimeThreshold',obj.SingleTapQuietTimeThreshold,'SingleTapShockTimeThreshold',obj.SingleTapShockTimeThreshold,'SingleTapAmplitudeThreshold',obj.SingleTapAmplitudeThreshold8g,'DoubleTapDurationTimeThreshold',obj.DoubleTapDurationTimeThreshold,'SlowMotionTimeThreshold',obj.SlowMotionTimeThreshold,'SlowMotionAmplitudeThreshold',obj.SlowMotionAmplitudeThreshold8g,'HighGTimeThreshold',obj.HighGTimeThreshold,'HighGAmplitudeThreshold',obj.HighGAmplitudeThreshold8g,'FlatThetaThreshold',obj.FlatThetaThreshold,'FlatTimeThreshold',obj.FlatTimeThreshold,'DataType',obj.DataType);
                case '+/- 16g'
                    obj.SensorObject = bmi160(obj.HwUtilityObject, ...
                        'Bus',obj.I2CBus,'I2CAddress',obj.I2CAddress,'MagnetometerI2CAddress',obj.MagnetometerI2CAddress,'IsActiveMag',obj.IsActiveMag,'IsActiveGyro',obj.IsActiveGyro,'GyroscopeRange',obj.GyroscopeRange,'GyroscopeODR',obj.GyroscopeODR,'IsActiveAccel',obj.IsActiveAccel,'AccelerometerRange',obj.AccelerationRange,'AccelerometerODR',obj.AccelerometerODR,'AccelerometerFilterMode',obj.AccelerometerFilterMode,'GyroscopeFilterMode',obj.GyroscopeFilterMode,'IsAccelStatus',obj.IsAccelStatus,'IsGyroStatus',obj.IsGyroStatus,'IsMagStatus',obj.IsMagStatus,'EnableSecondaryMag',obj.EnableSecondaryMag,'IsAnyMotion',obj.IsAnyMotion,'IsSingleTap',obj.IsSingleTap,'IsDoubleTap',obj.IsDoubleTap,'IsHighGDetection',obj.IsHighGDetection,'IsSlowMotion',obj.IsSlowMotion,'IsFlatDetection',obj.IsFlatDetection,'IsDataReady',obj.IsDataReady,'IsActiveTemperature',obj.IsActiveTemperature,'MagnetometerODR',obj.MagnetometerODR,'InterruptPinAnyMotion',obj.InterruptPinAnyMotion,'InterruptPinSingleTap',obj.InterruptPinSingleTap,'InterruptPinDoubleTap',obj.InterruptPinDoubleTap,'InterruptPinHighG',obj.InterruptPinHighG,'InterruptPinSlowMotion',obj.InterruptPinSlowMotion,'InterruptPinFlat',obj.InterruptPinFlat,'InterruptPinDataReady',obj.InterruptPinDataReady,'AnyMotionTimeThreshold',obj.AnyMotionTimeThreshold,'AnyMotionAmplitudeThreshold',obj.AnyMotionAmplitudeThreshold16g,'SingleTapQuietTimeThreshold',obj.SingleTapQuietTimeThreshold,'SingleTapShockTimeThreshold',obj.SingleTapShockTimeThreshold,'SingleTapAmplitudeThreshold',obj.SingleTapAmplitudeThreshold16g,'DoubleTapDurationTimeThreshold',obj.DoubleTapDurationTimeThreshold,'SlowMotionTimeThreshold',obj.SlowMotionTimeThreshold,'SlowMotionAmplitudeThreshold',obj.SlowMotionAmplitudeThreshold16g,'HighGTimeThreshold',obj.HighGTimeThreshold,'HighGAmplitudeThreshold',obj.HighGAmplitudeThreshold16g,'FlatThetaThreshold',obj.FlatThetaThreshold,'FlatTimeThreshold',obj.FlatTimeThreshold,'DataType',obj.DataType);
            end

        end

        function varargout = readSensorDataHook(obj)
            if obj.IsAccelStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection || obj.IsDataReady)
                if obj.IsGyroStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection || obj.IsDataReady)
                    if obj.IsMagStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection || obj.IsDataReady)
                        outAccel = obj.OutputModules{end-2}.readSensor(obj);
                        outGyro = obj.OutputModules{end-1}.readSensor(obj);
                        [outMag,timestamp] = obj.OutputModules{end}.readSensor(obj);
                        % If more than status is required
                        if obj.NumOutputs > 3
                            for i = 1:obj.NumOutputs-3
                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                            end
                        else
                            i = 0;
                        end
                        varargout{i+1} = outAccel;
                        varargout{i+2} = outGyro;
                        varargout{i+3} = outMag;
                        varargout{i+4} = timestamp;
                    else
                        outAccel = obj.OutputModules{end-1}.readSensor(obj);
                        [outGyro,timestamp] = obj.OutputModules{end}.readSensor(obj);
                        % If more than status is required
                        if obj.NumOutputs > 2
                            for i = 1:obj.NumOutputs-2
                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                            end
                        else
                            i = 0;
                        end
                        varargout{i+1} = outAccel;
                        varargout{i+2} = outGyro;
                        varargout{i+3} = timestamp;
                    end
                else
                    if obj.IsMagStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection || obj.IsDataReady)
                        outAccel = obj.OutputModules{end-1}.readSensor(obj);
                        [outMag,timestamp] = obj.OutputModules{end}.readSensor(obj);
                        % If more than status is required
                        if obj.NumOutputs > 2
                            for i = 1:obj.NumOutputs-2
                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                            end
                        else
                            i = 0;
                        end
                        varargout{i+1} = outAccel;
                        varargout{i+2} = outMag;
                        varargout{i+3} = timestamp;
                    else
                        [outAccel,timestamp] = obj.OutputModules{end}.readSensor(obj);
                        % If more than status is required
                        if obj.NumOutputs > 1
                            for i = 1:obj.NumOutputs-1
                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                            end
                        else
                            i = 0;
                        end
                        varargout{i+1} = outAccel;
                        varargout{i+2} = timestamp;
                    end
                end
            else
                if obj.IsGyroStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection || obj.IsDataReady)
                    if obj.IsMagStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection || obj.IsDataReady)
                        outGyro = obj.OutputModules{end-1}.readSensor(obj);
                        [outMag,timestamp] = obj.OutputModules{end}.readSensor(obj);
                        % If more than status is required
                        if obj.NumOutputs > 2
                            for i = 1:obj.NumOutputs-2
                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                            end
                        else
                            i = 0;
                        end
                        varargout{i+1} = outGyro;
                        varargout{i+2} = outMag;
                        varargout{i+3} = timestamp;
                    else
                        [outGyro,timestamp] = obj.OutputModules{end}.readSensor(obj);
                        % If more than status is required
                        if obj.NumOutputs > 1
                            for i = 1:obj.NumOutputs-1
                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                            end
                        else
                            i = 0;
                        end
                        varargout{i+1} = outGyro;
                        varargout{i+2} = timestamp;
                    end
                else
                    if obj.IsMagStatus && ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsFlatDetection || obj.IsDataReady)
                        [outMag,timestamp] = obj.OutputModules{end}.readSensor(obj);
                        % If more than status is required
                        if obj.NumOutputs > 1
                            for i = 1:obj.NumOutputs-1
                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                            end
                        else
                            i = 0;
                        end
                        varargout{i+1} = outMag;
                        varargout{i+2} = timestamp;
                    else
                        if obj.IsIntSource
                            if obj.IsTapEventSource
                                if obj.IsHighGEventSource
                                    if obj.IsAnyMotionEventSource
                                        [outIntSource,timestamp] = obj.OutputModules{end-3}.readSensor(obj);
                                        [outTapSource,timestamp] = obj.OutputModules{end-2}.readSensor(obj);
                                        [outHighGSource,timestamp] = obj.OutputModules{end-1}.readSensor(obj);
                                        [outAnyMotionSource,timestamp] = obj.OutputModules{end}.readSensor(obj);
                                        if obj.NumOutputs > 4
                                            for i = 1:obj.NumOutputs-4
                                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                                            end
                                        else
                                            i = 0;
                                        end
                                        varargout{i+1} = outIntSource;
                                        varargout{i+2} = outTapSource;
                                        varargout{i+3} = outHighGSource;
                                        varargout{i+4} = outAnyMotionSource;
                                        varargout{i+5} = timestamp;
                                    else
                                        [outIntSource,timestamp] = obj.OutputModules{end-2}.readSensor(obj);
                                        [outTapSource,timestamp] = obj.OutputModules{end-1}.readSensor(obj);
                                        [outHighGSource,timestamp] = obj.OutputModules{end}.readSensor(obj);
                                        if obj.NumOutputs > 3
                                            for i = 1:obj.NumOutputs-3
                                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                                            end
                                        else
                                            i = 0;
                                        end
                                        varargout{i+1} = outIntSource;
                                        varargout{i+2} = outTapSource;
                                        varargout{i+3} = outHighGSource;
                                        varargout{i+4} = timestamp;
                                    end
                                else
                                    if obj.IsAnyMotionEventSource
                                        [outIntSource,timestamp] = obj.OutputModules{end-2}.readSensor(obj);
                                        [outTapSource,timestamp] = obj.OutputModules{end-1}.readSensor(obj);
                                        [outAnyMotionSource,timestamp] = obj.OutputModules{end}.readSensor(obj);
                                        if obj.NumOutputs > 3
                                            for i = 1:obj.NumOutputs-3
                                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                                            end
                                        else
                                            i = 0;
                                        end
                                        varargout{i+1} = outIntSource;
                                        varargout{i+2} = outTapSource;
                                        varargout{i+3} = outAnyMotionSource;
                                        varargout{i+4} = timestamp;
                                    else
                                        [outIntSource,timestamp] = obj.OutputModules{end-1}.readSensor(obj);
                                        [outTapSource,timestamp] = obj.OutputModules{end}.readSensor(obj);
                                        if obj.NumOutputs > 2
                                            for i = 1:obj.NumOutputs-2
                                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                                            end
                                        else
                                            i = 0;
                                        end
                                        varargout{i+1} = outIntSource;
                                        varargout{i+2} = outTapSource;
                                        varargout{i+3} = timestamp;
                                    end
                                end
                            else
                                if obj.IsHighGEventSource
                                    if obj.IsAnyMotionEventSource
                                        [outIntSource,timestamp] = obj.OutputModules{end-2}.readSensor(obj);
                                        [outHighGSource,timestamp] = obj.OutputModules{end-1}.readSensor(obj);
                                        [outAnyMotionSource,timestamp] = obj.OutputModules{end}.readSensor(obj);
                                        if obj.NumOutputs > 3
                                            for i = 1:obj.NumOutputs-3
                                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                                            end
                                        else
                                            i = 0;
                                        end
                                        varargout{i+1} = outIntSource;
                                        varargout{i+2} = outHighGSource;
                                        varargout{i+3} = outAnyMotionSource;
                                        varargout{i+4} = timestamp;
                                    else
                                        [outIntSource,timestamp] = obj.OutputModules{end-1}.readSensor(obj);
                                        [outHighGSource,timestamp] = obj.OutputModules{end}.readSensor(obj);
                                        if obj.NumOutputs > 2
                                            for i = 1:obj.NumOutputs-2
                                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                                            end
                                        else
                                            i = 0;
                                        end
                                        varargout{i+1} = outIntSource;
                                        varargout{i+2} = outHighGSource;
                                        varargout{i+3} = timestamp;
                                    end
                                else
                                    if obj.IsAnyMotionEventSource
                                        [outIntSource,timestamp] = obj.OutputModules{end-1}.readSensor(obj);
                                        [outAnyMotionSource,timestamp] = obj.OutputModules{end}.readSensor(obj);
                                        if obj.NumOutputs > 2
                                            for i = 1:obj.NumOutputs-2
                                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                                            end
                                        else
                                            i = 0;
                                        end
                                        varargout{i+1} = outIntSource;
                                        varargout{i+2} = outAnyMotionSource;
                                        varargout{i+3} = timestamp;
                                    else
                                        [outIntSource,timestamp] = obj.OutputModules{end}.readSensor(obj);
                                        if obj.NumOutputs > 1
                                            for i = 1:obj.NumOutputs-1
                                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                                            end
                                        else
                                            i = 0;
                                        end
                                        varargout{i+1} = outIntSource;
                                        varargout{i+2} = timestamp;
                                    end
                                end
                            end
                        else
                            for i = 1:obj.NumOutputs
                                [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                            end
                            varargout{i+1} = timestamp;
                        end
                    end
                end
            end
        end
    end

    methods
        function validateAnyMotionAmplitudeThreshold(obj,val)
            switch obj.AccelerationRange
                case '+/- 2g'
                    initialOffset=0.00195;
                    rangeSpecificStep=0.00391;
                case '+/- 4g'
                    initialOffset=0.00391;
                    rangeSpecificStep=0.00781;
                case '+/- 8g'
                    initialOffset=0.00781;
                    rangeSpecificStep=0.01563;
                case '+/- 16g'
                    initialOffset=0.01563;
                    rangeSpecificStep=0.03125;
            end
            maxAmplitudePossible = ((255.*rangeSpecificStep) + initialOffset);
            if coder.target('MATLAB')
                validateattributes(val, {'double'}, ...
                    { '>=',initialOffset, '<=', maxAmplitudePossible, 'real', 'nonnan','nonempty', 'scalar'}, ...
                    '',message('matlab_sensors:blockmask:bmi160AnymotionAmplitudeMessage').getString);
            end
        end
        function set.AnyMotionAmplitudeThreshold2g(obj,val)
            validateAnyMotionAmplitudeThreshold(obj,val);
            obj.AnyMotionAmplitudeThreshold2g = val;
        end

        function set.AnyMotionAmplitudeThreshold4g(obj,val)
            validateAnyMotionAmplitudeThreshold(obj,val);
            obj.AnyMotionAmplitudeThreshold4g = val;
        end

        function set.AnyMotionAmplitudeThreshold8g(obj,val)
            validateAnyMotionAmplitudeThreshold(obj,val);
            obj.AnyMotionAmplitudeThreshold8g = val;
        end

        function set.AnyMotionAmplitudeThreshold16g(obj,val)
            validateAnyMotionAmplitudeThreshold(obj,val);
            obj.AnyMotionAmplitudeThreshold16g = val;
        end

        function validateSingleTapAmplitudeThreshold(obj,val)
            switch obj.AccelerationRange
                case '+/- 2g'
                    initialOffset=0.03125;
                    rangeSpecificStep=0.0625;
                case '+/- 4g'
                    initialOffset=0.0625;
                    rangeSpecificStep=0.125;
                case '+/- 8g'
                    initialOffset=0.125;
                    rangeSpecificStep=0.25;
                case '+/- 16g'
                    initialOffset=0.25;
                    rangeSpecificStep=0.5;
            end
            maxAmplitudePossible = ((31.*rangeSpecificStep) + initialOffset);
            if coder.target('MATLAB')
                validateattributes(val, {'double'}, ...
                    { '>=',initialOffset, '<=', maxAmplitudePossible, 'real', 'nonnan','nonempty', 'scalar'}, ...
                    '',message('matlab_sensors:blockmask:bmi160SingletapAmplitudeMessage').getString);
            end
        end

        function set.SingleTapAmplitudeThreshold2g(obj,val)
            validateSingleTapAmplitudeThreshold(obj,val);
            obj.SingleTapAmplitudeThreshold2g = val;
        end

        function set.SingleTapAmplitudeThreshold4g(obj,val)
            validateSingleTapAmplitudeThreshold(obj,val);
            obj.SingleTapAmplitudeThreshold4g = val;
        end

        function set.SingleTapAmplitudeThreshold8g(obj,val)
            validateSingleTapAmplitudeThreshold(obj,val);
            obj.SingleTapAmplitudeThreshold8g = val;
        end

        function set.SingleTapAmplitudeThreshold16g(obj,val)
            validateSingleTapAmplitudeThreshold(obj,val);
            obj.SingleTapAmplitudeThreshold16g = val;
        end

        function set.HighGTimeThreshold(obj,val)
            if coder.target('MATLAB')
                validateattributes(val, {'double'}, ...
                    { '>=',2.5, '<=', 640, 'real', 'nonnan','nonempty', 'scalar'}, ...
                    '',message('matlab_sensors:blockmask:bmi160HighGTimeMessage').getString);
            end
            obj.HighGTimeThreshold = val;
        end

        function set.FlatThetaThreshold(obj,val)
            if coder.target('MATLAB')
                validateattributes(val, {'double'}, ...
                    { '>=',0.7, '<=', 44.8, 'real', 'nonnan','nonempty', 'scalar'}, ...
                    '',message('matlab_sensors:blockmask:bmi160FlatThetaMessage').getString);
            end
            obj.FlatThetaThreshold = val;
        end

        function validateHighGAmplitudeThreshold(obj,val)
            switch obj.AccelerationRange
                case '+/- 2g'
                    initialOffset=0.00391;
                    rangeSpecificStep=0.00781;
                case '+/- 4g'
                    initialOffset=0.00781;
                    rangeSpecificStep=0.01563;
                case '+/- 8g'
                    initialOffset=0.01563;
                    rangeSpecificStep=0.03125;
                case '+/- 16g'
                    initialOffset=0.03125;
                    rangeSpecificStep=0.0625;
            end
            maxAmplitudePossible = ((255.*rangeSpecificStep) + initialOffset);
            if coder.target('MATLAB')
                validateattributes(val, {'double'}, ...
                    { '>=',initialOffset, '<=', maxAmplitudePossible, 'real', 'nonnan','nonempty', 'scalar'}, ...
                    '',message('matlab_sensors:blockmask:bmi160HighGAmplitudeMessage').getString);
            end
        end

        function set.HighGAmplitudeThreshold2g(obj,val)
            validateHighGAmplitudeThreshold(obj,val);
            obj.HighGAmplitudeThreshold2g = val;
        end

        function set.HighGAmplitudeThreshold4g(obj,val)
            validateHighGAmplitudeThreshold(obj,val);
            obj.HighGAmplitudeThreshold4g = val;
        end

        function set.HighGAmplitudeThreshold8g(obj,val)
            validateHighGAmplitudeThreshold(obj,val);
            obj.HighGAmplitudeThreshold8g = val;
        end

        function set.HighGAmplitudeThreshold16g(obj,val)
            validateHighGAmplitudeThreshold(obj,val);
            obj.HighGAmplitudeThreshold16g = val;
        end

        function validateSlowMotionAmplitudeThreshold(obj,val)
            switch obj.AccelerationRange
                case '+/- 2g'
                    initialOffset=0.00195;
                    rangeSpecificStep=0.00391;
                case '+/- 4g'
                    initialOffset=0.00391;
                    rangeSpecificStep=0.00781;
                case '+/- 8g'
                    initialOffset=0.00781;
                    rangeSpecificStep=0.01563;
                case '+/- 16g'
                    initialOffset=0.01563;
                    rangeSpecificStep=0.03125;
            end
            maxAmplitudePossible = ((255.*rangeSpecificStep) + initialOffset);
            if coder.target('MATLAB')
                validateattributes(val, {'double'}, ...
                    { '>=',initialOffset, '<=', maxAmplitudePossible, 'real', 'nonnan','nonempty', 'scalar'}, ...
                    '',message('matlab_sensors:blockmask:bmi160SlowmotionAmplitudeMessage').getString);
            end
        end

        function set.SlowMotionAmplitudeThreshold2g(obj,val)
            validateSlowMotionAmplitudeThreshold(obj,val);
            obj.SlowMotionAmplitudeThreshold2g = val;
        end

        function set.SlowMotionAmplitudeThreshold4g(obj,val)
            validateSlowMotionAmplitudeThreshold(obj,val);
            obj.SlowMotionAmplitudeThreshold4g = val;
        end

        function set.SlowMotionAmplitudeThreshold8g(obj,val)
            validateSlowMotionAmplitudeThreshold(obj,val);
            obj.SlowMotionAmplitudeThreshold8g = val;
        end

        function set.SlowMotionAmplitudeThreshold16g(obj,val)
            validateSlowMotionAmplitudeThreshold(obj,val);
            obj.SlowMotionAmplitudeThreshold16g = val;
        end
    end
    methods(Access = protected)
        % Block mask display
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            outport_label = [];
            num = getNumOutputsImpl(obj);
            if num > 0
                outputs = cell(1,num);
                [outputs{1:num}] = getOutputNamesImpl(obj);
                for i = 1:num
                    outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' ]; %#ok<AGROW>
                end
            end
            maskDisplayCmds = [ ...
                ['color(''white'');',newline],...
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);',newline]...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);',newline]...
                ['color(''blue'');',newline] ...
                ['text(38, 92, ','''',obj.Logo,'''',',''horizontalAlignment'', ''right'');',newline],...
                ['color(''black'');',newline], ...
                ['image(imread(fullfile(matlabshared.sensors.internal.getSensorRootDir,''+matlabshared'',''+sensors'',''+simulink'',''+internal'',''IMU_image.png'')),''center'');', newline], ...
                ['text(52,12,' [''' ' 'BMI160' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end

        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "AccelerationRange"
                    flag = ~obj.IsActiveAccel;
                case "AccelerometerODR"
                    flag = ~obj.IsActiveAccel;
                case "IsAnyMotion"
                    flag = ~obj.IsActiveAccel;
                case "IsSingleTap"
                    flag = ~obj.IsActiveAccel;
                case "IsDoubleTap"
                    flag = ~obj.IsActiveAccel;
                case "IsHighGDetection"
                    flag = ~obj.IsActiveAccel;
                case "IsSlowMotion"
                    flag = ~obj.IsActiveAccel;
                case "IsDataReady"
                    flag = ~(obj.IsActiveAccel||obj.IsActiveGyro||obj.IsActiveMag);
                case "IsFlatDetection"
                    flag = ~obj.IsActiveAccel;
                case "InterruptPinAnyMotion"
                    flag = ~(obj.IsAnyMotion && obj.IsActiveAccel);
                case "InterruptPinSingleTap"
                    flag = ~(obj.IsSingleTap && obj.IsActiveAccel);
                case "InterruptPinDoubleTap"
                    flag = ~(obj.IsDoubleTap && obj.IsActiveAccel);
                case "InterruptPinHighG"
                    flag = ~(obj.IsHighGDetection && obj.IsActiveAccel);
                case "InterruptPinSlowMotion"
                    flag = ~(obj.IsSlowMotion && obj.IsActiveAccel);
                case "InterruptPinDataReady"
                    flag = ~(obj.IsDataReady && (obj.IsActiveAccel||obj.IsActiveGyro||obj.IsActiveMag));
                case "InterruptPinFifo"
                    flag = ~obj.IsFifo;
                case "FifoMode"
                    flag = ~obj.IsFifo;
                case "FifoWaterMarkThreshold"
                    flag = ~(obj.IsFifo && strcmp(obj.FifoMode,"Water Mark"));
                case "FlatThetaThreshold"
                    flag = ~(obj.IsFlatDetection && obj.IsActiveAccel);
                case "FlatTimeThreshold"
                    flag = ~(obj.IsFlatDetection && obj.IsActiveAccel);
                case "InterruptPinFlat"
                    flag = ~(obj.IsFlatDetection && obj.IsActiveAccel);
                case "AnyMotionTimeThreshold"
                    flag = ~(obj.IsAnyMotion && obj.IsActiveAccel);
                case "AnyMotionAmplitudeThreshold2g"
                    switch obj.AccelerationRange
                        case '+/- 2g'
                            flag = ~(obj.IsAnyMotion && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "AnyMotionAmplitudeThreshold4g"
                    switch obj.AccelerationRange
                        case '+/- 4g'
                            flag = ~(obj.IsAnyMotion && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "AnyMotionAmplitudeThreshold8g"
                    switch obj.AccelerationRange
                        case '+/- 8g'
                            flag = ~(obj.IsAnyMotion && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "AnyMotionAmplitudeThreshold16g"
                    switch obj.AccelerationRange
                        case '+/- 16g'
                            flag = ~(obj.IsAnyMotion && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "SingleTapQuietTimeThreshold"
                    flag = ~((obj.IsSingleTap || obj.IsDoubleTap)&& obj.IsActiveAccel);
                case "SingleTapShockTimeThreshold"
                    flag = ~((obj.IsSingleTap || obj.IsDoubleTap)&& obj.IsActiveAccel);
                case "SingleTapAmplitudeThreshold2g"
                    switch obj.AccelerationRange
                        case '+/- 2g'
                            flag = ~((obj.IsSingleTap || obj.IsDoubleTap) && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "SingleTapAmplitudeThreshold4g"
                    switch obj.AccelerationRange
                        case '+/- 4g'
                            flag = ~((obj.IsSingleTap || obj.IsDoubleTap) && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "SingleTapAmplitudeThreshold8g"
                    switch obj.AccelerationRange
                        case '+/- 8g'
                            flag = ~((obj.IsSingleTap || obj.IsDoubleTap) && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "SingleTapAmplitudeThreshold16g"
                    switch obj.AccelerationRange
                        case '+/- 16g'
                            flag = ~((obj.IsSingleTap || obj.IsDoubleTap)&& obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "DoubleTapDurationTimeThreshold"
                    flag = ~(obj.IsDoubleTap && obj.IsActiveAccel);
                case "HighGTimeThreshold"
                    flag = ~(obj.IsHighGDetection && obj.IsActiveAccel);
                case "HighGAmplitudeThreshold2g"
                    switch obj.AccelerationRange
                        case '+/- 2g'
                            flag = ~(obj.IsHighGDetection && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "HighGAmplitudeThreshold4g"
                    switch obj.AccelerationRange
                        case '+/- 4g'
                            flag = ~(obj.IsHighGDetection && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "HighGAmplitudeThreshold8g"
                    switch obj.AccelerationRange
                        case '+/- 8g'
                            flag = ~(obj.IsHighGDetection && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "HighGAmplitudeThreshold16g"
                    switch obj.AccelerationRange
                        case '+/- 16g'
                            flag = ~(obj.IsHighGDetection && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "SlowMotionTimeThreshold"
                    flag = ~(obj.IsSlowMotion && obj.IsActiveAccel);
                case "SlowMotionAmplitudeThreshold2g"
                    switch obj.AccelerationRange
                        case '+/- 2g'
                            flag = ~(obj.IsSlowMotion && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "SlowMotionAmplitudeThreshold4g"
                    switch obj.AccelerationRange
                        case '+/- 4g'
                            flag = ~(obj.IsSlowMotion && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "SlowMotionAmplitudeThreshold8g"
                    switch obj.AccelerationRange
                        case '+/- 8g'
                            flag = ~(obj.IsSlowMotion && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "SlowMotionAmplitudeThreshold16g"
                    switch obj.AccelerationRange
                        case '+/- 16g'
                            flag = ~(obj.IsSlowMotion && obj.IsActiveAccel);
                        otherwise
                            flag = true;
                    end
                case "MagnetometerI2CAddress"
                    flag = ~obj.EnableSecondaryMag;
                case "IsActiveMag"
                    flag = ~obj.EnableSecondaryMag;
                case "IsEnableAccelLowPassFilter"
                    flag = ~obj.IsActiveAccel;
                case "AccelerometerFilterMode"
                    flag = ~(obj.IsActiveAccel && obj.IsEnableAccelLowPassFilter);
                case "GyroscopeRange"
                    flag = ~obj.IsActiveGyro;
                case "GyroscopeODR"
                    flag = ~obj.IsActiveGyro;
                case "IsEnableGyroLowPassFilter"
                    flag = ~obj.IsActiveGyro;
                case "GyroscopeFilterMode"
                    flag = ~(obj.IsActiveGyro && obj.IsEnableGyroLowPassFilter);
                case "MagnetometerODR"
                    flag = ~(obj.IsActiveMag && obj.EnableSecondaryMag);
                case "IsAccelStatus"
                    flag = obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsDataReady || obj.IsFlatDetection;
                case "IsGyroStatus"
                    flag = obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsDataReady || obj.IsFlatDetection;
                case "IsMagStatus"
                    flag = obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsDataReady || obj.IsFlatDetection|| ~obj.EnableSecondaryMag;
                case "BitRate"
                    flag = true;
                case "IsIntSource"
                    flag = ~(obj.IsAnyMotion || obj.IsSingleTap || obj.IsDoubleTap || obj.IsHighGDetection || obj.IsSlowMotion || obj.IsDataReady ||obj.IsFlatDetection);
                case "IsTapEventSource"
                    flag = ~(obj.IsIntSource && (obj.IsSingleTap || obj.IsDoubleTap) && obj.IsActiveAccel);
                case "IsAnyMotionEventSource"
                    flag = ~(obj.IsIntSource && (obj.IsAnyMotion) && obj.IsActiveAccel);
                case "IsHighGEventSource"
                    flag = ~(obj.IsHighGDetection && (obj.IsIntSource) && obj.IsActiveAccel);
            end
        end

        function validatePropertiesImpl(obj)
            % Validate related or interdependent property values
            %Check whether all outputs are disabled. In that case an error is
            %thrown asking user to enable atleast one output
            if ~obj.IsActiveGyro && ~obj.IsActiveAccel && ~(obj.IsActiveMag && obj.EnableSecondaryMag) && ~obj.IsActiveTemperature && ~obj.IsAccelStatus && ~obj.IsGyroStatus && ~obj.IsMagStatus
                error(message('matlab_sensors:general:SensorsNoOutputs'));
            end
        end
    end

    methods(Access = protected, Static)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'BMI160 6DOF IMU Sensor','Text',message('matlab_sensors:blockmask:bmi160MaskDescription',char(181) ,char(0176)).getString,'ShowSourceLink',false);
        end
        function groups = getPropertyGroupsImpl
            i2cModule = matlab.system.display.internal.Property('I2CModule', 'Description', 'I2C module');
            i2cAddress = matlab.system.display.internal.Property('I2CAddress', 'Description', 'BMI160 I2C address');
            anyMotionProp = matlab.system.display.internal.Property('IsAnyMotion', 'Description', 'Any motion');
            anyMotionTimeThresholdProp = matlab.system.display.internal.Property('AnyMotionTimeThreshold', 'Description', 'Time threshold');
            anyMotionAmplitudeThresholdProp = matlab.system.display.internal.Property('AnyMotionAmplitudeThreshold2g', 'Description', ['Amplitude threshold (0.00195 g - 0.999 g)']);
            anyMotionAmplitudeThresholdProp4g = matlab.system.display.internal.Property('AnyMotionAmplitudeThreshold4g', 'Description', ['Amplitude threshold (0.00391 g - 1.99546 g)']);
            anyMotionAmplitudeThresholdProp8g = matlab.system.display.internal.Property('AnyMotionAmplitudeThreshold8g', 'Description', ['Amplitude threshold (0.00781 g - 3.99346 g)']);
            anyMotionAmplitudeThresholdProp16g = matlab.system.display.internal.Property('AnyMotionAmplitudeThreshold16g', 'Description', ['Amplitude threshold (0.01563 g - 7.98438 g)']);
            singleTapProp = matlab.system.display.internal.Property('IsSingleTap', 'Description', 'Single tap');
            singleTapQuietTimeThresholdProp = matlab.system.display.internal.Property('SingleTapQuietTimeThreshold', 'Description', 'Quiet Time threshold');
            singleTapShockTimeThresholdProp = matlab.system.display.internal.Property('SingleTapShockTimeThreshold', 'Description', 'Shock Time threshold');
            singleTapAmplitudeThresholdProp2g = matlab.system.display.internal.Property('SingleTapAmplitudeThreshold2g', 'Description', 'Amplitude threshold (0.03125 g - 1.96875 g)');
            singleTapAmplitudeThresholdProp4g = matlab.system.display.internal.Property('SingleTapAmplitudeThreshold4g', 'Description', 'Amplitude threshold (0.0625 g - 3.9375 g)');
            singleTapAmplitudeThresholdProp8g = matlab.system.display.internal.Property('SingleTapAmplitudeThreshold8g', 'Description', 'Amplitude threshold (0.125 g - 7.875 g)');
            singleTapAmplitudeThresholdProp16g = matlab.system.display.internal.Property('SingleTapAmplitudeThreshold16g', 'Description', 'Amplitude threshold (0.25 g - 15.75 g)');
            doubleTapProp = matlab.system.display.internal.Property('IsDoubleTap', 'Description', 'Double tap');
            doubleTapDurationTimeThresholdProp = matlab.system.display.internal.Property('DoubleTapDurationTimeThreshold', 'Description', 'Duration Time threshold');
            flatdetectionProp = matlab.system.display.internal.Property('IsFlatDetection', 'Description', 'Flat detection');
            flatthetaThreshold = matlab.system.display.internal.Property('FlatThetaThreshold', 'Description', ['Theta threshold (0.7',char(0176),' to 44.8 ',char(0176),')']);
            flattimeThreshold = matlab.system.display.internal.Property('FlatTimeThreshold', 'Description', 'Time threshold');
            interruptPinFlat = matlab.system.display.internal.Property('InterruptPinFlat', 'Description', 'Interrupt generate pin');
            highGDetectionProp = matlab.system.display.internal.Property('IsHighGDetection', 'Description', 'High g detection');
            highGTimeThresholdProp = matlab.system.display.internal.Property('HighGTimeThreshold', 'Description', 'Time threshold (2.5 ms to 640 ms)');
            highGAmplitudeThresholdProp2g = matlab.system.display.internal.Property('HighGAmplitudeThreshold2g', 'Description', 'Amplitude threshold (0.00391 g - 1.99546 g)');
            highGAmplitudeThresholdProp4g = matlab.system.display.internal.Property('HighGAmplitudeThreshold4g', 'Description', 'Amplitude threshold (0.00781 g - 3.99346 g)');
            highGAmplitudeThresholdProp8g = matlab.system.display.internal.Property('HighGAmplitudeThreshold8g', 'Description', 'Amplitude threshold (0.01563 g - 7.98438 g)');
            highGAmplitudeThresholdProp16g = matlab.system.display.internal.Property('HighGAmplitudeThreshold16g', 'Description', 'Amplitude threshold (0.03125 g - 15.96875 g)');
            slowMotionProp = matlab.system.display.internal.Property('IsSlowMotion', 'Description', 'Slow motion');
            slowMotionTimeThresholdProp = matlab.system.display.internal.Property('SlowMotionTimeThreshold', 'Description', 'Time threshold');
            slowMotionAmplitudeThresholdProp2g = matlab.system.display.internal.Property('SlowMotionAmplitudeThreshold2g', 'Description', 'Amplitude threshold (0.00195 g - 0.999 g)');
            slowMotionAmplitudeThresholdProp4g = matlab.system.display.internal.Property('SlowMotionAmplitudeThreshold4g', 'Description', 'Amplitude threshold (0.00391 g - 1.99546 g)');
            slowMotionAmplitudeThresholdProp8g = matlab.system.display.internal.Property('SlowMotionAmplitudeThreshold8g', 'Description', 'Amplitude threshold (0.00781 g - 3.99346 g)');
            slowMotionAmplitudeThresholdProp16g = matlab.system.display.internal.Property('SlowMotionAmplitudeThreshold16g', 'Description', 'Amplitude threshold (0.01563 g - 7.98438 g)');
            dataReadyProp = matlab.system.display.internal.Property('IsDataReady', 'Description', 'Data ready');
            fifoProp = matlab.system.display.internal.Property('IsFifo', 'Description', 'FIFO','IsGraphical',false);
            interruptPinAnymotion = matlab.system.display.internal.Property('InterruptPinAnyMotion', 'Description', 'Interrupt generate pin');
            interruptPinSingleTap = matlab.system.display.internal.Property('InterruptPinSingleTap', 'Description', 'Interrupt generate pin');
            interruptPinDoubleTap = matlab.system.display.internal.Property('InterruptPinDoubleTap', 'Description', 'Interrupt generate pin');
            interruptPinHighG = matlab.system.display.internal.Property('InterruptPinHighG', 'Description', 'Interrupt generate pin');
            interruptPinSlowMotion = matlab.system.display.internal.Property('InterruptPinSlowMotion', 'Description', 'Interrupt generate pin');
            interruptPinDataReady = matlab.system.display.internal.Property('InterruptPinDataReady', 'Description', 'Interrupt generate pin');
            interruptPinFifo = matlab.system.display.internal.Property('InterruptPinFifo', 'Description', 'Interrupt generate pin','IsGraphical',false);
            fifoModeSelect = matlab.system.display.internal.Property('FifoMode', 'Description', 'Select FIFO interrupt type','IsGraphical',false);
            fifoWaterMarkThreshold = matlab.system.display.internal.Property('FifoWaterMarkThreshold', 'Description', 'Select FIFO interrupt type','IsGraphical',false);
            secondaryMagProp = matlab.system.display.internal.Property('EnableSecondaryMag', 'Description', 'Enable secondary magnetometer');
            magnetometerI2CAddress = matlab.system.display.internal.Property('MagnetometerI2CAddress', 'Description', 'BMM150 I2C address');
            bitRate=matlab.system.display.internal.Property('BitRate', 'Description', 'Bit rate','IsGraphical',false);
            i2cProperties = matlab.system.display.Section('PropertyList', {i2cModule,i2cAddress,secondaryMagProp,magnetometerI2CAddress,bitRate});
            % Select interrupts
            selectInterrupts = matlab.system.display.Section('Title', 'Generate interrupts on', 'PropertyList', {singleTapProp,singleTapQuietTimeThresholdProp,singleTapShockTimeThresholdProp,singleTapAmplitudeThresholdProp2g,singleTapAmplitudeThresholdProp4g,singleTapAmplitudeThresholdProp8g,singleTapAmplitudeThresholdProp16g,interruptPinSingleTap,doubleTapProp,doubleTapDurationTimeThresholdProp,interruptPinDoubleTap,highGDetectionProp,highGTimeThresholdProp,highGAmplitudeThresholdProp2g,highGAmplitudeThresholdProp4g,highGAmplitudeThresholdProp8g,highGAmplitudeThresholdProp16g,interruptPinHighG,anyMotionProp,anyMotionTimeThresholdProp,anyMotionAmplitudeThresholdProp,anyMotionAmplitudeThresholdProp4g,anyMotionAmplitudeThresholdProp8g,anyMotionAmplitudeThresholdProp16g,interruptPinAnymotion,slowMotionProp,slowMotionTimeThresholdProp,slowMotionAmplitudeThresholdProp2g,slowMotionAmplitudeThresholdProp4g,slowMotionAmplitudeThresholdProp8g,slowMotionAmplitudeThresholdProp16g,interruptPinSlowMotion,flatdetectionProp,flatthetaThreshold,flattimeThreshold,interruptPinFlat,dataReadyProp,interruptPinDataReady,fifoProp,fifoModeSelect,fifoWaterMarkThreshold,interruptPinFifo},'Type', matlab.system.display.SectionType.collapsiblepanel);
            % Select outputs
            gyroProp = matlab.system.display.internal.Property('IsActiveGyro', 'Description', 'Angular rate (rad/s)','Row',matlab.system.display.internal.Row.current);
            accelProp = matlab.system.display.internal.Property('IsActiveAccel', 'Description', 'Acceleration (m/s^2)','Row',matlab.system.display.internal.Row.current);
            magProp = matlab.system.display.internal.Property('IsActiveMag', 'Description', ['Magnetic field (',char(181),'T)'],'Row',matlab.system.display.internal.Row.current);
            temperatureProp = matlab.system.display.internal.Property('IsActiveTemperature', 'Description', ['Temperature (',char(0176),'C)'],'Row',matlab.system.display.internal.Row.current);
            accelStatusProp= matlab.system.display.internal.Property('IsAccelStatus','Description', 'Acceleration status');
            gyroStatusProp= matlab.system.display.internal.Property('IsGyroStatus','Description', 'Angular rate status','Row',matlab.system.display.internal.Row.current);
            magStatusProp= matlab.system.display.internal.Property('IsMagStatus','Description', 'Magnetic field status','Row',matlab.system.display.internal.Row.current);
            isIntSourceProp = matlab.system.display.internal.Property('IsIntSource','Description', 'Interrupt source');
            isTapEventSourceProp = matlab.system.display.internal.Property('IsTapEventSource','Description', 'Tap source','Row',matlab.system.display.internal.Row.current);
            isAnymotionEventSourceProp = matlab.system.display.internal.Property('IsAnyMotionEventSource','Description', 'Any motion source','Row',matlab.system.display.internal.Row.current);
            isHighGEventSourceProp = matlab.system.display.internal.Property('IsHighGEventSource','Description', 'High g source','Row',matlab.system.display.internal.Row.current);
            selectOutputs = matlab.system.display.Section('Title', 'Select outputs', 'PropertyList', {accelProp,gyroProp,magProp,temperatureProp,isIntSourceProp,isTapEventSourceProp,isHighGEventSourceProp,isAnymotionEventSourceProp,accelStatusProp,gyroStatusProp,magStatusProp});
            % Accelerometer properties
            accelerationRange = matlab.system.display.internal.Property('AccelerationRange','Description', 'Accelerometer range');
            accelerometerODR = matlab.system.display.internal.Property('AccelerometerODR','Description', 'Accelerometer output data rate');
            accelerometerFilterMode = matlab.system.display.internal.Property('AccelerometerFilterMode','Description', 'Accelerometer filter mode');
            enableLowPassFilter=matlab.system.display.internal.Property('IsEnableAccelLowPassFilter', 'Description', 'Enable low pass filter');
            % gyroscope properties
            gyroscopeRange = matlab.system.display.internal.Property('GyroscopeRange', 'Description', 'Gyroscope range');
            gyroscopeODR = matlab.system.display.internal.Property('GyroscopeODR', 'Description', 'Gyroscope output data rate');
            gyroscopeFilterMode = matlab.system.display.internal.Property('GyroscopeFilterMode', 'Description', 'Gyroscope filter mode');
            enableGyroLowPassFilter=matlab.system.display.internal.Property('IsEnableGyroLowPassFilter', 'Description', 'Enable low pass filter');
            % Magnetometer properties
            magnetometerODR =  matlab.system.display.internal.Property('MagnetometerODR', 'Description', 'Magnetometer output data rate');
            accelerometerSettings = matlab.system.display.Section(...
                'Title','Accelerometer settings',...
                'PropertyList',{accelerationRange,accelerometerODR,enableLowPassFilter,accelerometerFilterMode},'Type', matlab.system.display.SectionType.collapsiblepanel);
            gyroscopeSettings = matlab.system.display.Section(...
                'Title','Gyroscope settings',...
                'PropertyList',{gyroscopeRange,gyroscopeODR,enableGyroLowPassFilter,gyroscopeFilterMode},'Type', matlab.system.display.SectionType.collapsiblepanel);
            magnetometerSettings = matlab.system.display.Section(...
                'Title','Magnetometer settings',...
                'PropertyList',{magnetometerODR},'Type', matlab.system.display.SectionType.collapsiblepanel);
            dataType =  matlab.system.display.internal.Property('DataType', 'Description', 'Data type');
            dataTypeSection = matlab.system.display.Section('PropertyList', {dataType});
            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            sampleTimeSection = matlab.system.display.Section('PropertyList', {SampleTimeProp});
            MainGroup = matlab.system.display.SectionGroup(...
                'Title','Parameters',...
                'Sections', [i2cProperties,selectOutputs,accelerometerSettings,gyroscopeSettings,magnetometerSettings,selectInterrupts,dataTypeSection,sampleTimeSection]);
            groups=MainGroup;
        end
    end
end