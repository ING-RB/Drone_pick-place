classdef TableBuilderOptions < matlab.mixin.Scalar
%TableBuilderOptions   Options for building a table.
%
%   Note: This options object does not do any cross-validation of
%   the options properties. So you can make the properties go out
%   of sync with one another.
%
%   Cross-validation is only done when setting on the TableBuilder
%   object. This acts like a simple form of MVC separation, where
%   the TableBuilderOptions object is the Model (M), while the
%   TableBuilder object is the Controller (C). Any datastore or
%   ImportOptions that uses TableBuilder ends up being the View (V).
%
%   See also: matlab.io.internal.common.builder.TableBuilder

%   Copyright 2022 The MathWorks, Inc.

    % Per-variable naming properties.
    % These are the original, unmodified VariableNames (before VariableNamingRule is applied).
    properties
        OriginalVariableNames (1, :) string {mustBeNonmissing} = string.empty(0, 1)
    end

    % Normalized versions of the per-variable naming properties.
    % Depending on the workflow, you might prefer to use these over the un-normalized versions.
    % NOTE: If you're implementing an IO function you probably want to prefer using these due
    %       to precedent from readtable, ImportOptions, and datastore.
    properties
        VariableNames (1, :) string {mustBeNonmissing} = string.empty(0, 1)
    end

    properties
        SelectedVariableIndices (1, :) double {matlab.io.internal.common.builder.TableBuilder.mustBeValidIndices} = double.empty(1, 0)
        VariableNamingRule      (1, 1) string = "preserve"
    end

    properties (Constant)
        % Default values for the DimensionNames properties.
        % Is also used to fill in zero-length strings supplied as the DimensionNames.
        DefaultDimensionNames (1, 2) string = ["Row" "Variables"];
    end

    % Since there are normalization concerns for the DimensionNames
    % properties, this pair of properties stores the normalized DimensionNames that
    % will be used to build() tables, and the original unnormalized
    % DimensionNames.
    properties
        OriginalDimensionNames (1, 2) string {matlab.io.internal.common.builder.TableBuilder.mustBeValidDimensionNames} = ...
                                              matlab.io.internal.common.builder.TableBuilderOptions.DefaultDimensionNames;

        DimensionNames         (1, 2) string {matlab.io.internal.common.builder.TableBuilder.mustBeValidDimensionNames} = ...
                                              matlab.io.internal.common.builder.TableBuilderOptions.DefaultDimensionNames;
    end

    % Type constraints for each variable in the generated table.
    % These are set to string(missing) by default to avoid type validation when building
    % the generated table.
    % If any VariableTypes values are set to non-missing strings, then their types
    % are checked at build() time and any mismatch results in an error.
    properties
        VariableTypes (1, :) string = string.empty(0, 1)
    end

    properties
        OriginalRowFilter = rowfilter(missing)

        % RowFilter can be slow to construct compared to the sub-millisecond execution time of parquetread.
        % So have a property which indicates that the TableBuilder is
        % unconstrained so that the RowFilter does not have to be queried.
        IsTrivialFilter (1, 1) logical = true
    end


    % Additional behavioral options.
    properties
        % Provides a warning when setting properties like VariableNames or VariableNamingRule
        % if variable name normalization has occurred.
        WarnOnNormalizationDuringSet (1, 1) logical = true

        % Provides a warning when building a table that required VariableName normalization.
        % Original VariableNames are saved in the VariableDescriptions property.
        % In general, you probably want this to be the opposite of the
        % WarnOnNormalizationDuringSet value.
        % NOTE: Only the false case is implemented currently.
        WarnOnNormalizationDuringBuild (1, 1) logical = false

        % Should SelectedVariableIndices have unique indices or not?
        % Setting to true will throw an error if a user tries to set duplicate
        % SelectedVariableIndices.
        % NOTE: Only the true case is implemented.
        RequireUniqueSelectedVariableIndices (1, 1) logical = true

        % Should OriginalVariableNames be saved in table VariableDescriptions if normalized
        % has occurred during build()?
        % NOTE: Only the true case is implemented.
        SaveOriginalVariableNamesInVariableDescriptions (1, 1) logical = true
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of TableBuilderOptions in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    methods
        function obj = set.VariableNamingRule(obj, rule)
            % Validate that VariableNamingRule is a string. Do case
            % normalization and partial matching.
            import matlab.io.internal.common.builder.TableBuilder.validateVariableNamingRule;
            obj.VariableNamingRule = validateVariableNamingRule(rule);
        end


        function obj = set.OriginalRowFilter(obj, rf)
            if ~isa(rf, "matlab.io.RowFilter")
                validateattributes(rf, "matlab.io.RowFilter", "scalar", string(missing), "RowFilter");
            end

            obj.OriginalRowFilter = rf;
        end
    end

    %%%%%%%%%%% SERIALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Hidden)
        function S = saveobj(obj)
            % Store save-load metadata.
            S = struct("EarliestSupportedVersion", 1);
            S.ClassVersion = obj.ClassVersion;

            % Behavioral properties
            S.WarnOnNormalizationDuringSet                    = obj.WarnOnNormalizationDuringSet;
            S.WarnOnNormalizationDuringBuild                  = obj.WarnOnNormalizationDuringBuild;
            S.RequireUniqueSelectedVariableIndices            = obj.RequireUniqueSelectedVariableIndices;
            S.SaveOriginalVariableNamesInVariableDescriptions = obj.SaveOriginalVariableNamesInVariableDescriptions;

            % Table generation properties
            S.VariableNamingRule      = obj.VariableNamingRule;
            S.OriginalVariableNames   = obj.OriginalVariableNames;
            S.VariableNames           = obj.VariableNames;
            S.SelectedVariableIndices = obj.SelectedVariableIndices;
            S.OriginalDimensionNames  = obj.OriginalDimensionNames;
            S.DimensionNames          = obj.DimensionNames;
            S.VariableTypes           = obj.VariableTypes;
            S.OriginalRowFilter       = obj.OriginalRowFilter;
            S.IsTrivialFilter         = obj.IsTrivialFilter;
        end
    end

    methods (Hidden, Static)
        function obj = loadobj(S)
            if isfield(S, "EarliestSupportedVersion")
                % Error if we are sure that a version incompatibility is about to occur.
                if S.EarliestSupportedVersion > matlab.io.internal.common.builder.TableBuilderOptions.ClassVersion
                    error(message("MATLAB:io:common:validation:UnsupportedClassVersion"));
                end
            end

            % Reconstruct TableBuilderOptions and re-set all properties.
            obj = matlab.io.internal.common.builder.TableBuilderOptions();
            obj.WarnOnNormalizationDuringSet                    = S.WarnOnNormalizationDuringSet;
            obj.WarnOnNormalizationDuringBuild                  = S.WarnOnNormalizationDuringBuild;
            obj.RequireUniqueSelectedVariableIndices            = S.RequireUniqueSelectedVariableIndices;
            obj.SaveOriginalVariableNamesInVariableDescriptions = S.SaveOriginalVariableNamesInVariableDescriptions;

            % Table generation properties
            obj.VariableNamingRule      = S.VariableNamingRule;
            obj.OriginalVariableNames   = S.OriginalVariableNames;
            obj.VariableNames           = S.VariableNames;
            obj.SelectedVariableIndices = S.SelectedVariableIndices;
            obj.OriginalDimensionNames  = S.OriginalDimensionNames;
            obj.DimensionNames          = S.DimensionNames;
            obj.VariableTypes           = S.VariableTypes;
            obj.OriginalRowFilter       = S.OriginalRowFilter;
            obj.IsTrivialFilter         = S.IsTrivialFilter;
        end
    end
end
