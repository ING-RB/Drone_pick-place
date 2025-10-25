classdef (Hidden) ahrsfilter < ...
        fusion.internal.simulink.AHRSFilterSimulinkBase
%   This class is for internal use only. It may be removed in the future. 
%AHRSFILTER  Simulink version of the ahrsfilter. 
%   The AHRSFILTER class implements an Attitude and Heading Reference
%   System for use in the MATLAB System Block.
    
%   Copyright 2019-2021 The MathWorks, Inc.        

    %#codegen
    
    
    properties (Nontunable, Dependent)
        % Reference frame. Dependent and just used for display. The real
        % one is hidden and constructor only so exposing through a
        % dependent property.
        DispRefFrame
    end
    
    properties (Constant, Hidden)
        DispRefFrameSet = matlab.system.StringSet({'NED', 'ENU'});
    end
    
    methods
        function obj = ahrsfilter(varargin)
            setProperties(obj, nargin, varargin{:});
        end

        % Propagate DispRefFrame to ReferenceFrame
        function set.DispRefFrame(obj, val)
            obj.ReferenceFrame = val;
        end
        function v = get.DispRefFrame(obj)
            v = obj.ReferenceFrame;
        end
    end
    
    methods (Access = protected)
        function num = getNumOutputsImpl(~)
            num = 2;
        end
        
        function n = getOutputNamesImpl(~)
            n = ["Orientation", "Angular" + newline + "Velocity"];
        end
        
        function n = getInputNamesImpl(~)
            n = ["Accel", ...
                "Gyro", ...
                "Mag"];
        end
        function icon = getIconImpl(~)
            %getIconImpl Define icon for System block
            filepath = fullfile(matlabroot, 'toolbox', 'shared', 'positioning', 'simulink', 'blockicons', 'AHRS.dvg');
            icon = matlab.system.display.Icon(filepath);
        end        
        function s = getSampleTimeWrapped(obj)
            % Wrapper around getSampleTime. Overload this method to use in
            % MATLAB.
            ts = getSampleTime(obj);
            s = ts.SampleTime;
        end
        
        function setupImpl(obj,  accelIn, gyroIn, magIn)
            ts = getSampleTimeWrapped(obj);
            coder.internal.errorIf(ts == 0,...
               'shared_sensorsim_common:SimulinkCommon:NoContinuousSampleTime', ...
                'AHRS');
            obj.SampleRate = 1./ts;
            setupImpl@fusion.internal.simulink.AHRSFilterSimulinkBase(obj, accelIn, gyroIn, magIn);
        end
        
        function [orientOut, av] = stepImpl(obj, accelIn, gyroIn, magIn)
            [orient, av] = stepImpl@fusion.internal.simulink.AHRSFilterSimulinkBase(obj, accelIn, gyroIn, magIn);

            % Unpack the quaternion if necessary
            if strcmpi(obj.OrientationFormat, 'quaternion') 
                orientOut = compact(orient);
            else
                orientOut = orient;
            end
            
        end
        
        % Propagators
        function [s1, s2] = getOutputSizeImpl(obj)
            ps = propagatedInputSize(obj, 1);
            numsamples = ps(1);
            validateFrameSize(obj, ps);
            
            % Orientation
            df = obj.DecimationFactor;
            nout = numsamples/df;
            if strcmpi(obj.OrientationFormat, 'quaternion')
                s1 = [nout, 4];
            else
                s1 = [3 3 nout];
            end
            % Angular velocity
            s2 = [nout 3];
        end    
        
        function [dt1, dt2] = getOutputDataTypeImpl(obj)
           dt1 = propagatedInputDataType(obj,1);
           dt2 = dt1;
        end
        function [tf1, tf2]  = isOutputComplexImpl(~)
            tf1 = false;
            tf2 = false;
        end
        
        function [tf1, tf2] = isOutputFixedSizeImpl(~)
            tf1 = true;
            tf2 = true;
        end
        
    end
    
    methods (Access = protected, Static, Hidden)
        function groups = getPropertyGroupsImpl
            refFrame = matlab.system.display.internal.Property( ....
                'DispRefFrame', 'Description', ...
                lookupDesc('DispRefFrame'), 'StringSetValues', ...
                {'NED', 'ENU'}, 'Default', 'NED');

            df = matlab.system.display.internal.Property(...
                'DecimationFactor', 'Description', ...
                lookupDesc('DecimationFactor'));
            icov = matlab.system.display.internal.Property(...
                'InitialProcessNoise', 'Description', ...
                lookupDesc('InitialProcessNoise'), 'UseClassDefault', false, ...
                'Default', 'ahrsfilter.defaultProcessNoise', ....
                'ToolTipText', '12-by-12 matrix');
            oFormat = matlab.system.display.internal.Property(...
                'OrientationFormat', 'Description', ...
                lookupDesc('OrientationFormat') );
            main = matlab.system.display.SectionGroup(...
                'Title', lookupDesc('Main'), ...
                'PropertyList', {refFrame, df, icov, oFormat}, ...
                'DependOnPrivatePropertyList', {'DispRefFrame'});
            
            an = makeProp('AccelerometerNoise');
            gn = makeProp('GyroscopeNoise');
            mn = makeProp('MagnetometerNoise');
            gdn = makeProp('GyroscopeDriftNoise');
            sensor = matlab.system.display.SectionGroup(...
                'Title', lookupDesc('MeasurementNoise'), ...
                'PropertyList', {an, gn, mn,gdn});
           
            lanoise = makeProp('LinearAccelerationNoise');
            mdnoise = makeProp('MagneticDisturbanceNoise');
            ladecay = matlab.system.display.internal.Property(...
                'LinearAccelerationDecayFactor', 'Description', ...
                lookupDesc('LinearAccelerationDecayFactor') );
            mddecay = matlab.system.display.internal.Property(...
                'MagneticDisturbanceDecayFactor', 'Description', ...
                lookupDesc('MagneticDisturbanceDecayFactor') );
            msf = makeProp('ExpectedMagneticFieldStrength');
            env = matlab.system.display.SectionGroup(...
                'Title', lookupDesc('EnvironmentalNoise'), ...
                'PropertyList', {lanoise,  mdnoise, ladecay,mddecay, msf});

            groups = [main, sensor, env];
        end

        function header = getHeaderImpl
            m1 = string(lookupDesc('AHRSBlockHeader'));
            m2 = string(lookupDesc('AHRSBlockDesc'));
            
            % We don't translate block names, so okay to not use message catalog
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', 'AHRS', ...
                'ShowSourceLink', false, ...
                'Text', ...
                m1 + newline + newline + ...
                m2 + newline);
        end
        
    end

    methods (Hidden, Static)
        function flag = isAllowedInSystemBlock
            flag = true;
        end
    end
    
end
    
function p = makeProp(prop)
% Add a new property
    propunits = ahrsfilter.(prop + "Units");
    p = matlab.system.display.internal.Property(prop, 'Description', [lookupDesc(prop) ' (' propunits ')']);
end

function txt = lookupDesc(desc)
%LOOKUPDESC Find the property description in the message catalog
    m = message("shared_positioning:internal:IMUFusionCommon:" + desc);
    txt = m.getString;
end
