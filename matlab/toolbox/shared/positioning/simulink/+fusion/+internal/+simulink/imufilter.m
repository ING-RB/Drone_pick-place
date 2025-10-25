classdef (Hidden) imufilter < ...
        fusion.internal.simulink.IMUFilterSimulinkBase
%   This class is for internal use only. It may be removed in the future.
%IMUFILTER  Simulink version of the imufilter.
%   The IMUFILTER class implements an orientation estimation system from
%   accelerometer and gyroscope readings for use in MATLAB System Block.

%   Copyright 2023 The MathWorks, Inc.

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

    % Setter and Getter
    methods
        % Propagate DispRefFrame to ReferenceFrame
        function set.DispRefFrame(obj, val)
            obj.ReferenceFrame = val;
        end

        function v = get.DispRefFrame(obj)
            v = obj.ReferenceFrame;
        end
    end

    methods
        function obj = imufilter(varargin)
            setProperties(obj, nargin, varargin{:});
        end
    end

    methods (Access = protected)
        function s = getSampleTimeWrapped(obj)
            % Wrapper around getSampleTime. Overload this method to use
            % in MATLAB.
            ts = getSampleTime(obj);
            s = ts.SampleTime;
        end

        function setupImpl(obj, accelIn, gyroIn)
            ts = getSampleTimeWrapped(obj);
            coder.internal.errorIf(ts == 0, ...
               'shared_sensorsim_common:SimulinkCommon:NoContinuousSampleTime', ...
               'imufilter');
            obj.SampleRate = 1./ts;
            setupImpl@fusion.internal.simulink.IMUFilterSimulinkBase(...
                                                obj, accelIn, gyroIn);
        end

        function [orientOut, angvel] = stepImpl(obj, accelIn, gyroIn)
            [orient, angvel] = stepImpl@ ...
                fusion.internal.simulink.IMUFilterSimulinkBase(...
                                                obj, accelIn, gyroIn);

            % Unpack the quaternion if necessary
            if strcmpi(obj.OrientationFormat, 'quaternion')
                orientOut = compact(orient);
            else
                orientOut = orient;
            end
        end
    end

    % Simulink block icon
    methods (Access = protected)
        function icon = getIconImpl(~)
            %getIconImpl Define icon for System block
            filepath = fullfile(matlabroot, 'toolbox', 'shared', ...
                        'positioning', 'simulink', 'blockicons', ...
                        'IMUFilter.svg');
            icon = matlab.system.display.Icon(filepath);
        end
    end

    % Input and Output: name, type, and size
    methods (Access = protected)
        function n = getInputNamesImpl(~)
            n = ["Accel", ...
                "Gyro"];
        end

        function num = getNumOutputsImpl(~)
            num = 2;
        end

        function n = getOutputNamesImpl(~)
            n = ["Orientation", "Angular" + newline + "Velocity"];
        end
    end

    % Propagators
    methods (Access = protected)
        function [s1, s2] = getOutputSizeImpl(obj)
            ps = propagatedInputSize(obj, 1);
            numsamples = ps(1);
            validateFrameSize(obj, ps);

            % Orientation
            df = obj.DecimationFactor;
            nout = numsamples/df;
            % If orientation output is in quaternion format then size of
            % output if N-by-4
            if strcmpi(obj.OrientationFormat, 'quaternion')
                s1 = [nout, 4];
            else
            % If orientation output is in rotation matrix then size of
            % output if 3-by-3-by-N
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

    % Mask
    methods (Access = protected, Static, Hidden)
        function groups = getPropertyGroupsImpl
            refFrame = matlab.system.display.internal.Property( ....
                'DispRefFrame', ...
                'Description', lookupDesc('DispRefFrame'), ...
                'StringSetValues', {'NED', 'ENU'}, 'Default', 'NED');
            orientFormat = matlab.system.display.internal.Property(...
                'OrientationFormat', ...
                'Description', lookupDesc('OrientationFormat'));
            decimFactor = matlab.system.display.internal.Property(...
                'DecimationFactor', ...
                'Description', lookupDesc('DecimationFactor'));
            initialcov = matlab.system.display.internal.Property(...
                'InitialProcessNoise', ...
                'Description', lookupDesc('InitialProcessNoise'), ...
                'UseClassDefault', false, ...
                'Default', 'imufilter.defaultProcessNoise', ....
                'ToolTipText', '9-by-9 matrix');

            filterSettings = matlab.system.display.Section(...
                'Title', lookupDesc('imufilterFilterSettings'), ...
                'PropertyList', {refFrame, orientFormat, ...
                                 decimFactor, initialcov}, ...
                'DependOnPrivatePropertyList', {'DispRefFrame'});

            accelNoise     = makeProp('AccelerometerNoise');
            gyroNoise      = makeProp('GyroscopeNoise');
            gyroDriftNoise = makeProp('GyroscopeDriftNoise');
            sensor = matlab.system.display.Section(...
                'Title', lookupDesc('MeasurementNoise'), ...
                'PropertyList',{accelNoise, gyroNoise, gyroDriftNoise});

            linAccelNoise = makeProp('LinearAccelerationNoise');
            linAccelDecayFactor = ...
                matlab.system.display.internal.Property(...
                'LinearAccelerationDecayFactor', 'Description', ...
                lookupDesc('LinearAccelerationDecayFactor') );
            env = matlab.system.display.Section(...
                'Title', lookupDesc('EnvironmentalNoise'), ...
                'PropertyList', {linAccelNoise,  linAccelDecayFactor});

            groups = [filterSettings, sensor, env];
        end

        % Simulink block description
        function header = getHeaderImpl
            heading = string(lookupDesc('imufilterBlockHeader'));
            blockDesc = string(lookupDesc('imufilterBlockDesc'));
            gainTuneDesc = string(lookupDesc('imufilterBlockTune'));

            % We don't translate block names, so okay to not use message 
            % catalog
            header = matlab.system.display.Header(mfilename('class'),...
                'Title', 'IMU Filter', ...
                'ShowSourceLink', false, ...
                'Text', ...
                heading + newline + newline + ...
                blockDesc + newline + newline + ...
                gainTuneDesc);
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
    propunits = imufilter.(prop + "Units");
    p = matlab.system.display.internal.Property(prop, ...
                'Description', [lookupDesc(prop) ' (' propunits ')']);
end

function txt = lookupDesc(desc)
%LOOKUPDESC Find the property description in the message catalog
    m = message("shared_positioning:internal:IMUFusionCommon:" + desc);
    txt = m.getString;
end