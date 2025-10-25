classdef complementaryFilter < complementaryFilter
%   This class is for internal use only. It may be removed in the future.
%COMPLEMENTARYFILTER  Simulink version of the complementaryFilter.
%   The COMPLEMENTARYFILTER class implements an orientation estimation
%   system for use in the MATLAB System Block.

%   Copyright 2022 The MathWorks, Inc.

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

    methods (Access = protected)
        function s = getSampleTimeWrapped(obj)
            % Wrapper around getSampleTime. Overload this method to use in
            % MATLAB.
            ts = getSampleTime(obj);
            s = ts.SampleTime;
        end

        function setupImpl(obj, varargin)
            ts = getSampleTimeWrapped(obj);
            coder.internal.errorIf(ts == 0, ...
               'shared_sensorsim_common:SimulinkCommon:NoContinuousSampleTime', ...
               'ComplementaryFilter');
            obj.SampleRate = 1./ts;
            setupImpl@complementaryFilter(obj, varargin{:});
        end

        function [orientOut, angvel] = stepImpl(obj, varargin)
            [orient, angvel] = ...
                            stepImpl@complementaryFilter(obj, varargin{:});

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
                        'complementaryFilter.svg');
            icon = matlab.system.display.Icon(filepath);
        end
    end

    % Input and Output: name, type, and size
    methods (Access = protected)
        function n = getInputNamesImpl(obj)
            n = ["Accel", ...
                "Gyro"];
            if obj.HasMagnetometer
                n = [n, "Mag"];
            end
        end

        function n = getOutputNamesImpl(~)
            n = ["Orientation", "Angular" + newline + "Velocity"];
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

    % Propagators
    methods (Access = protected)
        function [s1, s2] = getOutputSizeImpl(obj)
            ps = propagatedInputSize(obj, 1);
            numsamples = ps(1);

            % Orientation
            if strcmpi(obj.OrientationFormat, 'quaternion')
                s1 = [numsamples, 4];
            else
                s1 = [3 3 numsamples];
            end
            % Angular velocity
            s2 = [numsamples 3];
        end

        function [dt1, dt2] = getOutputDataTypeImpl(obj)
           dt1 = propagatedInputDataType(obj,1);
           dt2 = dt1;
        end
    end

    methods (Access = protected, Static, Hidden)
        % Property group and description
        function groups = getPropertyGroupsImpl
            % Filter Settings
            refFrame = matlab.system.display.internal.Property( ....
                'DispRefFrame', ...
                'Description', lookupDesc('DispRefFrame'), ...
                'StringSetValues', {'NED', 'ENU'}, 'Default', 'NED');
            orientFormat = matlab.system.display.internal.Property(...
                'OrientationFormat', ...
                'Description', lookupDesc('OrientationFormat'));
            filterSettings = matlab.system.display.Section( ...
                'Title', lookupDesc('FilterSettings'), ...
                'PropertyList', {refFrame, orientFormat}, ...
                'DependOnPrivatePropertyList', {'DispRefFrame'});

            % Measurement Parameters
            % Accelerometer Gain Input
            accGain = matlab.system.display.internal.Property( ...
                'AccelerometerGain', ...
                'Description', lookupDesc('AccelerometerGain'));

            % Magnetometer Gain Inputs
            inp =  matlab.system.display.internal.Property( ...
                'HasMagnetometer', ...
                'Description', lookupDesc('HasMagnetometer'));
            magGain = matlab.system.display.internal.Property( ...
                'MagnetometerGain', ...
                'Description', lookupDesc('MagnetometerGain'));

            measurementParameters = matlab.system.display.Section( ...
                'Title', lookupDesc('MeasurementParameters'), ...
                'PropertyList', {accGain, inp, magGain});

            groups = [filterSettings, measurementParameters];
        end

        % Simulink block description
        function header = getHeaderImpl
            heading = string(lookupDesc('CompFilterBlockHeader'));
            blockDesc = string(lookupDesc('CompFilterBlockDesc'));
            gainTuneDesc = string(lookupDesc('CompFilterBlockTune'));

            % We don't translate block names, so okay to not use message 
            % catalog
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', 'Complementary Filter', ...
                'ShowSourceLink', false, ...
                'Text', ...
                heading + newline + newline + ...
                blockDesc + newline + newline + ...
                gainTuneDesc);
        end
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

    methods (Hidden, Static)
        function flag = isAllowedInSystemBlock
            flag = true;
        end
    end
end

function txt = lookupDesc(desc)
%LOOKUPDESC Find the property description in the message catalog
    m = message("shared_positioning:internal:IMUFusionCommon:" + desc);
    txt = m.getString;
end