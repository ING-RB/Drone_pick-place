classdef TabularBuilderOptions < matlab.mixin.Scalar
%TabularBuilderOptions   Options for building a table or timetable
%   using OutputType.
%
%   Note: This options object does not do any cross-validation of
%   the options properties. So you can make the properties go out
%   of sync with one another.
%
%   See also: matlab.io.internal.common.builder.TableBuilder,
%             matlab.io.internal.common.builder.TimetableBuilder,

%   Copyright 2022 The MathWorks, Inc.

    % Could be an underlying TableBuilder or TimetableBuilder.
    properties
        UnderlyingBuilder (1, 1) {matlab.io.internal.common.builder.TabularBuilder.validateUnderlyingBuilder} = matlab.io.internal.common.builder.TableBuilder()
    end

    properties
        OutputType (1, 1) string {matlab.io.internal.common.builder.TabularBuilder.validateOutputType} = "table"
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of TableBuilderOptions in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    %%%%%%%%%%% SERIALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Hidden)
        function S = saveobj(obj)
            % Store save-load metadata.
            S = struct("EarliestSupportedVersion", 1);
            S.ClassVersion = obj.ClassVersion;

            % Table/timetable generation properties
            S.UnderlyingBuilder = obj.UnderlyingBuilder;
            S.OutputType        = obj.OutputType;
        end
    end

    methods (Hidden, Static)
        function obj = loadobj(S)
            if isfield(S, "EarliestSupportedVersion")
                % Error if we are sure that a version incompatibility is about to occur.
                if S.EarliestSupportedVersion > matlab.io.internal.common.builder.TabularBuilderOptions.ClassVersion
                    error(message("MATLAB:io:common:validation:UnsupportedClassVersion"));
                end
            end

            % Reconstruct TimetableBuilderOptions and re-set all properties.
            obj = matlab.io.internal.common.builder.TabularBuilderOptions();
            obj.UnderlyingBuilder = S.UnderlyingBuilder;
            obj.OutputType        = S.OutputType;
        end
    end
end
