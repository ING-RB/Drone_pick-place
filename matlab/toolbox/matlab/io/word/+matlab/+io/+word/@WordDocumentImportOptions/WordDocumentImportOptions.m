classdef WordDocumentImportOptions < matlab.io.ImportOptions & ...
        matlab.io.xml.internal.parameter.TableSelectorProvider & ...
        matlab.io.internal.parameter.RowParametersProvider & ...
        matlab.io.internal.parameter.SpanHandlingProvider & ...
        matlab.internal.datatypes.saveLoadCompatibility & ...
        matlab.io.internal.mixin.UsesStringsForPropertyValues
    %matlab.io.word.WordDocumentImportOptions Options for importing data from a Word file
    %
    %   opts = wordDocumentImportOptions("Prop1",val1,"Prop2",val2,...) creates
    %           options for importing a table from a Word file.
    %
    %   Name-Value pairs for wordDocumentImportOptions:
    %
    %    numVars - Number of variables
    %
    %    Variable Properties
    %      VariableNames         - Variable names
    %      VariableNamingRule    - Flag to preserve variable names
    %      VariableTypes         - Data types of variable
    %      SelectedVariableNames - Subset of variables to import
    %      VariableOptions       - Type specific variable import options
    %
    %    Location Properties
    %      TableSelector           - Table data XPath expression
    %      DataRows                - Data location
    %      RowNamesColumn          - Row names location
    %      VariableNamesRow        - Variable names location
    %      VariableUnitsRow        - Variable units location
    %      VariableDescriptionsRow - Variable descriptions location
    %
    %    Replacement Rules
    %      MissingRule          - Procedure to manage missing data
    %      EmptyRowRule         - Procedure to handle empty rows
    %      ImportErrorRule      - Procedure to handle import errors
    %      ExtraColumnsRule     - Procedure to handle extra columns
    %      MergedCellColumnRule - Procedure to handle cells with merged columns
    %      MergedCellRowRule    - Procedure to handle cells with merged rows
    %
    %   See Also: detectImportOptions, readtable, wordDocumentImportOptions,
    %             matlab.io.VariableImportOptions

    %   Copyright 2021 The MathWorks, Inc.

    properties(Constant, Access = protected)
        version = 1;
    end

    properties (Parameter)
        %RowNamesColumn  the column that contains row names describing the
        % data.
        % RowNamesColumn must be a non-negative scalar integer.
        RowNamesColumn = 0;

        %ExtraColumnsRule what to do with extra columns of data that appear
        % after the expected variables.
        %
        %   Possible values:
        %       addvars: Create a new variable in the resulting table
        %                containing the data from the extra columns. The
        %                new variables are named 'ExtraVar1', 'ExtraVar2',
        %                etc..
        %
        %        ignore: Ignore the extra columns of data.
        %
        %         error: Error during import and abort the operation.
        ExtraColumnsRule = "addvars";
    end

    methods
        function opts = WordDocumentImportOptions(varargin)
            varargin = ['PreserveVariableNames', true, varargin];

            % To ensure MissingRule and ImportErrorRule are string scalars
            % by default, we have to call the MissingRule and
            % ImportErrorRule setters.
            varargin = ['MissingRule', 'fill', 'ImportErrorRule', 'fill', varargin];

            [opts,otherArgs] = opts.parseInputs(varargin,{'NumVariables', ...
                                'VariableOptions','PreserveVariableNames','VariableNames'});
            opts.assertNoAdditionalParameters(fields(otherArgs),class(opts));
        end

        function opts = set.ExtraColumnsRule(opts,rhs)
            rules = ["addvars","ignore","wrap","error"];
            opts.ExtraColumnsRule = validatestring(rhs,rules);
        end

        function opts = set.RowNamesColumn(opts,rhs)
            n = matlab.io.internal.common.validateNonNegativeScalarInt(rhs);
            opts.RowNamesColumn = n;
        end
    end

    methods (Access = {?matlab.io.internal.functions.ReadTableWithImportOptionsWordDocument})
        function params = getOptionsStruct(obj)
            params = struct();
            params.ParserType = 'worddocument';
            params.OutputBuilderType = 'table';

            params.MissingRule = convertStringsToChars(obj.MissingRule);
            params.ImportErrorRule = convertStringsToChars(obj.ImportErrorRule);
            params.EmptyRowRule = convertStringsToChars(obj.EmptyRowRule);

            % params.NumVariables = obj.fast_var_opts.numVars();
            params.NumVariables = numel(obj.SelectedVariableNames);
            params.PreserveVariableNames = obj.PreserveVariableNames;

            params.TableSelector = obj.TableSelector;

            params.VariableNamesRow = obj.VariableNamesRow;
            params.VariableUnitsRow = obj.VariableUnitsRow;
            params.VariableDescriptionsRow = obj.VariableDescriptionsRow;

            params.VariableOptions = obj.fast_var_opts.getVarOptsStruct();
        end
    end

    methods (Access = protected)
        function str = saveLoadNames(obj)
            % setdiff(string(properties('matlab.io.word.WordDocumentImportOptions')), string(properties('matlab.io.ImportOptions')))
            str = ["DataRows", "EmptyRowRule", "ExtraColumnsRule",...
                "MergedCellColumnRule", "MergedCellRowRule", "RowNamesColumn", "TableSelector",...
                "VariableDescriptionsRow", "VariableNamesRow", "VariableUnitsRow"];
        end

        function s = saveToStruct(obj)
        % gets serialized struct of ImportOptions
            s = saveToStruct@matlab.io.ImportOptions(obj);

            for prop = obj.saveLoadNames
                s.(prop) = obj.(prop);
            end

            % sets the version and minCompatVersion fields
            s = obj.setCompatibleVersionLimit(s, 1);
            s.incompatibilityMsg = '';
        end

        function obj = loadFromStruct(obj, s)
        % Set properties defined in ImportOptions
            obj = loadFromStruct@matlab.io.ImportOptions(obj, s);

            for prop = obj.saveLoadNames
                obj = trySetProp(obj, s, prop);
            end
        end
    end

    methods(Hidden)
        function s = saveobj(obj)
            s = obj.saveToStruct();
        end
    end

    methods(Static, Hidden)
        function obj = loadobj(serialized)
        % always construct a default WordDocumentImportOptions
            obj = matlab.io.word.WordDocumentImportOptions();

            % Return a default WordDocumentImportOptions if the current object
            % version is less than the minimum compatible version of the
            % serialized object.
            if obj.isIncompatible(serialized, 'MATLAB:io:word:saveload:IncompatibleLoad')
                return;
            end
            obj = loadFromStruct(obj, serialized);
        end
    end

    methods(Access = protected)
        function obj = updatePerVarSizes(obj,nNew)
        end

        function addCustomPropertyGroups(opts,helper)
            addPropertyGroup(helper,...
                             getString(message('MATLAB:textio:importOptionsProperties:Replacement')),opts,...
                             {'MissingRule','ImportErrorRule','EmptyRowRule',...
                             'MergedCellColumnRule','MergedCellRowRule','ExtraColumnsRule'});

            varStruct.VariableNames = opts.VariableNames;
            varStruct.VariableTypes = opts.VariableTypes;
            varStruct.SelectedVariableNames = opts.SelectedVariableNames;
            varStruct.VariableOptions = [];
            varStruct.VariableNamingRule = opts.VariableNamingRule;

            addPropertyGroup(helper,...
                             getString(message('MATLAB:textio:importOptionsProperties:VariableImport')),varStruct);

            addPropertyGroup(helper,...
                             getString(message('MATLAB:textio:importOptionsProperties:Location')),opts,...
                             {'TableSelector','DataRows','VariableNamesRow',...
                                'VariableUnitsRow', 'VariableDescriptionsRow', 'RowNamesColumn'});
        end

        function modifyCustomGroups(opts,helper)
        end

        function verifyMaxVarSize(obj,n)
        end
    end

    methods(Static, Access = protected)
        function props = getTypeSpecificProperties()
            props = ["TableSelector", "VariableNamesRow", ...
                "VariableUnitsRow", "RowNamesColumn", "EmptyRowRule"];
        end
    end
end

function obj = trySetProp(obj, s, prop)
% Tries to set property to the saved value.
    try
        obj.(prop) = s.(prop);
    catch ME
        % Don't warn if the property is not a field on the struct. This
        % may happen when loading an object saved in a previous release.
        if ~strcmp(ME.identifier, "MATLAB:nonExistentField")
            % On error, the property is left as the default value.
            warning(message('MATLAB:io:word:saveload:IncompatiblePropertyLoad',...
                            'matlab.io.word.WordDocumentImportOptions', prop));
        end
    end
end
