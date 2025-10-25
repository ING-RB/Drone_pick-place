classdef gpsSensor < fusion.internal.GPSSensorBase
    %This function is for internal use only. It may be removed in the future.

    %gpsSensor Defines the input/output spec and appearance of the GPS
    %block

    %   Copyright 2021-2024 The MathWorks, Inc.

    %#codegen

    properties (Nontunable, Hidden)
        SampleRate
    end

    properties (Dependent, Nontunable)
        % Dependent property for reference frame. ReferenceFrame property is hidden,
        % constructor-only, but exposed through this dependent version.
        DispRefFrame

        % Double precision seed that will be cast to uint32
        SeedDouble
    end

    properties (Constant, Hidden)
        DispRefFrameSet = matlab.system.StringSet({'ENU', 'NED'});
    end

    methods
        function obj = gpsSensor(varargin)
            %gpsSensor constructor

            setProperties(obj, nargin, varargin{:});
            % Simulink block is always using mt19937ar randomization for
            % repeatability in code generation
            obj.RandomStream = 'mt19937ar with seed';
        end

        function st = getSampleTimeWrapper(obj)
            %getSampleTimeWrapper Wrap around getSampleTime method to allow
            %overrides in inherited class for testing purpose
            st = getSampleTime(obj);
        end

        function sr = get.SampleRate(obj)
            %SampleRate is defined based on system object sample time
            ts = getSampleTimeWrapper(obj);
            sr = 1/ts.SampleTime;
        end

        function set.SeedDouble(obj, x)
            %SeedDouble setter

            %Internal seed is uint32
            obj.Seed = uint32(x);
        end

        function x = get.SeedDouble(obj)
            %SeedDouble getter

            %Appearance is double
            x = double(obj.Seed);
        end

        function set.DispRefFrame(obj, val)
            %DispRefFrame setter

            obj.ReferenceFrame = val;
        end

        function v = get.DispRefFrame(obj)
            %DispRefFrame getter
            v = obj.ReferenceFrame;
        end
    end

    methods(Access = protected)

        function [s1, s2, s3, s4] = getOutputSizeImpl(obj)
            % output size is based on first input

            ps = propagatedInputSize(obj, 1);
            numsamples = ps(1);
            [s1, s2] = deal([numsamples 3]);
            [s3, s4] = deal([numsamples 1]);
        end

        function [dt1, dt2, dt3, dt4] = getOutputDataTypeImpl(obj)
            % output data type is based on first input
            dt1 = propagatedInputDataType(obj,1);
            [dt2, dt3, dt4] = deal(dt1);
        end

        function [tf1, tf2, tf3, tf4]  = isOutputComplexImpl(~)
            % all outputs are real
            tf1 = false;
            tf2 = false;
            tf3 = false;
            tf4 = false;
        end

        function [tf1, tf2, tf3, tf4] = isOutputFixedSizeImpl(~)
            % all outputs are fixed size
            tf1 = true;
            tf2 = true;
            tf3 = true;
            tf4 = true;
        end

        function setupImpl(obj, pos, vel)
            % Perform one-time calculations, such as computing constants

            coder.internal.errorIf(~isfinite(obj.SampleRate),...
                'shared_sensorsim_common:SimulinkCommon:NoContinuousSampleTime', ...
                'GPS');
            setupImpl@fusion.internal.GPSSensorBase(obj, pos, vel);
        end

        function validateInputsImpl(~, pos, vel)
            % Validate inputs to the step method at initialization

            validateattributes(pos, {'single', 'double'}, ...
                {'real', 'finite', '2d', 'ncols', 3}, mfilename, 'Position', 1 );

            % data types for both inputs must match
            expectedDataType = class(pos);
            % number of rows for both inputs must match
            numSamples = size(pos, 1);
            validateattributes(vel, {expectedDataType}, ...
                {'real', 'finite', '2d', 'nrows', numSamples, 'ncols', 3}, ...
                mfilename, 'Velocity', 2);

        end

        function num = getNumInputsImpl(~)
            % Define total number of inputs for system with optional inputs
            num = 2;
        end

        function num = getNumOutputsImpl(~)
            % Define total number of outputs
            num = 4;
        end

        function icon = getIconImpl(~)
            % Define icon for System block
            
            filepath = fullfile(matlabroot, 'toolbox', 'shared', 'sensorsim', 'gps', 'simulink', 'core', 'blockicons', 'GPS.dvg');
            icon = matlab.system.display.Icon(filepath);
        end

        function n = getOutputNamesImpl(~)
            % Output port labels
            n = ["LLA", "Velocity", "Groundspeed", "Course"];
        end

        function n = getInputNamesImpl(~)
            % Input port labels
            n = ["Position", ...
                "Velocity"];
        end
    end

    methods (Access = protected, Static, Hidden)
        function groups = getPropertyGroupsImpl()
            %getPropertyGroupsImpl Setup block mask groups

            % reference frame group
            refFrame = matlab.system.display.internal.Property(...
                'DispRefFrame',  'Description', ...
                lookupDesc('DispRefFrame'), 'StringSetValues', ...
                {'ENU', 'NED'}, 'Default', 'NED');

            ref = matlab.system.display.Section('Title', '',...
                'PropertyList', {refFrame}, ...
                'DependOnPrivatePropertyList', {'DispRefFrame'});

            % parameter group
            referenceLocation = makeProp('ReferenceLocation');
            horizontalPosAcc= makeProp('HorizontalPositionAccuracy');
            verticalPosAcc = makeProp('VerticalPositionAccuracy');
            velAcc = makeProp('VelocityAccuracy');
            decayFactor = matlab.system.display.internal.Property('DecayFactor', 'Description', lookupDesc('DecayFactor'));

            positionFormat = matlab.system.display.internal.Property(...
                'PositionInputFormat',  'Description', ...
                lookupDesc('PositionInputFormat'), 'StringSetValues', ...
                {'Local', 'Geodetic'}, 'Default', 'Local');

            main = matlab.system.display.Section(...
                'Title', lookupDesc('Parameters'), ...
                'PropertyList', {positionFormat, referenceLocation, horizontalPosAcc, verticalPosAcc, velAcc, decayFactor});

            % randomization group
            sd = matlab.system.display.internal.Property(...
                'SeedDouble', 'Description', lookupDesc('Seed'), ...
                'UseClassDefault', false, 'Default', '67' );

            rnd = matlab.system.display.Section(...
                'Title', lookupDesc('Randomization'), ...
                'PropertyList', {sd}, ...
                'DependOnPrivatePropertyList', {'SeedDouble'});

            % combine three groups
            groups = [ref, main, rnd];
        end

        function header = getHeaderImpl
            %getHeaderImpl Create block header text
            blockTitle = string(lookupDesc('MaskTitle'));
            h1 = string(lookupDesc('MaskDescH1'));
            main = string(lookupDesc('MaskDescMain'));
            howto = string(lookupDesc('MaskDescHowTo'));
            io = string(lookupDesc('MaskDescIO'));
            header = matlab.system.display.Header(mfilename('class'), ...
                'Title', blockTitle, ...
                'ShowSourceLink', false, ...
                'Text', ...
                h1 + newline + newline +  ....
                main + newline + newline + ...
                howto + newline + newline + ...
                io);
        end

    end
end

function p = makeProp(prop)
% Add a new property
propunits = gpsSensor.(prop + "Units");
p = matlab.system.display.internal.Property(prop, 'Description', [lookupDesc(prop) ' (' propunits ')']);
end

function txt = lookupDesc(desc)
%LOOKUPDESC Find the property description in the message catalog
m = message("shared_sensorsim_gps:gpsSensor:" + desc);
txt = m.getString;
end
