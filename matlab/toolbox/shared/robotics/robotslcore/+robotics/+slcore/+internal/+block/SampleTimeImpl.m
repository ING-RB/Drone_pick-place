classdef SampleTimeImpl < handle
%This class is for internal use only. It may be removed in the future.

%SampleTimeImpl Helper class for all robotics source blocks that need to expose sample time
%   Its main purpose is to validate the sample time inputs
%   that the user provides via the block mask.
%
%   Only certain sample times are supported (based on system object support):
%   - Inherited sample time
%   - Fixed-in-minor-step sample time
%   - Discrete sample time
%   - Constant sample time
%
%   If you have a system object class SysObj, use this class as
%   follows:
%   - Define a Non-tunable "SampleTime" property in SysObj
%   - Define a private variable "SampleTimeHandler" in SysObj that
%     contains an instance of this class
%   - In the set.SampleTime function, call validateAndSet in this class
%   - In the getSampleTimeImpl function of SysObj, retrieve the
%     SampleTimeSpec property of this class
%
%   See robotics.slros.internal.block.GetParameter for an example.

% Copyright 2015-2018 The MathWorks, Inc.

%#codegen

    properties (SetAccess = private)
        %SampleTime - Sample time
        %   Default: [-1 nan] (inherited)
        %   Size must be 1x2 to avoid dynamic memory allocation
        SampleTime
    end

    methods
        function obj = SampleTimeImpl
        %SampleTimeImpl Default constructor

        % Initialize the default inherited sample time specification
            obj.SampleTime = [-1 nan];
        end

        function validSampleTime = validate(obj, sampleTime)
        %validate Validate a given sample time input
        %   VALIDSAMPLETIME = validateAndSet(OBJ, SAMPLETIME) validates
        %   the input SAMPLETIME and, if valid, returns a harmonized
        %   VALIDSAMPLETIME that can be used for further processing by
        %   the caller.

            validateattributes(sampleTime, {'numeric'}, ...
                               {'nonempty', 'real', 'nonnan'}, '', 'SampleTime');

            % Structural check: Error out if more than two elements are specified
            coder.internal.errorIf(numel(sampleTime) > 2, ...
                                   'shared_robotics:robotslcore:sampletime:InvalidSampleTimeNeedScalar');

            % Make sure the sample time input is always a row vector
            sampleTimeRow = double(reshape(sampleTime, 1, []));

            % The following conditions are sorted in the order of expected
            % usage by customers.
            if sampleTimeRow(1) == -1.0
                obj.validateInheritedSampleTime(sampleTimeRow);
            elseif isinf(sampleTimeRow(1))
                obj.validateConstantSampleTime(sampleTimeRow);
            elseif sampleTimeRow(1) > 0.0
                obj.validateDiscreteSampleTime(sampleTimeRow);
            elseif sampleTimeRow(1) == 0.0
                obj.validateFixedInMinorStepSampleTime(sampleTimeRow);
            else
                coder.internal.error('shared_robotics:robotslcore:sampletime:InvalidSampleTimeType');
            end

            % Make sure the display to customers is always a row vector
            if isscalar(sampleTimeRow)
                obj.SampleTime(1) = sampleTimeRow;
            else
                obj.SampleTime(:) = sampleTimeRow;
            end

            validSampleTime = sampleTimeRow;
        end

        function spec = createSampleTimeSpec(obj)
        %createSampleTimeSpec construct sample time specification
        %according to sample time input.
        %
        %   Sample time spec cannot be stored as a class property as it
        %   by itself doesn't support code generation and should be
        %   only called from MATLAB system object getSampleTimeImpl
        %   method

            if obj.SampleTime(1) == -1.0
                spec = matlab.system.SampleTimeSpecification(...
                    "Type", "Inherited");
            elseif isinf(obj.SampleTime(1))
                spec = matlab.system.SampleTimeSpecification(...
                    "Type", "Discrete", "SampleTime", Inf);
            elseif obj.SampleTime(1) > 0.0
                offset = 0;
                if ~isnan(obj.SampleTime(2))
                    offset = double(obj.SampleTime(2));
                end
                spec = matlab.system.SampleTimeSpecification(...
                    "Type", "Discrete", ...
                    "SampleTime", double(obj.SampleTime(1)), "OffsetTime", offset);
            elseif obj.SampleTime(1) == 0.0
                spec = matlab.system.SampleTimeSpecification(...
                    "Type", "Fixed In Minor Step");
            else
                coder.internal.error('shared_robotics:robotslcore:sampletime:InvalidSampleTimeType');
            end
        end
    end

    methods (Access = private, Static)
        function validateFixedInMinorStepSampleTime(sampleTime)
        %validateFixedInMinorStepSampleTime Validate fixed-in-minor-step sampling time input
        %   The period is already confirmed to be 0.0. The only
        %   valid offset is 1.0.

            coder.internal.errorIf(numel(sampleTime) ~= 2 || sampleTime(2) ~= 1.0, ...
                                   'shared_robotics:robotslcore:sampletime:InvalidSampleTimeNeedOffsetOne');
        end

        function validateInheritedSampleTime(sampleTime)
        %validateInheritedSampleTime Validate inherited sampling time input
        %   The first element is already confirmed to be -1.0. The
        %   only valid offset is 0.0.

            if numel(sampleTime) == 2
                coder.internal.errorIf(sampleTime(2) ~= 0.0, ...
                                       'shared_robotics:robotslcore:sampletime:InvalidSampleTimeNeedZeroOffset');
            end
        end

        function validateDiscreteSampleTime(sampleTime)
        %validateDiscreteSampleTime Validate discrete periodic sampling time input
        %   The first element is already confirmed to be > 0.0. The
        %   only valid offset has to be smaller than the period and
        %   positive.

            if numel(sampleTime) == 2
                coder.internal.errorIf(sampleTime(2) >= sampleTime(1) || sampleTime(2) < 0.0, ...
                                       'shared_robotics:robotslcore:sampletime:InvalidSampleTimeNeedSmallerOffset');
            end
        end

        function validateConstantSampleTime(sampleTime)
        %validateConstantSampleTime Validate constant sampling time input
        %   The first element is already confirmed to be Inf. Make
        %   sure it's positive infinity.

            coder.internal.errorIf(sampleTime(1) < 0.0, ...
                                   'shared_robotics:robotslcore:sampletime:InvalidSampleTimeType');

            if numel(sampleTime) == 2
                coder.internal.errorIf(sampleTime(2) ~= 0.0, ...
                                       'shared_robotics:robotslcore:sampletime:InvalidConstantNeedZeroOffset');
            end
        end
    end

end
