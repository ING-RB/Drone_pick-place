classdef (Hidden) imuSensor < fusion.internal.IMUSensorBase
%   This class is for internal use only. It may be removed in the future.     
%IMUSENSOR Simulink version of the imuSensor
    
%   Copyright 2019-2023 The MathWorks, Inc. 

%#codegen

    properties (Nontunable, Dependent)
        % Dependent property for reference frame. ReferenceFrame property is hidden, 
        % constructor-only, but exposed through this dependent version.
        DispRefFrame
        
        % Double precision seed that will be cast to uint32
        SeedDouble
    end
    
    properties 
        % Magnetic field properties in NED and ENU. Use isInactivePropertyImpl
        % to swap between the two. This will give persistence to the value in each mode.
        MagneticFieldNED  = [27.5550 -2.4169 -16.0849];
        MagneticFieldENU  = [-2.4169 27.5550 16.0849];

        % Actual magnetic field property for computation
        MagneticField
    end
    
    properties (Constant, Hidden)
        DispRefFrameSet = matlab.system.StringSet({'ENU', 'NED'}); 
        AccelParamsNoiseTypeSet = matlab.system.StringSet({'double-sided', 'single-sided'});
        GyroParamsNoiseTypeSet = matlab.system.StringSet({'double-sided', 'single-sided'});
        MagParamsNoiseTypeSet = matlab.system.StringSet({'double-sided', 'single-sided'});
        TemperatureSet = matlab.system.SourceSet({'PropertyOrInput', ...
            'SystemBlock', 'TemperaturePort', 1, "Temperature"});
        MagneticFieldSet = matlab.system.SourceSet({'PropertyOrInput', ...
            'SystemBlock', 'MagneticFieldPort', 2, "Magnetic" + newline + "Field"});
    end

    properties
        % Unrolled accelparams
        AccelParamsMeasurementRange = Inf;
        AccelParamsResolution = 0;
        AccelParamsConstantBias = [0 0 0];
        AccelParamsAxesMisalignment = 100*eye(3);
        AccelParamsNoiseDensity = [0 0 0];
        AccelParamsBiasInstability = [0 0 0];
        AccelParamsBiasInstabilityNumerator = fractalcoef().Numerator;
        AccelParamsBiasInstabilityDenominator = fractalcoef().Denominator;
        AccelParamsRandomWalk = [0 0 0];
        AccelParamsTemperatureBias = [0 0 0];
        AccelParamsTemperatureScaleFactor = [0 0 0];
       
        % Unrolled gyroparams
        GyroParamsMeasurementRange = Inf;
        GyroParamsResolution = 0;
        GyroParamsConstantBias = [0 0 0];
        GyroParamsAxesMisalignment = 100*eye(3);
        GyroParamsNoiseDensity = [0 0 0];
        GyroParamsBiasInstability = [0 0 0];
        GyroParamsBiasInstabilityNumerator = fractalcoef().Numerator;
        GyroParamsBiasInstabilityDenominator = fractalcoef().Denominator;
        GyroParamsRandomWalk = [0 0 0];
        GyroParamsTemperatureBias = [0 0 0];
        GyroParamsTemperatureScaleFactor = [0 0 0];
        GyroParamsAccelerationBias = [0 0 0];
       
        % Unrolled magparams
        MagParamsMeasurementRange = Inf;
        MagParamsResolution = 0;
        MagParamsConstantBias = [0 0 0];
        MagParamsAxesMisalignment = 100*eye(3);
        MagParamsNoiseDensity = [0 0 0];
        MagParamsBiasInstability = [0 0 0];
        MagParamsBiasInstabilityNumerator = fractalcoef().Numerator;
        MagParamsBiasInstabilityDenominator = fractalcoef().Denominator;
        MagParamsRandomWalk = [0 0 0];
        MagParamsTemperatureBias = [0 0 0];
        MagParamsTemperatureScaleFactor = [0 0 0];
        
    end

    properties (Nontunable)
        AccelParamsNoiseType = 'double-sided';
        GyroParamsNoiseType = 'double-sided';
        MagParamsNoiseType = 'double-sided';
        % TemperaturePort Specify temperature from input port
        TemperaturePort (1,1) logical = false;
        % MagneticFieldPort Specify magnetic field from input port
        MagneticFieldPort (1,1) logical = false;
    end
    
    methods
        function obj = imuSensor(varargin)
            setProperties(obj, nargin, varargin{:});
            obj.RandomStream = 'mt19937ar with seed';
            updateMF(obj, obj.MagneticFieldNED); % default
        end
        
        
        function set.MagneticField(obj, val)
            validateattributes(val,{'single','double'}, ...
                {'real','size',[1,3],'finite'}, ...
                '', ...
                'MagneticField');
            obj.MagneticField = val;
        end

        function set.MagneticFieldNED(obj, val)
            validateattributes(val,{'single','double'}, ...
                {'real','size',[1,3],'finite'}, ...
                '', ...
                'MagneticFieldNED');
            updateMF(obj, val);
       end
        function set.MagneticFieldENU(obj, val)
            validateattributes(val,{'single','double'}, ...
                {'real','size',[1,3],'finite'}, ...
                '', ...
                'MagneticFieldENU');
            updateMF(obj, val);
        end
        
        function set.DispRefFrame(obj, val)
            obj.ReferenceFrame = val;
        end       

        function v = get.DispRefFrame(obj)
            v = obj.ReferenceFrame;
        end   

        function set.SeedDouble(obj,val)
            obj.Seed = val;
        end
        
        function v = get.SeedDouble(obj)
            v = double(obj.Seed);
        end
        
    end
 
    methods (Access = protected)
        
        function s = getSampleTimeWrapped(obj)
            % Wrapper around getSampleTime. Overload this method to use in
            % MATLAB.
            ts = getSampleTime(obj);
            s = ts.SampleTime;
        end
        
        function setupImpl(obj, ~, ~, ~) 
            setupRandomStream(obj);
            
            ts = getSampleTimeWrapped(obj); 
            coder.internal.errorIf(ts==0,...
                'shared_sensorsim_common:SimulinkCommon:NoContinuousSampleTime', ...
                'IMU');
            sr = 1/ts;
            obj.pRefFrame = ...
                fusion.internal.frames.ReferenceFrame.getMathObject( ...
                obj.ReferenceFrame);
            
            ap = makeAccelParams(obj);
            obj.pAccel = createSystemObject(ap, ...
                'ReferenceFrame', obj.ReferenceFrame);
            obj.pAccel.SampleRate = sr;
            obj.pAccel.Temperature = obj.Temperature;

            gp = makeGyroParams(obj); 
            obj.pGyro = createSystemObject(gp);
            obj.pGyro.SampleRate = sr;
            obj.pGyro.Temperature = obj.Temperature;


            mp = makeMagParams(obj);
            obj.pMag = createSystemObject(mp);
            obj.pMag.SampleRate = sr;
            obj.pMag.Temperature = obj.Temperature;
        
        end
        
        function [a,g,m] = stepImpl(obj, la, av, o)
            % Pack into a quaternion as necessary
            if size(o,2) == 4 
                orient = quaternion(o);
            else
                orient = o;
            end
            [a,g,m] = stepImpl@fusion.internal.IMUSensorBase(obj, la, av, orient);
        end

        function tf = isInactivePropertyImpl(obj, prop)
            % Switch the dialog from NED to ENU Magnetic Field 
            tf = false;
            if strcmpi(prop, 'MagneticFieldENU')
                if strcmpi(obj.ReferenceFrame, 'NED') || obj.MagneticFieldPort
                    tf = true;
                end
            end
            if strcmpi(prop, 'MagneticFieldNED')
                if strcmpi(obj.ReferenceFrame, 'ENU') || obj.MagneticFieldPort
                    tf = true;
                end
            end
    
        end

        function validateInputsImpl(~, acceleration, angularvelocity, orientation)
            validateattributes(acceleration, {'single', 'double'}, ...
                {'real', 'finite', '2d', 'ncols', 3}, mfilename, 'Linear Acceleration', 1 );
            expectedDataType = class(acceleration);
            numSamples = size(acceleration, 1);
             validateattributes(angularvelocity, {expectedDataType}, ...
                {'real', 'finite', '2d', 'nrows', numSamples, 'ncols', 3}, ...
                mfilename, 'Angular Velocity', 2);
           
            opass = true;    
            switch ndims(orientation)
                case 2
                    sz = size(orientation);
                    if sz(2) == 4 % a quaternion
                        valsize = true;
                        validateattributes(orientation, {expectedDataType}, ...
                            {'real', 'finite', '2d', 'size', [numSamples 4]}, ...
                            mfilename, 'Orientation', 3);

                    elseif (sz(2) == 3) % a rotation matrix
                        valsize = true;
                        validateattributes(orientation, {expectedDataType}, ...
                            {'real', 'finite', '2d', 'size', [3 3] } );
                    else
                        valsize = false;
                    end
                    coder.internal.assert(valsize, ...
                        'shared_positioning:imuSensor:ExpectedOrientation');
                case 3
                    validateattributes(orientation, {expectedDataType}, ...
                        {'real', 'finite', '3d', 'size', [3 3 numSamples]}, ...
                        mfilename, 'Orientation', 3);
                otherwise
                    opass = false;
            end
            coder.internal.assert(opass, ...
                'shared_positioning:imuSensor:ExpectedOrientation');
        end    

        function icon = getIconImpl(~)
            %getIconImpl Define icon for System block
            filepath = fullfile(matlabroot, 'toolbox', 'shared', 'positioning', 'simulink', 'blockicons', 'IMU.dvg');
            icon = matlab.system.display.Icon(filepath);
        end
        
        function processTunedPropertiesImpl(obj)
            ap = makeAccelParams(obj);
            gp = makeGyroParams(obj);
            mp = makeMagParams(obj);
            if isChangedProperty(obj, 'Temperature')
                obj.pAccel.Temperature = obj.Temperature;
                updateSystemObject(ap, obj.pAccel);
                obj.pGyro.Temperature = obj.Temperature;
                updateSystemObject(gp, obj.pGyro);
                obj.pMag.Temperature = obj.Temperature;
                updateSystemObject(mp, obj.pMag);
            end
            if hasChangedAccelProperty(obj)
                updateSystemObject(ap, obj.pAccel);
            end
            if hasChangedGyroProperty(obj) 
                updateSystemObject(gp, obj.pGyro);
            end
            if hasChangedMagProperty(obj) 
                updateSystemObject(mp, obj.pMag);
            end
        end
        
        function num = getNumOutputsImpl(~)
            num = 3;
        end
        
        function n = getOutputNamesImpl(~)
            n = ["Accel", "Gyro", "Mag"];
        end
        
        function n = getInputNamesImpl(~)
            n = ["Linear" + newline + "Acceleration", ...
                "Angular" + newline + "Velocity", ...
                "Orientation"];
        end
        
        % Propagators
        function [s1, s2, s3] = getOutputSizeImpl(obj)
            ps = propagatedInputSize(obj, 1);
            numsamples = ps(1);
            [s1, s2, s3] = deal([numsamples 3]);
        end    
        
        function [dt1, dt2, dt3] = getOutputDataTypeImpl(obj)
           dt1 = propagatedInputDataType(obj,1);
           dt2 = dt1;
           dt3 = dt1;
        end
        function [tf1, tf2, tf3]  = isOutputComplexImpl(~)
            tf1 = false;
            tf2 = false;
            tf3 = false;
        end
        
        function [tf1, tf2, tf3] = isOutputFixedSizeImpl(~)
            tf1 = true;
            tf2 = true;
            tf3 = true;
        end
       
        % Helpers
        function val = hasGyro(~)
            val = true; 
        end
        
        function val = hasMag(~)
            val = true; 
        end

        function updateMF(obj, mf)
        % Update the Magnetic Field
            obj.MagneticField = mf;
        end
        
        function updateSeed(obj, sd)
            obj.Seed = uint32(sd);
        end

        function ap = makeAccelParams(obj)
            ap = accelparams;
            ap.MeasurementRange          = obj.AccelParamsMeasurementRange;
            ap.Resolution                = obj.AccelParamsResolution;
            ap.ConstantBias              = obj.AccelParamsConstantBias;
            ap.AxesMisalignment          = obj.AccelParamsAxesMisalignment;
            ap.NoiseDensity              = obj.AccelParamsNoiseDensity;
            ap.BiasInstability           = obj.AccelParamsBiasInstability;
            ap.RandomWalk                = obj.AccelParamsRandomWalk;
            ap.NoiseType                 = obj.AccelParamsNoiseType;
            ap.TemperatureBias           = obj.AccelParamsTemperatureBias;
            ap.TemperatureScaleFactor    = obj.AccelParamsTemperatureScaleFactor;

            ap.BiasInstabilityCoefficients = struct( ...
                "Numerator", obj.AccelParamsBiasInstabilityNumerator, ...
                "Denominator", obj.AccelParamsBiasInstabilityDenominator);
        end

        function gp = makeGyroParams(obj)
            gp = gyroparams;
            gp.MeasurementRange          = obj.GyroParamsMeasurementRange;
            gp.Resolution                = obj.GyroParamsResolution;
            gp.ConstantBias              = obj.GyroParamsConstantBias;
            gp.AxesMisalignment          = obj.GyroParamsAxesMisalignment;
            gp.NoiseDensity              = obj.GyroParamsNoiseDensity;
            gp.BiasInstability           = obj.GyroParamsBiasInstability;
            gp.RandomWalk                = obj.GyroParamsRandomWalk;
            gp.NoiseType                 = obj.GyroParamsNoiseType;
            gp.TemperatureBias           = obj.GyroParamsTemperatureBias;
            gp.TemperatureScaleFactor    = obj.GyroParamsTemperatureScaleFactor;
            gp.AccelerationBias          = obj.GyroParamsAccelerationBias;

            gp.BiasInstabilityCoefficients = struct( ...
                "Numerator", obj.GyroParamsBiasInstabilityNumerator, ...
                "Denominator", obj.GyroParamsBiasInstabilityDenominator);
        end

        function mp = makeMagParams(obj)
            mp = magparams;
            mp.MeasurementRange          = obj.MagParamsMeasurementRange;
            mp.Resolution                = obj.MagParamsResolution;
            mp.ConstantBias              = obj.MagParamsConstantBias;
            mp.AxesMisalignment          = obj.MagParamsAxesMisalignment;
            mp.NoiseDensity              = obj.MagParamsNoiseDensity;
            mp.BiasInstability           = obj.MagParamsBiasInstability;
            mp.RandomWalk                = obj.MagParamsRandomWalk;
            mp.NoiseType                 = obj.MagParamsNoiseType;
            mp.TemperatureBias           = obj.MagParamsTemperatureBias;
            mp.TemperatureScaleFactor    = obj.MagParamsTemperatureScaleFactor;

            mp.BiasInstabilityCoefficients = struct( ...
                "Numerator", obj.MagParamsBiasInstabilityNumerator, ...
                "Denominator", obj.MagParamsBiasInstabilityDenominator);
        end

        function tf = hasChangedAccelProperty(obj)
            tf = any(isChangedProperty(obj, {...
                'AccelParamsMeasurementRange', ...
                'AccelParamsResolution', ...
                'AccelParamsConstantBias', ...
                'AccelParamsAxesMisalignment', ...
                'AccelParamsNoiseDensity', ...
                'AccelParamsBiasInstability', ...
                'AccelParamsBiasInstabilityNumerator', ...
                'AccelParamsBiasInstabilityDenominator', ...
                'AccelParamsRandomWalk', ...
                'AccelParamsTemperatureBias', ...
                'AccelParamsTemperatureScaleFactor'}));
        end

        function tf = hasChangedGyroProperty(obj)
            tf = any(isChangedProperty(obj, {...
                'GyroParamsMeasurementRange', ...
                'GyroParamsResolution', ...
                'GyroParamsConstantBias', ...
                'GyroParamsAxesMisalignment', ...
                'GyroParamsNoiseDensity', ...
                'GyroParamsBiasInstability', ...
                'GyroParamsBiasInstabilityNumerator', ...
                'GyroParamsBiasInstabilityDenominator', ...
                'GyroParamsRandomWalk', ...
                'GyroParamsTemperatureBias', ...
                'GyroParamsTemperatureScaleFactor', ...
                'GyroParamsAccelerationBias'}));
        end

        function tf = hasChangedMagProperty(obj)
            tf = any(isChangedProperty(obj, {...
                'MagParamsMeasurementRange', ...
                'MagParamsResolution', ...
                'MagParamsConstantBias', ...
                'MagParamsAxesMisalignment', ...
                'MagParamsNoiseDensity', ...
                'MagParamsBiasInstability', ...
                'MagParamsBiasInstabilityNumerator', ...
                'MagParamsBiasInstabilityDenominator', ...
                'MagParamsRandomWalk', ...
                'MagParamsTemperatureBias', ...
                'MagParamsTemperatureScaleFactor'}));
        end
  
    end
    
    methods (Static, Hidden, Access=protected)
        function header = getHeaderImpl
            m1 = string(lookupDesc('BlockHeader'));
            m2 = string(lookupDesc('BlockDesc'));
            % We do not translate block names. Okay to have Title in English.
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', 'IMU', ...
                'ShowSourceLink', false, ...
                'Text', ...
                m1+ newline + newline + ...
                m2);
        end

        function groups = getPropertyGroupsImpl
            refFrame = matlab.system.display.internal.Property(...
                'DispRefFrame',  'Description', ...
                lookupDesc('DispRefFrame'), 'StringSetValues', ...
                {'ENU', 'NED'}, 'Default', 'NED');
         
            mainParams = matlab.system.display.Section('Title', '',...
                'PropertyList', {refFrame}, ...
                'DependOnPrivatePropertyList', {'DispRefFrame'});
            
            tempPortProp = matlab.system.display.internal.Property( ...
                'TemperaturePort', 'Description', ...
                getString(message("shared_positioning:imuSensor:TemperaturePort")));
            tempProp = matlab.system.display.internal.Property(...
                'Temperature', 'Description', ...
                [ lookupDesc('Temperature')  ' (' char(176) 'C' ')']);
            mfPortProp = matlab.system.display.internal.Property( ...
                'MagneticFieldPort', 'Description', ...
                getString(message("shared_positioning:imuSensor:MagneticFieldPort")));
            mfENU = matlab.system.display.internal.Property(...
                'MagneticFieldENU', 'Description', ...
                lookupDesc('MagneticFieldENU'));
            mfNED = matlab.system.display.internal.Property(...
                'MagneticFieldNED', 'Description', ...
                lookupDesc('MagneticFieldNED'));
             
            envParams =  matlab.system.display.Section('Title', ...
                lookupDesc('EnvSection'), 'PropertyList', ...
                {tempPortProp, tempProp, mfPortProp, mfNED, mfENU});
            
            sd = matlab.system.display.internal.Property(...
                'SeedDouble', 'Description', lookupDesc('Seed'), ...
                'Default', '67');
            
            rnd = matlab.system.display.Section(...
                'Title', lookupDesc('Randomization'), ...
                'PropertyList', {sd}, ...
                'DependOnPrivatePropertyList', {'SeedDouble'});
            
            paramGroup =  matlab.system.display.SectionGroup(...
                'Title', lookupDesc('Parameters'), ...
                'Sections', [mainParams, envParams rnd]);
            
            ap = accelparams;
            prefix = 'AccelParams';
            accelGroup = makeSensorTab(prefix, ap, 'Accelerometer');
            
            gp = gyroparams;
            prefix = 'GyroParams';
            gyroGroup = makeSensorTab(prefix, gp, 'Gyroscope');
            
            % Add to gyro prop
            gyroGroup.Sections(1).PropertyList{end + 1} = ...
                makeProp([prefix, 'AccelerationBias'], gp, prefix);
            
            mp = magparams;
            prefix = 'MagParams';
            magGroup = makeSensorTab(prefix, mp, 'Magnetometer');
            
            
            groups = [ paramGroup accelGroup gyroGroup magGroup ];
        end
    end
    
    
    methods (Hidden, Static)
        function flag = isAllowedInSystemBlock
            flag = true;
        end
    end
