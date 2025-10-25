classdef LSM6DSRAnd6DSOBase < sensors.internal.LSM6DSBase
    %Base class for LSM6DSR and LSM6DSO, since most of the features except
    %range and device ID are same for this sensors
    
    %   Copyright 2020-2021 The MathWorks, Inc.
    %#codegen
    properties(Access = protected, Constant)
        ODRParametersGyro =[12.5, 26, 52, 104, 208, 416, 833, 1666, 3332, 6664];
        ODRParametersAccel = [12.5, 26, 52, 104, 208, 416, 833, 1666, 3332, 6664];
    end
    
    properties(Hidden,Nontunable)
        % The sensor default condition. Only make the properties Abortset ,
        % if the values are sensor defaults
        AccelSelectCompositeFilters = 'No filter';
        AccelLPF2BW = 'ODR/4';
        AccelHPFBW = 'ODR/4';
        EnableGyroHPF = false;
        GyroHPFBW = 0.016;
        EnableGyroLPF = false;
        GyroLPFBWMode = 0;
    end
    
    properties(Hidden,Nontunable)
        GyroscopeODR = 12.5;
        AccelerometerODR = 12.5;
    end
    
    properties(Access = protected,Nontunable)
        TemperatureResolution = 1/256;
    end
    
    methods
        function obj = LSM6DSRAnd6DSOBase(varargin)
            obj@sensors.internal.LSM6DSBase(varargin{:})
            if ~obj.isSimulink
                if ~coder.target('MATLAB')
                    obj.init(varargin{:});
                else
                    try
                        obj.init(varargin{:});
                    catch ME
                        throwAsCaller(ME);
                    end
                end
                     % For MATLAB, activate all the sensors and set the
                     % default values for the properties. No need of
                     % setting accel and gyro odr here, since those will be
                     % set in setODRImpl();
                     obj.isActiveAccel = true;
                     obj.isActiveGyro = true;
                     obj.isActiveTemp = true;
                     obj.AccelerometerRange = '+/- 2g';
                     obj.GyroscopeRange = '125 dps';
                     obj.AccelSelectCompositeFilters = 'No filter';
                     obj.AccelLPF2BW = 'ODR/4';
                     obj.AccelHPFBW = 'ODR/4';
                     obj.EnableGyroHPF = false;
                     obj.GyroHPFBW = 0.016;
                     obj.EnableGyroLPF = false;
                     obj.GyroLPFBWMode =  0;
            else
                names =     {'Bus','I2CAddress','isActiveAccel','isActiveGyro','isActiveTemp', 'AccelerometerRange', 'AccelerometerODR', ...
                    'AccelSelectCompositeFilters', 'AccelLPF2BW', 'AccelHPFBW', 'GyroscopeRange',...
                    'GyroscopeODR', 'EnableGyroHPF', 'GyroHPFBW' ,'EnableGyroLPF', 'GyroLPFBWMode'};
                defaults =    {0,0x6A, true,true,true, '+/- 2g', 12.5,...
                    'No filter','ODR/4','ODR/4','125 dps',...
                    12.5, false, 0.016, false, 0};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                i2cAddress = p.parameterValue('I2CAddress');
                bus =  p.parameterValue('Bus');
                % For simulink, all the other properties,
                % (readmode,outputformat etc) are irrelevant.
                obj.init(varargin{1},'I2CAddress',i2cAddress,'Bus',bus);
                obj.isActiveAccel = p.parameterValue('isActiveAccel');
                obj.isActiveGyro= p.parameterValue('isActiveGyro');
                obj.isActiveTemp = p.parameterValue('isActiveTemp');
                obj.AccelerometerRange = p.parameterValue('AccelerometerRange');
                obj.AccelerometerODR =  p.parameterValue('AccelerometerODR');
                obj.AccelSelectCompositeFilters = p.parameterValue('AccelSelectCompositeFilters');
                obj.AccelLPF2BW = p.parameterValue('AccelLPF2BW');
                obj.AccelHPFBW = p.parameterValue('AccelHPFBW');
                obj.GyroscopeRange = p.parameterValue('GyroscopeRange');
                obj.GyroscopeODR =  p.parameterValue('GyroscopeODR');
                obj.EnableGyroHPF = p.parameterValue('EnableGyroHPF');
                obj.GyroHPFBW = p.parameterValue('GyroHPFBW');
                obj.EnableGyroLPF =p.parameterValue('EnableGyroLPF');
                obj.GyroLPFBWMode =  p.parameterValue('GyroLPFBWMode');
            end
        end
        
        function set.AccelerometerODR(obj, value)
            % First 4 bits of the CTRL1_XL is used for ODR setting
            if obj.isActiveAccel
                switch value
                    case 12.5
                        ByteMask_CTRL1_XL = 0x10;
                    case 26
                        ByteMask_CTRL1_XL = 0x20;
                    case 52
                        ByteMask_CTRL1_XL = 0x30;
                    case 104
                        ByteMask_CTRL1_XL = 0x40;
                    case 208
                        ByteMask_CTRL1_XL = 0x50;
                    case 416
                        ByteMask_CTRL1_XL = 0x60;
                    case 833
                        ByteMask_CTRL1_XL = 0x70;
                    case 1666
                        ByteMask_CTRL1_XL = 0x80;
                    case 3332
                        ByteMask_CTRL1_XL = 0x90;
                    case 6664
                        ByteMask_CTRL1_XL = 0xA0;
                    otherwise
                        ByteMask_CTRL1_XL = 0x10;
                end
                val_CTRL1_XL = readRegister(obj.Device, obj.CTRL1_XL);
                writeRegister(obj.Device,obj.CTRL1_XL, bitor(bitand(val_CTRL1_XL, uint8(0x0F)), uint8(ByteMask_CTRL1_XL)));
                obj.AccelerometerODR = value;
            end
        end
        
        function set.AccelSelectCompositeFilters(obj,value)
            value = selectCompositeFilter(obj,value);
            if obj.isActiveAccel
                obj.AccelSelectCompositeFilters = value;
            else
                obj.AccelSelectCompositeFilters = 'No filter';
            end
        end
        
        function set.AccelLPF2BW(obj,value)
            % Same set of bits are used for HPF and LPF, hence same
            % function call for AccelLPF2BW and AccelHPFBW
            setAccelCompositeLPFBW(obj,value);
            obj.AccelLPF2BW = value;
        end
        
        function set.AccelHPFBW(obj,value)
            setAccelCompositeHPFBW(obj,value);
            obj.AccelHPFBW = value;
        end
        
        function set.GyroscopeODR(obj,value)
            if obj.isActiveGyro
                switch value
                    case 12.5
                        ByteMask_CTRL2_G = 0x10;
                    case 26
                        ByteMask_CTRL2_G = 0x20;
                    case 52
                        ByteMask_CTRL2_G = 0x30;
                    case 104
                        ByteMask_CTRL2_G = 0x40;
                    case 208
                        ByteMask_CTRL2_G = 0x50;
                    case 416
                        ByteMask_CTRL2_G = 0x60;
                    case 833
                        ByteMask_CTRL2_G = 0x70;
                    case 1666
                        ByteMask_CTRL2_G = 0x80;
                    case 3332
                        ByteMask_CTRL2_G = 0x90;
                    case 6664
                        ByteMask_CTRL2_G = 0xA0;
                    otherwise
                        ByteMask_CTRL2_G = 0x30;
                end
                val = readRegister(obj.Device, obj.CTRL2_G);
                writeRegister(obj.Device, obj.CTRL2_G ,bitor(bitand(val, uint8(0x0F)), uint8(ByteMask_CTRL2_G)));
                obj.GyroscopeODR = value;
            else
                obj.GyroscopeODR = 0;
            end
        end
        
        function set.EnableGyroHPF(obj,value)
            % Enabling bit will be set along with BW(to avoid multiple I2C
            % operations)
            obj.EnableGyroHPF = value;
        end
        
        function set.GyroHPFBW(obj,value)
            setHPFBWGyro(obj,value);
            obj.GyroHPFBW = value;
        end
        
        function set.EnableGyroLPF(obj,value)
            setEnableGyroLPF(obj,value);
            obj.EnableGyroLPF = value;
        end
        
        function set.GyroLPFBWMode(obj,value)
            value = setLPFBWModeGyro(obj,value);
            obj.GyroLPFBWMode = value;
        end
    end
    
    methods(Access = protected)
        function setODRImpl(obj)
            % used only for MATLAB
            gyroODR = obj.ODRParametersGyro(obj.ODRParametersGyro<=obj.SampleRate);
            accelODR = obj.ODRParametersAccel(obj.ODRParametersAccel<=obj.SampleRate);
            obj.AccelerometerODR = accelODR(end);
            obj.GyroscopeODR = gyroODR(end);
        end
    end
    
    methods(Access = private)
        function value =  selectCompositeFilter(obj,value)
            % HP_SLOPE_XL_EN = 1(CTRl8_XL) for HPF,
            % LPF2_XL_EN = 1 (CTRL1_XL),HP_SLOPE_XL_EN = 0(CTRl8_XL) for LPF
            switch value
                case 'Low pass filter'
                    val_CTRL1_XL = readRegister(obj.Device, obj.CTRL1_XL,1,'uint8');
                    writeRegister(obj.Device,obj.CTRL1_XL, bitor(val_CTRL1_XL,0x02));
                    val_CTRL8_XL = readRegister(obj.Device, obj.CTRL8_XL,1,'uint8');
                    writeRegister(obj.Device,obj.CTRL8_XL, bitand(val_CTRL8_XL,0xFB));
                case 'High pass filter'
                    val_CTRL1_XL = readRegister(obj.Device, obj.CTRL1_XL,1,'uint8');
                    writeRegister(obj.Device,obj.CTRL1_XL, bitand(val_CTRL1_XL,0xFD));
                    val_CTRL8_XL = readRegister(obj.Device, obj.CTRL8_XL,1,'uint8');
                    writeRegister(obj.Device,obj.CTRL8_XL, bitor(val_CTRL8_XL,0x04));
                otherwise
                    % disable LPF2 andHPF
                    value = 'No filter';
                    val_CTRL1_XL = readRegister(obj.Device, obj.CTRL1_XL,1,'uint8');
                    writeRegister(obj.Device,obj.CTRL1_XL, bitand(val_CTRL1_XL,0xFD));
                    val_CTRL8_XL = readRegister(obj.Device, obj.CTRL8_XL,1,'uint8');
                    writeRegister(obj.Device,obj.CTRL8_XL, bitand(val_CTRL8_XL,0xFB));
            end
        end
        
       function setAccelCompositeHPFBW(obj,value)
           if strcmp(obj.AccelSelectCompositeFilters,'High pass filter')
                setAccelCompositeFilterBW(obj,value)
           end
       end
       
       function setAccelCompositeLPFBW(obj,value)
           if strcmp(obj.AccelSelectCompositeFilters,'Low pass filter')
                setAccelCompositeFilterBW(obj,value)
           end
       end
        
        function setAccelCompositeFilterBW(obj,value)
            % Set the BW of LPF or HPF composite filter
            switch value
                case 'ODR/4'
                    ByteMask_CTRL8_XL = 0x00;
                case 'ODR/10'
                    ByteMask_CTRL8_XL = 0x20;
                case 'ODR/20'
                    ByteMask_CTRL8_XL = 0x40;
                case 'ODR/45'
                    ByteMask_CTRL8_XL = 0x60;
                case 'ODR/100'
                    ByteMask_CTRL8_XL = 0x80;
                case 'ODR/200'
                    ByteMask_CTRL8_XL = 0xA0;
                case 'ODR/400'
                    ByteMask_CTRL8_XL = 0xC0;
                case 'ODR/800'
                    ByteMask_CTRL8_XL = 0xE0;
                otherwise
                    ByteMask_CTRL8_XL = 0x00;
            end
            val = readRegister(obj.Device, obj.CTRL8_XL);
            writeRegister(obj.Device,obj.CTRL8_XL, bitor(bitand(val, uint8(0x1F)), uint8(ByteMask_CTRL8_XL)));
        end
        
        function setHPFBWGyro(obj,value)
            % Enable Gyro High Pass filter and set the Bandwidth
            if obj.EnableGyroHPF
                switch value
                    case 0.016
                        ByteMask_CTRL7_G = 0x40;
                    case 0.065
                        ByteMask_CTRL7_G = 0x50;
                    case 0.260
                        ByteMask_CTRL7_G = 0x60;
                    case 1.04
                        ByteMask_CTRL7_G = 0x70;
                    otherwise
                        ByteMask_CTRL7_G = 0x40;
                end
                val = readRegister(obj.Device, obj.CTRL7_G);
                writeRegister(obj.Device,obj.CTRL7_G, bitor(bitand(val, uint8(0x8F)), uint8(ByteMask_CTRL7_G)));
            end
        end
        
        function setEnableGyroLPF(obj,value)
            if obj.isActiveAccel
                if value
                    val = readRegister(obj.Device, obj.CTRL4_C);
                    writeRegister(obj.Device,obj.CTRL4_C, bitor(val, 0x02));
                else
                    val = readRegister(obj.Device, obj.CTRL4_C);
                    writeRegister(obj.Device,obj.CTRL4_C, bitand(val, 0xFD));
                end
            end
        end
        
        function value = setLPFBWModeGyro(obj,value)
            if obj.EnableGyroLPF
                % THE LPF bandwidth depend on the mode value and ODR
                if obj.GyroscopeODR>1666 &&  value>3
                    % for higher ODR only value < 3 available
                    value = 3;
                end
                switch value
                    case 0
                        ByteMask_CTRL6_C  = 0x00;
                    case 1
                        ByteMask_CTRL6_C  = 0x01;
                    case 2
                        ByteMask_CTRL6_C = 0x02;
                    case 3
                        ByteMask_CTRL6_C  = 0x03;
                        % need to look into accel ODR dependency
                    case 4
                        ByteMask_CTRL6_C  = 0x04;
                    case 5
                        ByteMask_CTRL6_C  = 0x05;
                    case 6
                        ByteMask_CTRL6_C = 0x06;
                    case 7
                        ByteMask_CTRL6_C  = 0x07;
                    otherwise
                        ByteMask_CTRL6_C  = 0x00;
                        value = 0;
                end
                val = readRegister(obj.Device, obj.CTRL6_C);
                writeRegister(obj.Device,obj.CTRL6_C, bitor(bitand(val, 0xF8), ByteMask_CTRL6_C));
            end
        end
    end
end