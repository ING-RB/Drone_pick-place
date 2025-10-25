classdef TableBuilder < matlab.mixin.Scalar
%TableBuilder   A utility to incrementally build tables.
%
%   Examples:
%
%     >> import matlab.io.internal.common.builder.TableBuilder
%
%     %%%% Example 1 %%%%
%     % Construct a table with some variable names specified ahead-of-time.
%
%     >> tb = TableBuilder(VariableNames=["A" "B"])
%
%     >> T = tb.build([5 6]', [7 8]') % Generates a table with VariableNames "A" and "B".
%
%     %%%% Example 2 %%%%
%     % Normalize invalid/duplicate variable names and then construct a
%     % table. A warning is printed on construction.
%     % Original variable names are saved in VariableDescriptions.
%
%     >> tb = TableBuilder(VariableNames=["" "Properties" "X" "X"])
%
%     >> T = tb.build("hello", 7, datetime('now'), hours(1))    % VariableNames are ["Var1" "Properties_1" "X" "X_1"]
%     >> T.Properties.VariableDescriptions       % Stores original Variable names: ["" "Properties" "X" "X"]
%
%     %%%% Example 3 %%%%
%     % Start with valid variable names, but then change variable naming
%     % rule. A warning is printed when this happens.
%
%     >> tb = TableBuilder(VariableNames=["hello world"])
%     >> tb.VariableNamingRule = "modify"    % A warning is printed and "hello world" is normalized to "helloWorld".
%
%     >> T = tb.build(0x3u64);    % Table with VariableNames "helloWorld" is generated.
%
%     %%%% Example 4 %%%%
%     % Select only some of the variables in the table being built.
%
%     >> tb = TableBuilder(VariableNames=["A" "B"])
%     >> tb.SelectedVariableNames = "A"
%
%     >> T = tb.build(7, "cat")  % Table with 1 variable "A" is built
%
%     %%%% Example 5 %%%%
%     % A clear delineation is made between pre-normalization and
%     % post-normalization VariableNames behavior. You can use
%     % SelectedVariableNames or OriginalSelectedVariableNames depending on
%     % whether you want to select post- or pre-normalization names.
%
%     >> tb = TableBuilder(VariableNames=["Properties" "B"])
%
%     >> tb.SelectedVariableNames         = "Properties_1"   % Select the 1st var using a post-normalization name.
%     >> tb.OriginalSelectedVariableNames = "Properties"     % Select the 1st var using a pre-normalization name.
%
%     %%%% Example 6 %%%%
%     % DimensionNames normalization is also handled. If a Variable name
%     % conflicts with a dimension name, the dimension name is modified
%     % during build-time.
%
%     >> tb = TableBuilder(VariableNames=["Hello" "Row"])
%
%     >> T = tb.build(11, 13)
%     >> T.Properties.DimensionNames    % DimensionNames is ["Row_1" "Variables"]
%
%     %%%% Example 7 %%%%
%     % Alternatives to the build() method. You can build a zero-row table
%     % using buildEmpty(), or build a table using only selected variables
%     % using buildSelected().
%
%     >> tb = TableBuilder(VariableNames=["A" "B"], SelectedVariableIndices=2)
%
%     >> T = tb.build(7, 8)          % Need to specify all variables. Returns a 1x1 table with the "B" variable.
%     >> T = tb.buildSelected(8)     % Only need to specify selected variables. Returns a 1x1 table with the "B" variable.
%
%     >> Tempty = tb.buildEmpty()    % Returns a 0x1 table with the "B" variable.
%
%     %%%% Example 8 %%%%
%     % Strict type checking during build() can be enabled by setting the VariableTypes
%     % property.
%
%     >> tb = TableBuilder(VariableNames=["A" "B"], VariableTypes=["double" "string"])
%
%     >> T = tb.build(1, 2)          % Error: Unexpected value of type "double" for second variable. Expected "string".
%     >> T = tb.build(1, "hello")    % Works fine.
%
%     %%%% Example 9 %%%%
%     % Use RowFilter to remove rows during build().
%
%     >> rf = rowfilter(["A" "B"])
%     >> tb = TableBuilder(VariableNames=["A" "B"], RowFilter=rf.A > 5)
%
%     >> T = tb.build([1 7]', ["hello" "world"]')  % Only returns the second row since that matches the filter.
%
%   TableBuilderOptions is the actual storage layer for the properties
%   here. This object (TableBuilder) is a cross-validation layer over it.
%
%   See also: matlab.io.internal.common.builder.TableBuilderOptions,
%             matlab.io.internal.common.builder.TimetableBuilder,
%             matlab.io.internal.common.builder.TabularBuilder

