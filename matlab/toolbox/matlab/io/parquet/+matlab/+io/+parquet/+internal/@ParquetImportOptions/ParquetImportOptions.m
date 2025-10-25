classdef ParquetImportOptions < matlab.mixin.Scalar
%ParquetImportOptions   Options for reading a Parquet file.

%   Copyright 2022 The MathWorks, Inc.

    % Properties from TabularBuilder.
    % The behavior is wired up to match parquetread/ParquetDatastore's behavior.
    properties (Dependent)
        VariableNames
        SelectedVariableNames
        VariableTypes
        OutputType
        RowTimes
        VariableNamingRule
        PreserveVariableNames
        RowFilter
    end

    properties (GetAccess = 'public', SetAccess = 'private')
        % Default to VariableNamingRule="modify".
        TabularBuilder (1, 1) matlab.io.internal.common.builder.TabularBuilder = matlab.io.internal.common.builder.TabularBuilder(PreserveVariableNames=false);
    end

    properties
        % Stores variable names from the Parquet file used earlier for detection.
        % During reading, the selected variable indices are mapped to these names and
        % then found in the Parquet file being read. This helps account for variable name
        % reorderings and extra variables in the file being read.
        ParquetFileVariableNames (1, :) string = string.empty(1, 0);
    end

    properties
        ArrowTypeConversionOptions (1, 1) matlab.io.internal.arrow.conversion.ArrowTypeConversionOptions
    end

    properties (Access = private, Constant)
        % Save-load metadata.
        % ClassVersion = 1 corresponds to the first release of ParquetImportOptions in R2022b.
        ClassVersion(1, 1) double = 1;
    end

    %%%%%%%%%%% CONSTRUCTORS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function obj = ParquetImportOptions(args)
            arguments
                args.VariableNames
                args.SelectedVariableNames
                args.VariableTypes
                args.OutputType
                args.RowTimes
                args.VariableNamingRule
                args.PreserveVariableNames
                args.RowFilter
                args.ParquetFileVariableNames
                args.ArrowTypeConversionOptions
            end

            if numel(fieldnames(args)) == 0
                return;
            end

            obj = matlab.io.parquet.internal.ParquetImportOptions.construct(args);
        end
    end

    methods (Static)
        obj = construct(args);
    end

    %%%%%%%%%%% GETTERS AND SETTERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function names = get.VariableNames(obj)
            names = obj.TabularBuilder.VariableNames;
        end

        function obj = set.VariableNames(obj, names)
            obj.TabularBuilder.VariableNames = names;
        end

        function names = get.SelectedVariableNames(obj)
            names = obj.TabularBuilder.SelectedVariableNames;
        end

        function obj = set.SelectedVariableNames(obj, names)
            obj.TabularBuilder.SelectedVariableNames = names;
        end

        function types = get.VariableTypes(obj)
            types = obj.TabularBuilder.VariableTypes;
        end

        function obj = set.VariableTypes(obj, types)
            obj.TabularBuilder.VariableTypes = types;
        end

        function type = get.OutputType(obj)
            type = obj.TabularBuilder.OutputType;
        end

        function obj = set.OutputType(obj, type)
            obj.TabularBuilder.OutputType = type;
        end

        function name = get.RowTimes(obj)
            name = obj.TabularBuilder.RowTimes;
        end

        function obj = set.RowTimes(obj, name)
            obj.TabularBuilder.RowTimes = name;
        end

        function rule = get.VariableNamingRule(obj)
            rule = obj.TabularBuilder.VariableNamingRule;
        end

        function obj = set.VariableNamingRule(obj, rule)
            obj.TabularBuilder.VariableNamingRule = rule;
        end

        function tf = get.PreserveVariableNames(obj)
            tf = obj.TabularBuilder.PreserveVariableNames;
        end

        function obj = set.PreserveVariableNames(obj, tf)
            obj.TabularBuilder.PreserveVariableNames = tf;
        end

        function rf = get.RowFilter(obj)
            rf = obj.TabularBuilder.RowFilter;
        end

        function obj = set.RowFilter(obj, rf)
            obj.TabularBuilder.RowFilter = rf;
        end
    end

    %%%%%%%%%%% SERIALIZATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Hidden)
        S = saveobj(obj);
    end

    methods (Hidden, Static)
        obj = loadobj(S);
    end
end
