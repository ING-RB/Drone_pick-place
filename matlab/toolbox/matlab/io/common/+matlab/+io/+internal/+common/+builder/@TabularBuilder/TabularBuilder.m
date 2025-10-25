classdef TabularBuilder < matlab.mixin.Scalar
%TabularBuilder   Incrementally build tables and timetables
%
%   TabularBuilderOptions is the actual storage layer for the properties
%   here. This object (TabularBuilder) is a cross-validation layer over it.
%
%   See also: matlab.io.internal.common.builder.TableBuilder,
%             matlab.io.internal.common.builder.TimetableBuilder,
%             matlab.io.internal.common.builder.TabularBuilderOptions

%   Copyright 2022 The MathWorks, Inc.

    properties
        %Options   TabularBuilderOptions that control the table/timetable
        %   returned by TabularBuilder.
        %
        %   Setting this property does not trigger any validation. So you
        %   can set this property directly to sidestep all
        %   cross-validation (but you probably shouldn't).
        Options (1, 1) matlab.io.internal.common.builder.TabularBuilderOptions
    end

    % Setting OutputType needs to cross-update the UnderlyingBuilder.
    properties (Dependent)
        OutputType
    end

    % Setting any of the RowTimes properties can also automatically change
    % OutputType from "table" to "timetable".
    properties (Dependent)
        RowTimes
        RowTimesVariableIndex
        RowTimesVariableName
        OriginalRowTimesVariableName
    end

    % Pure dependent properties.
    properties (Dependent)
        VariableNames
        OriginalVariableNames
        SelectedVariableIndices
        SelectedVariableNames
        OriginalSelectedVariableNames
        VariableNamingRule
        PreserveVariableNames
        DimensionNames
        OriginalDimensionNames
        VariableTypes
        SelectedVariableTypes
        RowFilter
        OriginalRowFilter
        WarnOnNormalizationDuringSet
    end

    properties (Dependent, SetAccess=private)
        IsTrivialFilter
        NormalizedVariableIndices
        SelectedNormalizedVariableIndices
        SelectedVariableDescriptions
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of TabularBuilder in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    %%%%%%%%%%% CONSTRUCTORS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function tab = TabularBuilder(tbOpts, ttbOpts, tabOpts)
            arguments
                tbOpts.VariableNames
                tbOpts.SelectedVariableNames
                tbOpts.OriginalVariableNames
                tbOpts.OriginalSelectedVariableNames
                tbOpts.SelectedVariableIndices
                tbOpts.VariableNamingRule
                tbOpts.PreserveVariableNames
                tbOpts.DimensionNames
                tbOpts.OriginalDimensionNames
                tbOpts.NormalizedVariableIndices
                tbOpts.SelectedNormalizedVariableIndices
                tbOpts.SelectedVariableDescriptions
                tbOpts.VariableTypes
                tbOpts.SelectedVariableTypes
                tbOpts.RowFilter
                tbOpts.OriginalRowFilter
                tbOpts.WarnOnNormalizationDuringSet
                ttbOpts.RowTimesVariableIndex
                ttbOpts.RowTimesVariableName
                ttbOpts.OriginalRowTimesVariableName
                ttbOpts.RowTimes
                tabOpts.OutputType (1, 1) string
            end

            % Default constructor case.
            isEmptyFields = @(x) numel(fieldnames(x)) == 0;
            if isEmptyFields(tbOpts) && isEmptyFields(ttbOpts) && isEmptyFields(tabOpts)
                return;
            end

            import matlab.io.internal.common.builder.TabularBuilder
            tab = TabularBuilder.construct(tbOpts, ttbOpts, tabOpts);
        end
    end

    methods (Static)
        obj = construct(tbOpts, ttbOpts, tubOpts);
    end

    %%%%%%%%%%% GETTERS AND SETTERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function OutputType = get.OutputType(obj)
            OutputType = obj.Options.OutputType;
        end

        function obj = set.OutputType(obj, OutputType)
            % Validate OutputType.
            import matlab.io.internal.common.builder.TabularBuilder.validateOutputType;
            OutputType = validateOutputType(OutputType);

            % Don't do anything if OutputType is unchanged.
            if OutputType == obj.Options.OutputType
                return;
            end

            % If it does change, call into the appropriate converter.
            import matlab.io.internal.common.builder.TabularBuilder.*;
            if OutputType == "table"
                obj.Options.UnderlyingBuilder = TimetableBuilder2TableBuilder(obj.Options.UnderlyingBuilder);
            else
                obj.Options.UnderlyingBuilder = TableBuilder2TimetableBuilder(obj.Options.UnderlyingBuilder);
            end
            obj.Options.OutputType = OutputType;
        end

        function index = get.RowTimesVariableIndex(obj)
            if obj.OutputType == "table"
                index = nan;
            else
                index = obj.Options.UnderlyingBuilder.RowTimesVariableIndex;
            end
        end

        function name = get.RowTimesVariableName(obj)
            if obj.OutputType == "table"
                name = string(missing);
            else
                name = obj.Options.UnderlyingBuilder.RowTimesVariableName;
            end
        end

        function name = get.OriginalRowTimesVariableName(obj)
            if obj.OutputType == "table"
                name = string(missing);
            else
                name = obj.Options.UnderlyingBuilder.OriginalRowTimesVariableName;
            end
        end

        function value = get.RowTimes(obj)
            if obj.OutputType == "table"
                value = string(missing);
            else
                value = obj.Options.UnderlyingBuilder.RowTimes;
            end
        end

        function obj = set.RowTimesVariableIndex(obj, index)
            arguments
                obj
                index (1, 1) double {mustBeReal}
            end

            import matlab.io.internal.common.builder.TabularBuilder.RowTimesModeSwitch
            [obj.Options.UnderlyingBuilder, obj.Options.OutputType] = RowTimesModeSwitch(obj.Options.UnderlyingBuilder, ...
                                                                                         obj.Options.OutputType, ...
                                                                                         "RowTimesVariableIndex", ...
                                                                                         index);
        end

        function obj = set.RowTimesVariableName(obj, name)
            arguments
                obj
                name (1, 1) string
            end

            import matlab.io.internal.common.builder.TabularBuilder.RowTimesModeSwitch
            [obj.Options.UnderlyingBuilder, obj.Options.OutputType] = RowTimesModeSwitch(obj.Options.UnderlyingBuilder, ...
                                                                                         obj.Options.OutputType, ...
                                                                                         "RowTimesVariableName", ...
                                                                                         name);
        end

        function obj = set.OriginalRowTimesVariableName(obj, name)
            arguments
                obj
                name (1, 1) string
            end

            import matlab.io.internal.common.builder.TabularBuilder.RowTimesModeSwitch
            [obj.Options.UnderlyingBuilder, obj.Options.OutputType] = RowTimesModeSwitch(obj.Options.UnderlyingBuilder, ...
                                                                                         obj.Options.OutputType, ...
                                                                                         "OriginalRowTimesVariableName", ...
                                                                                         name);
        end

        function obj = set.RowTimes(obj, value)
            arguments
                obj
                value
            end

            import matlab.io.internal.common.builder.TabularBuilder.RowTimesModeSwitch
            [obj.Options.UnderlyingBuilder, obj.Options.OutputType] = RowTimesModeSwitch(obj.Options.UnderlyingBuilder, ...
                                                                                         obj.Options.OutputType, ...
                                                                                         "RowTimes", ...
                                                                                         value);
        end
    end

    %%%%%%%%%%% BUILDER METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        T = build(obj, varargin);

        T = buildEmpty(obj);

        T = buildSelected(obj, varargin);
    end

    %%%%%%%%%%% SERIALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Hidden)
        S = saveobj(obj);
    end

    methods (Hidden, Static)
        obj = loadobj(S);
    end

    % Pure dependent properties
    methods
        function value = get.VariableNames(obj)
            value = obj.Options.UnderlyingBuilder.VariableNames;
        end

        function obj = set.VariableNames(obj, value)
            obj.Options.UnderlyingBuilder.VariableNames = value;
        end

        function value = get.OriginalVariableNames(obj)
            value = obj.Options.UnderlyingBuilder.OriginalVariableNames;
        end

        function obj = set.OriginalVariableNames(obj, value)
            obj.Options.UnderlyingBuilder.OriginalVariableNames = value;
        end

        function value = get.SelectedVariableIndices(obj)
            value = obj.Options.UnderlyingBuilder.SelectedVariableIndices;
        end

        function obj = set.SelectedVariableIndices(obj, value)
            obj.Options.UnderlyingBuilder.SelectedVariableIndices = value;
        end

        function value = get.SelectedVariableNames(obj)
            value = obj.Options.UnderlyingBuilder.SelectedVariableNames;
        end

        function obj = set.SelectedVariableNames(obj, value)
            obj.Options.UnderlyingBuilder.SelectedVariableNames = value;
        end

        function value = get.OriginalSelectedVariableNames(obj)
            value = obj.Options.UnderlyingBuilder.OriginalSelectedVariableNames;
        end

        function obj = set.OriginalSelectedVariableNames(obj, value)
            obj.Options.UnderlyingBuilder.OriginalSelectedVariableNames = value;
        end

        function value = get.VariableNamingRule(obj)
            value = obj.Options.UnderlyingBuilder.VariableNamingRule;
        end

        function obj = set.VariableNamingRule(obj, value)
            obj.Options.UnderlyingBuilder.VariableNamingRule = value;
        end

        function value = get.PreserveVariableNames(obj)
            value = obj.Options.UnderlyingBuilder.PreserveVariableNames;
        end

        function obj = set.PreserveVariableNames(obj, value)
            obj.Options.UnderlyingBuilder.PreserveVariableNames = value;
        end

        function value = get.DimensionNames(obj)
            value = obj.Options.UnderlyingBuilder.DimensionNames;
        end

        function obj = set.DimensionNames(obj, value)
            obj.Options.UnderlyingBuilder.DimensionNames = value;
        end

        function value = get.OriginalDimensionNames(obj)
            value = obj.Options.UnderlyingBuilder.OriginalDimensionNames;
        end

        function obj = set.OriginalDimensionNames(obj, value)
            obj.Options.UnderlyingBuilder.OriginalDimensionNames = value;
        end

        function value = get.RowFilter(obj)
            value = obj.Options.UnderlyingBuilder.RowFilter;
        end

        function obj = set.RowFilter(obj, value)
            obj.Options.UnderlyingBuilder.RowFilter = value;
        end

        function value = get.OriginalRowFilter(obj)
            value = obj.Options.UnderlyingBuilder.OriginalRowFilter;
        end

        function obj = set.OriginalRowFilter(obj, value)
            obj.Options.UnderlyingBuilder.OriginalRowFilter = value;
        end

        function value = get.IsTrivialFilter(obj)
            value = obj.Options.UnderlyingBuilder.IsTrivialFilter;
        end

        function value = get.WarnOnNormalizationDuringSet(obj)
            value = obj.Options.UnderlyingBuilder.WarnOnNormalizationDuringSet;
        end

        function obj = set.WarnOnNormalizationDuringSet(obj, value)
            obj.Options.UnderlyingBuilder.WarnOnNormalizationDuringSet = value;
        end

        function obj = set.NormalizedVariableIndices(obj, value)
            obj.Options.UnderlyingBuilder.NormalizedVariableIndices = value;
        end

        function obj = set.SelectedNormalizedVariableIndices(obj, value)
            obj.Options.UnderlyingBuilder.SelectedNormalizedVariableIndices = value;
        end

        function obj = set.SelectedVariableDescriptions(obj, value)
            obj.Options.UnderlyingBuilder.SelectedVariableDescriptions = value;
        end

        function value = get.VariableTypes(obj)
            value = obj.Options.UnderlyingBuilder.VariableTypes;
        end

        function obj = set.VariableTypes(obj, value)
            obj.Options.UnderlyingBuilder.VariableTypes = value;
        end

        function value = get.SelectedVariableTypes(obj)
            value = obj.Options.UnderlyingBuilder.SelectedVariableTypes;
        end

        function obj = set.SelectedVariableTypes(obj, value)
            obj.Options.UnderlyingBuilder.SelectedVariableTypes = value;
        end
    end
end
