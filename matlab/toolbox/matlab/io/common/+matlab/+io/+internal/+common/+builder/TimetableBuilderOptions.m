classdef TimetableBuilderOptions < matlab.mixin.Scalar
%TimetableBuilderOptions   Options for building a timetable.
%
%   Note: This options object does not do any cross-validation of
%   the options properties. So you can make the properties go out
%   of sync with one another.
%
%   Note: Unlike TableBuilderOptions, which default-constructs in
%   a valid state, TimetableBuilderOptions default-constructs in
%   an invalid state since RowTimesVariableIndex defaults to 1 while
%   the TableBuilder has no variables. It is the caller's responsibility
%   to get this object into a self-consistent state.
%
%   See also: matlab.io.internal.common.builder.TableBuilder

%   Copyright 2022 The MathWorks, Inc.

    % Pull all the TableBuilder properties into this.
    properties
        TableBuilder (1, 1) matlab.io.internal.common.builder.TableBuilder
    end

    properties
        RowTimesVariableIndex (1, 1) double {mustBeInteger, mustBePositive} = 1
    end

    properties (Dependent)
        RowTimesVariableName
        OriginalRowTimesVariableName

        % Can be set as an index or a variable name string.
        % On get, will always be a variable name string.
        RowTimes
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of TableBuilderOptions in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    methods
        function name = get.OriginalRowTimesVariableName(obj)
            name = obj.TableBuilder.OriginalVariableNames(obj.RowTimesVariableIndex);
        end

        function obj = set.OriginalRowTimesVariableName(obj, name)
            % OriginalRowTimesVariableName must be a subset of OriginalSelectedVariableNames.
            import matlab.io.internal.common.builder.TimetableBuilder.validateRowTimesVariableName;
            obj.RowTimesVariableIndex = validateRowTimesVariableName(obj, name, true);
        end

        function name = get.RowTimesVariableName(obj)
            name = obj.TableBuilder.VariableNames(obj.RowTimesVariableIndex);
        end

        function obj = set.RowTimesVariableName(obj, name)
            % RowTimesVariableName must be a subset of SelectedVariableNames.
            import matlab.io.internal.common.builder.TimetableBuilder.validateRowTimesVariableName;
            obj.RowTimesVariableIndex = validateRowTimesVariableName(obj, name, false);
        end

        function name = get.RowTimes(obj)
            % Use the post-normalization name instead of the original name
            % for compatibility with ParquetDatastore.
            name = obj.RowTimesVariableName;
        end

        function obj = set.RowTimes(obj, nameOrIndex)
            import matlab.io.internal.common.builder.TimetableBuilder.validateRowTimesVariableIndex

            nameOrIndex = convertCharsToStrings(nameOrIndex);

            if isstring(nameOrIndex)
                obj.RowTimesVariableName = nameOrIndex;
            elseif isscalar(nameOrIndex) && isnumeric(nameOrIndex)
                obj.RowTimesVariableIndex = validateRowTimesVariableIndex(obj, nameOrIndex);
            else
                error(message("MATLAB:io:common:builder:InvalidRowTimesInput"));
            end
        end
    end

    %%%%%%%%%%% SERIALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Hidden)
        function S = saveobj(obj)
            % Store save-load metadata.
            S = struct("EarliestSupportedVersion", 1);
            S.ClassVersion = obj.ClassVersion;

            % Timetable generation properties
            S.TableBuilder          = obj.TableBuilder;
            S.RowTimesVariableIndex = obj.RowTimesVariableIndex;
        end
    end

    methods (Hidden, Static)
        function obj = loadobj(S)
            if isfield(S, "EarliestSupportedVersion")
                % Error if we are sure that a version incompatibility is about to occur.
                if S.EarliestSupportedVersion > matlab.io.internal.common.builder.TimetableBuilderOptions.ClassVersion
                    error(message("MATLAB:io:common:validation:UnsupportedClassVersion"));
                end
            end

            % Reconstruct TimetableBuilderOptions and re-set all properties.
            obj = matlab.io.internal.common.builder.TimetableBuilderOptions();
            obj.TableBuilder          = S.TableBuilder;
            obj.RowTimesVariableIndex = S.RowTimesVariableIndex;
        end
    end
end