%   Copyright 2022 The MathWorks, Inc.

    properties (SetAccess = private)
        %Options   TableBuilderOptions that control the table returned by
        %   TableBuilder.
        %
        %   Setting this property does not trigger any validation. So you
        %   can set this property directly to sidestep all
        %   crossvalidation (but you probably shouldn't).
        Options (1, 1) matlab.io.internal.common.builder.TableBuilderOptions
    end

    properties (Dependent)
        %VariableNames   The table VariableNames that will be generated
        %   by the build() method.
        %
        %   This property contains a list of unique nonmissing strings with length
        %   between 0 and namelengthmax (noninclusive). These strings will not conflict
        %   with reserved table identifiers like "Properties" or ":".
        %
        %   Setting this property could cause a normalization warning to be
        %   displayed. The situations in which this warning appears depends
        %   on the VariableNamingRule, PreserveVariableNames,
        %   WarnOnNormalizationDuringSet, and
        %   WarnOnNormalizationDuringBuild properties.
        %
        %   Note that setting this property directly completely overrides
        %   all OriginalVariableNames, in effect causing TableBuilder to
        %   "forget" all OriginalVariableNames. This is because we cannot
        %   disambiguate user intent between overriding all VariableNames
        %   vs. just overriding 1 specific VariableNames element.
        %
        %   To avoid this, consider setting OriginalVariableNames directly
        %   in all situations where its possible to do so.
        %
        %   Setting this property also indirectly sets DimensionNames if
        %   there's a conflict with DimensionNames.
        %
        %   Setting this property will cause VariableDescriptions
        %   to be populated on the generated table if VariableNames
        %   normalization occurred.
        %
        %   Defaults to 1-by-0 string (no variables).
        VariableNames

        %SelectedVariableNames   A subset of VariableNames that narrows the
        %   table generated by the build() method.
        %
        %   SelectedVariableNames must be specified as a vector of strings
        %   where every element must be present in VariableNames.
        %
        %   SelectedVariableNames may be specified in a different order as
        %   VariableNames, but must not contain any repeated names.
        %
        %   This property will automatically update if
        %   SelectedVariableIndices or VariableNames is set.
        %
        %   Defaults to 1-by-0 string (no variables selected).
        SelectedVariableNames

        %OriginalVariableNames   These are the VariableNames that the table
        %   would have had if it didn't require any name normalization.
        %
        %   Therefore this property stores the actual list of non-missing
        %   strings that end up being normalized into VariableNames.
        %
        %   The strings in this property could be duplicates, empty string,
        %   strings over namelengthmax, or reserved table identifiers.
        %
        %   Setting this property WILL trigger an update to the
        %   VariableNames property. This may cause a warning to be printed
        %   if the OriginalVariableNames weren't already valid table
        %   variable names.
        %
        %   Setting this property also indirectly sets DimensionNames if
        %   there's a conflict with DimensionNames.
        %
        %   Setting this property will cause VariableDescriptions
        %   to be populated on the generated table if VariableNames
        %   normalization occurred.
        %
        %   Defaults to 1-by-0 string.
        OriginalVariableNames

        %OriginalSelectedVariableNames   Similar to SelectedVariableNames,
        %   but selects from the pool of (pre-normalization)
        %   OriginalVariableNames instead of the post-normalization
        %   VariableNames.
        %
        %   Defaults to 1-by-0 string.
        OriginalSelectedVariableNames

        %SelectedVariableIndices   Indices of variables to generate when
        %   calling build().
        %
        %   SelectedVariableIndices must be specified as a numeric vector
        %   containing unique integer value between 1 and
        %   numel(VariableNames) (inclusive).
        %
        %   SelectedVariableIndices can be specified out of order, but may
        %   not contain any repeated indices. This restriction may be
        %   lifted in the future.
        %
        %   Defaults to 1-by-0 double (no selected variables).
        SelectedVariableIndices

        %VariableNamingRule   Normalization rule for table VariableNames.
        %
        %   Must be specified as a scalar string: "preserve" or "modify".
        %
        %   "preserve" and "modify" rules both require unique nonempty
        %   VariableNames. But the legacy "modify" behavior will also call
        %   matlab.lang.makeValidName (and force all variable names to be
        %   alphanumeric ASCII characters).
        %
        %   Note that changing this value triggers a re-normalization of
        %   VariableNames, and may therefore display a warning.
        %   VariableDescriptions will be populated on the generated table
        %   in this case.
        %
        %   Note that this property may also trigger an update in
        %   DimensionNames if a VariableNames conflict was encountered.
        %
        %   Defaults to "preserve", which should be preferred for new code.
        VariableNamingRule

        %PreserveVariableNames   Legacy flag for VariableNamingRule.
        %
        %   true => VariableNamingRule="preserve"
        %   false => VariableNamingRule="modify"
        %
        %   Defaults to true (table VariableNames are preserved.)
        PreserveVariableNames

        %DimensionNames   DimensionNames used to build the table.
        %
        %   Since VariableNames aren't allowed to intersect with
        %   DimensionNames, we have to do unique-ification of
        %   OriginalDimensionNames.
        %
        %   This property stores the unique-ified DimensionNames. So if
        %   VariableNames="Row", then DimensionNames(1) will be "Row_1".
        %   But OriginalDimensionNames(1) will still be "Row".
        %
        %   Note that unlike VariableNames/VariableNamingRule, changes to
        %   this property will never print a warning.
        %
        %   Defaults to ["Row" "Variables"].
        DimensionNames

        %OriginalDimensionNames   The DimensionNames that the table would
        %   have had if it didn't need unique-ification or normalization.
        %
        %   Defaults to ["Row" "Variables"].
        OriginalDimensionNames
    end

    % Informational properties that depend on the other properties.
    properties (Dependent, SetAccess=private)
        %NormalizedVariableIndices   Indices of any VariableNames that got
        %   normalized. Not settable.
        %
        %   Defaults to 1x0 empty double if no variable name needs
        %   normalization.
        NormalizedVariableIndices

        %SelectedNormalizedVariableIndices   Indices of any VariableNames
        %   that are both selected and normalized. Not settable.
        %
        %   Defaults to 1x0 empty double if no selected variable name needs
        %   normalization.
        SelectedNormalizedVariableIndices

        %SelectedVariableDescriptions   The VariableDescriptions that will
        %   be set on the generated table. Not settable.
        %
        %   This will be 1x0 empty string if no selected variables needed
        %   normalization.
        %
        %   If any selected variable needs normalization, this will be set
        %   to OriginalSelectedVariableNames.
        %
        %   Note that the actual default for table's VariableDescriptions
        %   is a 0x0 cell. You may need to handle that separately.
        SelectedVariableDescriptions
    end

    properties (Dependent)
        %VariableTypes   Type constraints for the data used to build the
        %   table.
        %
        %   VariableTypes is an 1xN string vector of the same length as
        %   VariableNames.
        %
        %   By default, all values in the VariableTypes vector are
        %   set to string(missing), indicating that no type checking will
        %   occur during build().
        %
        %   Set VariableTypes to a non-missing string to enable type
        %   checking at build() time. An error will be thrown if any
        %   variable provided during build() fails to satisfy a type
        %   requirement.
        %
        %   Note that the list of variable types is not checked for
        %   validity.
        %   So you could potentially provide non-existent type names
        %   when specifying VariableTypes. This will error at build-time
        %   though.
        VariableTypes

        %SelectedVariableTypes   VariableTypes that are selected by
        %   SelectedVariableIndices.
        %
        %   Similar to VariableTypes, but for Selected variables.
        %   Therefore this is a 1xN string, where N is the length of
        %   SelectedVariableIndices.
        %
        %   Is in the same order as SelectedVariableIndices.
        SelectedVariableTypes
    end

    properties (Dependent)
        %RowFilter   Rows to remove from the generated table after build().
        %
        %   This property stores the filter expression using normalized
        %   variable names (specified in the VariableNames property).
        %
        %   Defaults to rowfilter(missing).
        RowFilter

        %OriginalRowFilter   Rows to remove from the generated table after
        %   build(), specified using OriginalVariableNames.
        %
        %   Defaults to rowfilter(missing).
        OriginalRowFilter
    end

    properties (Dependent, SetAccess=private)
        %IsTrivialFilter   Describes if the RowFilter is in a trivial
        %   state (no filtering to be done.)
        IsTrivialFilter
    end

    properties (Dependent)
        %WarnOnNormalizationDuringSet   Whether to print a warning
        %   if table variable name normalization occurred when setting the
        %   VariableNames or VariableNamingRule properties.
        %
        %   This defaults to true in order to match parquetread
        %   behavior.
        WarnOnNormalizationDuringSet
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of TableBuilder in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    %%%%%%%%%%% CONSTRUCTORS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function tb = TableBuilder(args)
            arguments
                args.VariableNames
                args.SelectedVariableNames
                args.OriginalVariableNames
                args.OriginalSelectedVariableNames
                args.SelectedVariableIndices
                args.VariableNamingRule
                args.PreserveVariableNames
                args.DimensionNames
                args.OriginalDimensionNames
                args.NormalizedVariableIndices
                args.SelectedNormalizedVariableIndices
                args.SelectedVariableDescriptions
                args.VariableTypes
                args.SelectedVariableTypes
                args.RowFilter
                args.OriginalRowFilter
                args.WarnOnNormalizationDuringSet
                args.Options
            end

            if numel(fieldnames(args)) == 0
                % Default constructor case.
                return;
            end

            % Call into a utility to make sure all properties are
            % validated in the right order for construction.
            tb = matlab.io.internal.common.builder.TableBuilder.construct(args);
        end
    end

    methods (Static)
        obj = construct(args);
    end

    %%%%%%%%%%% SETTERS AND GETTERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Unlike the getters and setters on the Options object, these ones
    % actually do cross-validation.
    methods
        function varNames = get.OriginalVariableNames(obj)
            varNames = obj.Options.OriginalVariableNames;
        end

        function obj = set.OriginalVariableNames(obj, varNames)
            arguments
                obj      (1, 1) matlab.io.internal.common.builder.TableBuilder
                varNames (1, :) string {mustBeNonmissing}
            end

            % Verify that this is the same length as existing VariableNames.
            if numel(varNames) ~= numel(obj.OriginalVariableNames)
                N = numel(obj.OriginalVariableNames);
                error(message("MATLAB:io:common:builder:NumberOfVariablesMustBeConstant", N));
            end

            % Set the original VariableNames in the options object. Store the normalized
            % names in VariableNames.
            import matlab.io.internal.common.builder.TableBuilder.normalizeVariableNames
            obj.Options = normalizeVariableNames(obj.Options, varNames);
        end

        function varNames = get.VariableNames(obj)
            varNames = obj.Options.VariableNames;
        end

        function obj = set.VariableNames(obj, varNames)
            % Override OriginalVariableNames and trigger re-normalization.
            % This could print a warning.
            obj.OriginalVariableNames = varNames;
        end

        function rule = get.VariableNamingRule(obj)
            rule = obj.Options.VariableNamingRule;
        end

        function obj = set.VariableNamingRule(obj, rule)
            % Validate that VariableNamingRule is the correct datatype and
            % value.
            import matlab.io.internal.common.builder.TableBuilder.validateVariableNamingRule;
            rule = validateVariableNamingRule(rule);

            opts = obj.Options;
            opts.VariableNamingRule = rule;

            % Trigger re-normalization of VariableNames and DimensionNames.
            import matlab.io.internal.common.builder.TableBuilder.normalizeVariableNames
            obj.Options = normalizeVariableNames(opts, opts.OriginalVariableNames);
        end

        function dimNames = get.DimensionNames(obj)
            dimNames = obj.Options.DimensionNames;
        end

        function obj = set.DimensionNames(obj, dimNames)
            % Since DimensionNames is dependent on OriginalDependentNames, set() on
            % DimensionNames is implied as an override to OriginalDimensionNames.
            obj.OriginalDimensionNames = dimNames;
        end

        function dimNames = get.OriginalDimensionNames(obj)
            dimNames = obj.Options.OriginalDimensionNames;
        end

        function obj = set.OriginalDimensionNames(obj, dimNames)
            % Validate size/datatype of DimensionNames.
            import matlab.io.internal.common.builder.TableBuilder.mustBeValidDimensionNames
            dimNames = mustBeValidDimensionNames(dimNames);

            % Store the supplied dimNames as OriginalDimensionNames.
            % Store the normalized dimension names as DimensionNames.
            import matlab.io.internal.common.builder.TableBuilder.normalizeDimensionNames
            obj.Options.OriginalDimensionNames = dimNames;
            obj.Options.DimensionNames = normalizeDimensionNames(obj.Options);
        end

        function indices = get.SelectedVariableIndices(obj)
            indices = obj.Options.SelectedVariableIndices;
        end

        function obj = set.SelectedVariableIndices(obj, indices)
            % Cross-validate and store the new SelectedVariableIndices value.
            import matlab.io.internal.common.builder.TableBuilder.validateSelectedVariableIndices
            obj.Options.SelectedVariableIndices = validateSelectedVariableIndices(obj.Options, indices);
        end

        function varNames = get.OriginalSelectedVariableNames(obj)
            varNames = obj.OriginalVariableNames(obj.SelectedVariableIndices);
        end

        function obj = set.OriginalSelectedVariableNames(obj, varNames)

            % OriginalSelectedVariableNames must be a subset of OriginalVariableNames.
            import matlab.io.internal.common.builder.TableBuilder.validateSelectedVariableNames;
            indices = validateSelectedVariableNames(obj.Options, varNames, true);

            % Make sure that no RowFilter variable names are being
            % deselected.
            import matlab.io.internal.common.builder.TableBuilder.checkRowFilterConstrainedVariableNamesSelection;
            obj.Options.SelectedVariableIndices = checkRowFilterConstrainedVariableNamesSelection(obj.Options, indices);
        end

        function varNames = get.SelectedVariableNames(obj)
            varNames = obj.VariableNames(obj.SelectedVariableIndices);
        end

        function obj = set.SelectedVariableNames(obj, varNames)

            % SelectedVariableNames must be a subset of VariableNames.
            import matlab.io.internal.common.builder.TableBuilder.validateSelectedVariableNames;
            indices = validateSelectedVariableNames(obj.Options, varNames, false);

            % Make sure that no RowFilter variable names are being
            % deselected.
            import matlab.io.internal.common.builder.TableBuilder.checkRowFilterConstrainedVariableNamesSelection;
            obj.Options.SelectedVariableIndices = checkRowFilterConstrainedVariableNamesSelection(obj.Options, indices);
        end

        function tf = get.PreserveVariableNames(obj)
            tf = obj.VariableNamingRule == "preserve";
        end

        function obj = set.PreserveVariableNames(obj, tf)
            % Just set VariableNamingRule instead.
            import matlab.io.internal.common.builder.TableBuilder.convertPreserveVariableNamesToVariableNamingRule
            obj.VariableNamingRule = convertPreserveVariableNamesToVariableNamingRule(tf);
        end

        function types = get.VariableTypes(obj)
            types = obj.Options.VariableTypes;
        end

        function obj = set.VariableTypes(obj, types)
            % Make sure that VariableTypes are of the right length before setting.
            import matlab.io.internal.common.builder.TableBuilder.validateVariableTypes
            obj.Options.VariableTypes = validateVariableTypes(obj.Options, types, false);
        end

        function rf = get.RowFilter(obj)
            if obj.Options.IsTrivialFilter
                % We need to add the actual variable names on the
                % RowFilter object.
                rf = rowfilter(obj.SelectedVariableNames);
            else
                % Map the OriginalRowFilter variable names to the normalized names.
                % Note that duplicate variable names are unfortunately all mapped to the first
                % instance of the duplicate at this step. So this step is potentially lossy.
                rf = replaceVariableNames(obj.Options.OriginalRowFilter, obj.OriginalSelectedVariableNames, obj.SelectedVariableNames);
            end
        end

        function obj = set.RowFilter(obj, rf)
            if ~isa(rf, "matlab.io.RowFilter")
                validateattributes(rf, "matlab.io.RowFilter", "scalar", string(missing), "RowFilter");
            end

            import matlab.io.internal.common.builder.TableBuilder.validateRowFilterConstrainedVariableNames
            rf = validateRowFilterConstrainedVariableNames(obj.Options, rf, false);

            % IO-based filtering is only supported for a predefined set of
            % types.
            import matlab.io.internal.filter.validators.validateParquetDatatypeSupport
            rf = validateParquetDatatypeSupport(rf);

            % Map the normalized names back to the original variable names.
            obj.Options.OriginalRowFilter = replaceVariableNames(rf, obj.VariableNames, obj.OriginalVariableNames);
            obj.Options.IsTrivialFilter = false;
        end

        function rf = get.OriginalRowFilter(obj)
            if obj.Options.IsTrivialFilter
                % We need to add the actual variable names on the
                % RowFilter object.
                rf = rowfilter(obj.OriginalSelectedVariableNames);
            else
                rf = obj.Options.OriginalRowFilter;
            end
        end

        function obj = set.OriginalRowFilter(obj, rf)
            if ~isa(rf, "matlab.io.RowFilter")
                validateattributes(rf, "matlab.io.RowFilter", "scalar", string(missing), "RowFilter");
            end

            % IO-based filtering is only supported for a predefined set of
            % types.
            import matlab.io.internal.filter.validators.validateParquetDatatypeSupport
            rf = validateParquetDatatypeSupport(rf);

            import matlab.io.internal.common.builder.TableBuilder.validateRowFilterConstrainedVariableNames
            obj.Options.OriginalRowFilter = validateRowFilterConstrainedVariableNames(obj.Options, rf, true);
            obj.Options.IsTrivialFilter = false;
        end

        function tf = get.IsTrivialFilter(obj)
            tf = obj.Options.IsTrivialFilter;
        end

        function indices = get.NormalizedVariableIndices(obj)
            % For now, just return indices of variables where the
            % VariableNames differs from the OriginalVariableNames.
            indices = find(obj.VariableNames ~= obj.OriginalVariableNames);

            % Make it a row vector to be consistent with other per-variable
            % properties.
            indices = reshape(indices, 1, []);
        end

        function indices = get.SelectedNormalizedVariableIndices(obj)
            % For now, just return indices of variables where the
            % SelectedVariableNames differs from the OriginalSelectedVariableNames.
            indices = find(obj.SelectedVariableNames ~= obj.OriginalSelectedVariableNames);

            % Return an index vector into VariableNames, not
            % SelectedVariableNames. So use SelectedVariableIndices to map
            % back to VariableNames indices.
            indices = obj.SelectedVariableIndices(indices);

            % Make it a row vector to be consistent with other per-variable
            % properties.
            indices = reshape(indices, 1, []);
        end

        function descriptions = get.SelectedVariableDescriptions(obj)
            % Based on ImportOptions behavior, VariableDescriptions should
            % only be populated if there is at least one selected variable
            % that needed normalization behavior.
            if isempty(obj.SelectedNormalizedVariableIndices)
                % NB default table VariableDescriptions is actually 0x0,
                % not 1x0.
                % Going with 1x0 here to be consistent in TableBuilder.
                descriptions = string.empty(1, 0);
            else
                descriptions = obj.OriginalSelectedVariableNames;
            end
        end

        function types = get.SelectedVariableTypes(obj)
            types = obj.VariableTypes(obj.SelectedVariableIndices);
        end

        function obj = set.SelectedVariableTypes(obj, SelectedVariableTypes)
            arguments
                obj
                SelectedVariableTypes (1, :) string
            end

            % Must be of same length as SelectedVariableIndices.
            import matlab.io.internal.common.builder.TableBuilder.validateVariableTypes
            types = validateVariableTypes(obj, SelectedVariableTypes, true);

            % Modify the VariableTypes that are selected.
            obj.VariableTypes(obj.SelectedVariableIndices) = types;
        end

        function tf = get.WarnOnNormalizationDuringSet(obj)
            tf = obj.Options.WarnOnNormalizationDuringSet;
        end

        function obj = set.WarnOnNormalizationDuringSet(obj, tf)
            obj.Options.WarnOnNormalizationDuringSet = tf;
        end

        function tf = isequaln(varargin)
            % We need to ignore IsTrivialFilter during isequaln.
            isTableBuilder = @(x) isa(x, "matlab.io.internal.common.builder.TableBuilder");

            for i=1:numel(varargin)
                if isTableBuilder(varargin{i})
                    % Forces IsTrivialFilter to be false.
                    varargin{i}.OriginalRowFilter = varargin{i}.OriginalRowFilter;
                end
            end

            tf = builtin("isequaln", varargin{:});
        end
    end

    %%%%%%%%%%% BUILDER METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        T = build(obj, varargin);

        T = buildEmpty(obj);

        T = buildSelected(obj, varargin);
    end

    %%%%%%%%%%% SERIALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Hidden)
        S = saveobj(obj);
    end

    methods (Hidden, Static)
        obj = loadobj(S);
    end
end