end

function p = makeProp(prop, param, prefix)
    rootprop = erase(prop, prefix);
    propunits = param.(rootprop + "Units");
    p = matlab.system.display.internal.Property(prop, 'Description', ...
        [lookupDesc(prop) ' (' propunits ')']);
end

function txt = lookupDesc(desc)
%LOOKUPDESC Find the property description in the message catalog
    m = message("shared_positioning:imuSensor:" + desc);
    txt = m.getString;
end

function g = makeSensorTab(prefix, ap, name)
    mrange = makeProp([prefix 'MeasurementRange'], ap, prefix);
    mres = makeProp([prefix 'Resolution'],  ap, prefix);
    mbias = makeProp([prefix 'ConstantBias'], ap, prefix);
    maxes = makeProp([prefix 'AxesMisalignment'], ap, prefix);

    basic = matlab.system.display.Section('Title', '', 'PropertyList', ...
        {mrange, mres, mbias, maxes});

    ndensity = makeProp([prefix 'NoiseDensity'], ap, prefix);
    nbias = makeProp([prefix 'BiasInstability'], ap, prefix);
    nbiasnum = matlab.system.display.internal.Property( ...
        [prefix 'BiasInstabilityNumerator'], 'Description', ...
        lookupDesc([prefix 'BiasInstabilityNumerator']));
    nbiasden = matlab.system.display.internal.Property( ...
        [prefix 'BiasInstabilityDenominator'], 'Description', ...
        lookupDesc([prefix 'BiasInstabilityDenominator']));
    nwalk = makeProp([prefix 'RandomWalk'],  ap, prefix);
    ntype = matlab.system.display.internal.Property(...
        [prefix 'NoiseType'],  'Description', ...
        lookupDesc([prefix 'NoiseType']), 'StringSetValues', ...
        {'double-sided', 'single-sided'}, 'Default', 'double-sided');

    noise = matlab.system.display.Section('Title', lookupDesc('NoiseTab'), ...
        'PropertyList', {ndensity, nbias, nbiasnum, nbiasden, nwalk, ntype});

    tbias = makeProp([prefix 'TemperatureBias'],  ap, prefix);
    tscale = makeProp([prefix 'TemperatureScaleFactor'], ap, prefix);

    temperature = matlab.system.display.Section('Title', ...
        lookupDesc('TemperatureEffects'), 'PropertyList', ...
        {tbias, tscale});

    g = matlab.system.display.SectionGroup(...
        'Title', lookupDesc(name), ...
        'Sections', [basic, noise, temperature]);

end


