classdef TimetableBuilder < matlab.mixin.Scalar
%TimetableBuilder   A utility to incrementally build timetables
%
%   TimetableBuilderOptions is the actual storage layer for the properties
%   here. This object (TimetableBuilder) is a cross-validation layer over it.
%
%   See also: matlab.io.internal.common.builder.TableBuilder,
%             matlab.io.internal.common.builder.TimetableBuilderOptions,
%             matlab.io.internal.common.builder.TabularBuilder

%   Copyright 2022 The MathWorks, Inc.

    properties
        %Options   TimetableBuilderOptions that control the timetable
        %   returned by TimetableBuilder.
        %
        %   Setting this property does not trigger any validation. So you
        %   can set this property directly to sidestep all
        %   cross-validation (but you probably shouldn't).
        Options (1, 1) matlab.io.internal.common.builder.TimetableBuilderOptions
    end

    % We need to make sure that the RowTimes variable doesn't get
    % deselected. So the setters for SelectedVariableNames,
    % OriginalSelectedVariableNames, and SelectedVariableIndices are
    % overriden.
    %
    % Also, the VariableTypes/SelectedVariableTypes of the RowTimes column
    % shouldn't change away from datetime/duration/missing.
    properties (Dependent)
        SelectedVariableIndices

        SelectedVariableNames

        OriginalSelectedVariableNames

        VariableTypes

        SelectedVariableTypes
    end

    % Override for the RowTimesVariableIndex property. The setter
    % cross-validates that the index is selected and the VariableTypes for
    % that index is a datetime/duration type if nonmissing.
    properties (Dependent)
        RowTimesVariableIndex
    end

    % All of these are dependent on the Options property.
    properties (Dependent)
        VariableNames
        OriginalVariableNames
        VariableNamingRule
        PreserveVariableNames
        DimensionNames
        OriginalDimensionNames
        RowFilter
        OriginalRowFilter
        WarnOnNormalizationDuringSet
        TableBuilder
        RowTimesVariableName
        OriginalRowTimesVariableName
        RowTimes
    end

    properties (Dependent, SetAccess=private)
        IsTrivialFilter
        NormalizedVariableIndices
        SelectedNormalizedVariableIndices
        SelectedVariableDescriptions
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of TimetableBuilder in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    %%%%%%%%%%% CONSTRUCTORS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function ttb = TimetableBuilder(tbOpts, ttbOpts, opts)
            arguments
                tbOpts.?matlab.io.internal.common.builder.TableBuilder
                ttbOpts.RowTimesVariableIndex
                ttbOpts.RowTimesVariableName
                ttbOpts.OriginalRowTimesVariableName
                ttbOpts.RowTimes
                opts.TableBuilder
            end

            if isempty(fieldnames(tbOpts)) && isempty(fieldnames(ttbOpts)) ...
                    && isempty(fieldnames(opts))
                % Default constructor case.
                % This should error since at least one variable should be
                % selected as the RowTimes to correctly generate a timetable.
                error(message("MATLAB:io:common:builder:CouldNotInferRowTimes"));
            end

            % If the TableBuilder N-V pair is provided at
            % construction-time, use it as an override for all TableBuilder
            % options.
            import matlab.io.internal.common.builder.TableBuilder
            if isfield(opts, "TableBuilder")
                tb = opts.TableBuilder;
            else
                % Build a TableBuilder out of the TableBuilder options.
                tb = TableBuilder.construct(tbOpts);
            end

            % Build the TimetableBuilder out of the TableBuilder and the
            % RowTimes options.
            import matlab.io.internal.common.builder.TimetableBuilder
            ttb = TimetableBuilder.construct(ttb, tb, ttbOpts);
        end
    end

    methods (Static)
        ttb = construct(ttb, tb, ttbOpts);
    end

    %%%%%%%%%%% GETTERS AND SETTERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function indices = get.SelectedVariableIndices(obj)
            indices = obj.Options.TableBuilder.SelectedVariableIndices;
        end

        function names = get.SelectedVariableNames(obj)
            names = obj.Options.TableBuilder.SelectedVariableNames;
        end

        function names = get.OriginalSelectedVariableNames(obj)
            names = obj.Options.TableBuilder.OriginalSelectedVariableNames;
        end

        function types = get.VariableTypes(obj)
            types = obj.Options.TableBuilder.VariableTypes;
        end

        function types = get.SelectedVariableTypes(obj)
            types = obj.Options.TableBuilder.SelectedVariableTypes;
        end

        function index = get.RowTimesVariableIndex(obj)
            index = obj.Options.RowTimesVariableIndex;
        end

        function obj = set.SelectedVariableIndices(obj, indices)

            % Error if the SelectedVariableIndices is out of range.
            opts = obj.Options;
            opts.TableBuilder.SelectedVariableIndices = indices;

            % Validate that the RowTimes is still selected.
            % No need to store the output since changing the selection indices
            % cannot change the RowTimesVariableIndex, which is an index into
            % the VariableNames list (not the SelectedVariableNames list).
            import matlab.io.internal.common.builder.TimetableBuilder.validateRowTimesVariableIndex
            validateRowTimesVariableIndex(opts, opts.RowTimesVariableIndex);

            obj.Options = opts;
        end

        function obj = set.SelectedVariableNames(obj, names)

            % Error if the SelectedVariableNames is not members of VariableNames.
            opts = obj.Options;
            opts.TableBuilder.SelectedVariableNames = names;

            % Validate that the RowTimes is still selected.
            import matlab.io.internal.common.builder.TimetableBuilder.validateRowTimesVariableIndex
            validateRowTimesVariableIndex(opts, opts.RowTimesVariableIndex);

            obj.Options = opts;
        end

        function obj = set.OriginalSelectedVariableNames(obj, names)

            % Error if the OriginalSelectedVariableNames is not members of OriginalVariableNames.
            opts = obj.Options;
            opts.TableBuilder.OriginalSelectedVariableNames = names;

            % Validate that the RowTimes is still selected.
            import matlab.io.internal.common.builder.TimetableBuilder.validateRowTimesVariableIndex
            validateRowTimesVariableIndex(opts, opts.RowTimesVariableIndex);

            obj.Options = opts;
        end

        function obj = set.VariableTypes(obj, types)

            % Error if the VariableTypes is the wrong length.
            opts = obj.Options;
            opts.TableBuilder.VariableTypes = types;

            % Validate that the RowTimes is a datetime/duration type.
            import matlab.io.internal.common.builder.TimetableBuilder.validateRowTimesVariableIndex
            validateRowTimesVariableIndex(opts, opts.RowTimesVariableIndex);

            obj.Options = opts;
        end

        function obj = set.SelectedVariableTypes(obj, types)

            % Error if the SelectedVariableTypes is the wrong length.
            opts = obj.Options;
            opts.TableBuilder.SelectedVariableTypes = types;

            % Validate that the RowTimes is a datetime/duration type.
            import matlab.io.internal.common.builder.TimetableBuilder.validateRowTimesVariableIndex
            validateRowTimesVariableIndex(opts, opts.RowTimesVariableIndex);

            obj.Options = opts;
        end

        function obj = set.RowTimesVariableIndex(obj, index)

            % Error if this index is deselected or a non-timey type.
            import matlab.io.internal.common.builder.TimetableBuilder.validateRowTimesVariableIndex
            obj.Options.RowTimesVariableIndex = validateRowTimesVariableIndex(obj.Options, index);
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

    % Purely dependent properties (dependent on Options).
    methods
        function value = get.VariableNames(obj)
            value = obj.Options.TableBuilder.VariableNames;
        end

        function obj = set.VariableNames(obj, value)
            obj.Options.TableBuilder.VariableNames = value;
        end

        function value = get.OriginalVariableNames(obj)
            value = obj.Options.TableBuilder.OriginalVariableNames;
        end

        function obj = set.OriginalVariableNames(obj, value)
            obj.Options.TableBuilder.OriginalVariableNames = value;
        end

        function value = get.VariableNamingRule(obj)
            value = obj.Options.TableBuilder.VariableNamingRule;
        end

        function obj = set.VariableNamingRule(obj, value)
            obj.Options.TableBuilder.VariableNamingRule = value;
        end

        function value = get.PreserveVariableNames(obj)
            value = obj.Options.TableBuilder.PreserveVariableNames;
        end

        function obj = set.PreserveVariableNames(obj, value)
            obj.Options.TableBuilder.PreserveVariableNames = value;
        end

        function value = get.DimensionNames(obj)
            value = obj.Options.TableBuilder.DimensionNames;
        end

        function obj = set.DimensionNames(obj, value)
            obj.Options.TableBuilder.DimensionNames = value;
        end

        function value = get.OriginalDimensionNames(obj)
            value = obj.Options.TableBuilder.OriginalDimensionNames;
        end

        function obj = set.OriginalDimensionNames(obj, value)
            obj.Options.TableBuilder.OriginalDimensionNames = value;
        end

        function value = get.RowFilter(obj)
            value = obj.Options.TableBuilder.RowFilter;
        end

        function obj = set.RowFilter(obj, value)
            obj.Options.TableBuilder.RowFilter = value;
        end

        function value = get.OriginalRowFilter(obj)
            value = obj.Options.TableBuilder.OriginalRowFilter;
        end

        function obj = set.OriginalRowFilter(obj, value)
            obj.Options.TableBuilder.OriginalRowFilter = value;
        end

        function value = get.IsTrivialFilter(obj)
            value = obj.Options.TableBuilder.IsTrivialFilter;
        end

        function value = get.WarnOnNormalizationDuringSet(obj)
            value = obj.Options.TableBuilder.WarnOnNormalizationDuringSet;
        end

        function obj = set.WarnOnNormalizationDuringSet(obj, value)
            obj.Options.TableBuilder.WarnOnNormalizationDuringSet = value;
        end

        function obj = set.NormalizedVariableIndices(obj, value)
            obj.Options.TableBuilder.NormalizedVariableIndices = value;
        end

        function obj = set.SelectedNormalizedVariableIndices(obj, value)
            obj.Options.TableBuilder.SelectedNormalizedVariableIndices = value;
        end

        function obj = set.SelectedVariableDescriptions(obj, value)
            obj.Options.TableBuilder.SelectedVariableDescriptions = value;
        end

        function value = get.TableBuilder(obj)
            value = obj.Options.TableBuilder;
        end

        function obj = set.TableBuilder(obj, value)
            obj.Options.TableBuilder = value;
        end

        function value = get.RowTimesVariableName(obj)
            value = obj.Options.RowTimesVariableName;
        end

        function obj = set.RowTimesVariableName(obj, value)
            obj.Options.RowTimesVariableName = value;
        end

        function value = get.OriginalRowTimesVariableName(obj)
            value = obj.Options.OriginalRowTimesVariableName;
        end

        function obj = set.OriginalRowTimesVariableName(obj, value)
            obj.Options.OriginalRowTimesVariableName = value;
        end

        function value = get.RowTimes(obj)
            value = obj.Options.RowTimes;
        end

        function obj = set.RowTimes(obj, value)
            obj.Options.RowTimes = value;
        end
    end
end
