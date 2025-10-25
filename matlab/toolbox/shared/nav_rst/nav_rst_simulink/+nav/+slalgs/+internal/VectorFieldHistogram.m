classdef VectorFieldHistogram < nav.algs.internal.VectorFieldHistogramBase
    %This class is for internal use only. It may be removed in the future.

    %VECTORFIELDHISTOGRAM Avoid obstacles using vector field histogram
    %   This is the Simulink System Block implementation of the
    %   MATLAB-based algorithm.
    %
    %   Example:
    %
    %       % Create a vector field histogram object
    %       vfh = nav.slalgs.internal.VectorFieldHistogram;
    %
    %       % Example laser scan data input
    %       ranges = 10*ones(1, 300);
    %       ranges(1, 130:170) = 1.0;
    %       angles = linspace(-pi/2, pi/2, 300);
    %       targetDir = 0;
    %
    %       % Compute obstacle-free steering direction
    %       steeringDir = step(vfh, scan, targetDir)
    %
    %   See also controllerVFH.

    %   Copyright 2017-2019 The MathWorks, Inc.

    %#codegen

    methods (Access = protected)
        function [scan, target, classOfRanges] = parseAndValidateStepInputs(~, ranges, angles, target)
        %parseAndValidateStepInputs Validate inputs to step function

        % Scan as ranges and angles
            scan = robotics.internal.validation.validateLidarScan(...
                ranges, angles, 'step', 'ranges', 'angles');
            classOfRanges = class(scan.Ranges);

            % Validate the target direction
            validateattributes(target, {'double', 'single'}, {'nonnan', 'real', ...
                                'scalar', 'nonempty', 'finite'}, 'step', 'target direction');

        end

        function validateInputsImpl(obj, varargin)
        %validateInputsImpl Validate inputs before setupImpl is called
            [scan, target, classOfRanges] = obj.parseAndValidateStepInputs(varargin{:});

            isDataTypeEqual = isequal(classOfRanges, class(target));

            coder.internal.errorIf(~isDataTypeEqual, ...
                                   'nav:navalgs:vfh:DataTypeMismatch', ...
                                   classOfRanges, class(scan.Angles), class(target));
        end

        function outSize = getOutputSizeImpl(~)
        %getOutputSizeImpl Return size for each output port

        % Steering direction type is scalar
            outSize = 1;
        end

        function outType = getOutputDataTypeImpl(obj)
        %getOutputDataTypeImpl Return data type for each output port

            outType = propagatedInputDataType(obj,1);
        end

        function outComplex = isOutputComplexImpl(~)
        %isOutputComplexImpl Return true for each output port with complex data

        % Steering direction is real
            outComplex = false;
        end

        function c1 = isOutputFixedSizeImpl(~)
        %isOutputFixedSizeImpl Return true for each output port with fixed size

        % SteerDir has fixed size
            c1 = true;
        end

        function [name1, name2, name3] = getInputNamesImpl(~)
        %getInputNamesImpl Return input port names for System block
            name1 = 'Ranges';
            name2 = 'Angles';
            name3 = 'TargetDir';
        end

        function outNames = getOutputNamesImpl(~)
        %getOutputNamesImpl Return output port names for System block
            outNames = 'SteerDir';
        end

        function icon = getIconImpl(~)
        %getIconImpl Define icon for System block
            filepath = fullfile(matlabroot, 'toolbox', 'shared', 'nav_rst', 'nav_rst_simulink', 'blockicons', 'VFHIcon.dvg');
            icon = matlab.system.display.Icon(filepath);
        end

        function num = getNumInputsImpl(~)
        %getNumInputsImpl Get number of inputs
            num = 3;
        end

        function num = getNumOutputsImpl(~)
        %getNumOutputsImpl Define number of outputs for system with optional outputs
            num = 1;
        end

        function flag = isInputSizeMutableImpl(~,index)
        %isInputSizeMutableImpl Mutable input size status
        %   This function will be called once for each input of the
        %   system block.
        %   First two inputs, i.e. ranges and angles are variable sized
        %   signals.
            if (index == 1 || index  == 2)
                flag = true;
            else
                flag = false;
            end
        end
    end

    methods(Static, Access = protected)
        % Note that this is ignored for the mask-on-mask
        function header = getHeaderImpl
        %getHeaderImpl Create mask header
            header = matlab.system.display.Header('nav.slalgs.internal.VectorFieldHistogram', ...
                                                  'Title', message('nav:navslalgs:vfh:VFHTitle').getString, ...
                                                  'Text', message('nav:navslalgs:vfh:VFHDescription').getString, ...
                                                  'ShowSourceLink', false);
        end

        function groups = getPropertyGroupsImpl
        %getPropertyGroupsImpl Display getPropertyGroups parameters with groups and tabs

            propNumAngularSectors = matlab.system.display.internal.Property('NumAngularSectors',...
                'Description',getString(message('nav:navslalgs:vfh:NumAngularSectorsDisplayName')));
            propDistanceLimits = matlab.system.display.internal.Property('DistanceLimits',...
                'Description',getString(message('nav:navslalgs:vfh:DistanceLimitsDisplayName')));
            propHistogramThresholds = matlab.system.display.internal.Property('HistogramThresholds',...
                'Description',getString(message('nav:navslalgs:vfh:HistogramThresholdsDisplayName')));            

            valueGroup = matlab.system.display.Section(...
                'Title', message('nav:navslalgs:vfh:HistogramParameters').getString, 'PropertyList', ...
                {propNumAngularSectors, propDistanceLimits, propHistogramThresholds});

            propRobotRadius = matlab.system.display.internal.Property('RobotRadius',...
                'Description',getString(message('nav:navslalgs:vfh:RobotRadiusDisplayName')));
            propSafetyDistance = matlab.system.display.internal.Property('SafetyDistance',...
                'Description',getString(message('nav:navslalgs:vfh:SafetyDistanceDisplayName')));
            propMinTurningRadius = matlab.system.display.internal.Property('MinTurningRadius',...
                'Description',getString(message('nav:navslalgs:vfh:MinTurningRadiusDisplayName')));

            thresholdGroup = matlab.system.display.Section(...
                'Title', message('nav:navslalgs:vfh:VehicleParameters').getString, 'PropertyList', ...
                {propRobotRadius, propSafetyDistance, propMinTurningRadius});

            mainGroup = matlab.system.display.SectionGroup(...
                'Title', getString(message('nav:navslalgs:vfh:FirstTabName')), ...
                'Sections', ...
                [valueGroup, thresholdGroup]);

            propTargetDirectionWeight = matlab.system.display.internal.Property('TargetDirectionWeight',...
                'Description',getString(message('nav:navslalgs:vfh:TargetDirectionWeightDisplayName')));
            propCurrentDirectionWeight = matlab.system.display.internal.Property('CurrentDirectionWeight',...
                'Description',getString(message('nav:navslalgs:vfh:CurrentDirectionWeightDisplayName')));
            propPreviousDirectionWeight = matlab.system.display.internal.Property('PreviousDirectionWeight',...
                'Description',getString(message('nav:navslalgs:vfh:PreviousDirectionWeightDisplayName')));

            initGroup = matlab.system.display.SectionGroup(...
                'Title', message('nav:navslalgs:vfh:CostFunctionWeights').getString, 'PropertyList', ...
                {propTargetDirectionWeight, propCurrentDirectionWeight, propPreviousDirectionWeight});

            groups = [mainGroup,initGroup];
        end
    end

    methods(Access = protected)
        function flag = supportsMultipleInstanceImpl(~)
        %supportsMultipleInstanceImpl Return true to enable support for
        % For-Each Subsystem
            flag = true;
        end
    end

    methods
        function obj = VectorFieldHistogram(varargin)
        %VectorFieldHistogram Constructor
            setProperties(obj,nargin,varargin{:});
        end
    end
end
