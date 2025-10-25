classdef ReadTable < matlab.io.internal.functions.ExecutableFunction ...
        & matlab.io.internal.functions.DetectImportOptions ...
        & matlab.io.internal.functions.ReadTableWithImportOptions ...
        & matlab.io.internal.shared.TreatAsMissingInput ...
        & matlab.io.internal.functions.HasAliases
    %

    %   Copyright 2018-2020 The MathWorks, Inc.

    methods
        function t = execute(func,supplied)
        % Detect the appropriate object by file type
            if ~supplied.EmptyColumnType
                func.EmptyColumnType = 'double';
            end
            if supplied.Delimiter
                d = string(func.Delimiter);
                if isscalar(d)
                    switch (d{1})
                      case 'comma'
                        func.Delimiter = ',';
                      case 'semi'
                        func.Delimiter = ';';
                      case 'space'
                        func.Delimiter = ' ';
                      case 'tab'
                        func.Delimiter = '\t';
                      case 'bar'
                        func.Delimiter = '|';
                    end
                end
            end
            
            func.DetectHeader = true;
            func.Options = func.execute@matlab.io.internal.functions.DetectImportOptions(supplied);
            if supplied.Encoding
                % The import options now carries the encoding. No need to
                % pass it on.
                supplied.Encoding = false;
            end
            if supplied.TreatAsMissing && ~isempty(func.TreatAsMissing)
                func.Options = func.Options.setvaropts(func.Options.SelectedVariableNames,...
                                                       'TreatAsMissing',func.TreatAsMissing);
            end

            t = func.execute@matlab.io.internal.functions.ReadTableWithImportOptions(supplied);
            if height(t) > 0
                names = t.Properties.VariableNames;
                extraIdx = numel(func.Options.VariableNames)+1:width(t);
                names = matlab.lang.makeUniqueStrings(compose('Var%d',extraIdx),names,namelengthmax);
                t.Properties.VariableNames(extraIdx) = names;
            end

        end

        function names = usingRequired(~)
            names = "Filename";
        end

        function v = getAliases(obj)
            v = [obj.getAliases@matlab.io.internal.functions.DetectImportOptions(),...
                 obj.getAliases@matlab.io.internal.functions.ReadTableWithImportOptions();];
        end

        function exts = getExtensions(obj)
            exts = obj.getExtensions@matlab.io.internal.functions.DetectImportOptions();
        end


        function [func,supplied,other] = validate(func,varargin)
            [func,supplied,other] = validate@matlab.io.internal.functions.DetectImportOptions(func,varargin{:});
        end
    end

    methods (Access = protected)
        function [rhs,obj] = setSheet(obj,rhs)
            [rhs,obj] = obj.setSheet@matlab.io.internal.functions.DetectImportOptions(rhs);
        end

        function val = getSheet(obj,val)
            val = obj.getSheet@matlab.io.internal.functions.DetectImportOptions(val);
        end
    end


    methods (Static)
        function t = buildTableFromData(data, varNames, rowNames, dimNames, readVarNames, readRowNames, preserveVariableNames)

        % Change variable name validation and fixing behavior based on the value
        % of PreserveVariableNames.
            if preserveVariableNames
                variableNameBehavior = 'warnSaved';
            else
                % The legacy behavior is to normalize to valid MATLAB identifiers.
                variableNameBehavior = 'warnSavedLegacy';
            end

            % Set the var names.  These will be modified to make them valid, and the
            % original strings saved in the VariableDescriptions property.  Fix up duplicate
            % or empty names.
            validNames = matlab.internal.tabular.private.varNamesDim.makeValidName(varNames, variableNameBehavior);
            validNames = matlab.lang.makeUniqueStrings(validNames,{},namelengthmax);
            dimNames = matlab.lang.makeValidName(dimNames);
            
            % From 21a table errors when the dimension names conflict with one
            % of the reserved names. For backwards compatibility, fix those
            % names before checking for conflicts with variable names.
            dimNames = matlab.internal.tabular.private.metaDim.fixLabelsForCompatibility(dimNames);

            if readVarNames
                reservedNames = [validNames(:); dimNames{1}];
                if any(strcmp(dimNames{2},reservedNames))
                    % Make sure var names and dim names don't conflict. That could happen if var
                    % names read from the file are the same as the default dim names (when ReadRowNames
                    % is false), or same as the first dim name read from the file (ReadRowNames true).
                    dimNames{2} = matlab.lang.makeUniqueStrings(dimNames{2},reservedNames,namelengthmax);
                end
            else
                dimNames{2} = 'Variables';
            end

            if readRowNames
                rowNames = matlab.internal.tabular.private.rowNamesDim.makeValidName(rowNames, 'silent');
            end

            % make dimNames and validNames unique
            dimnames = convertCharsToStrings(dimNames);
            validnames = convertCharsToStrings(validNames);
            if any(dimnames(:)' == validnames(:), 'all')
                dimNames = matlab.lang.makeUniqueStrings(dimNames,validNames,namelengthmax);
            end

            numVars = numel(data);
            if numVars > 0
                numRows = size(data{1}, 1);
            else
                numRows = numel(rowNames);
            end
            t = table.init(data,numRows,rowNames,numVars,validNames,dimNames);
            if numVars > 0 && any(~strcmp(validNames,varNames))
                t.Properties.VariableDescriptions = varNames;
            end
        end
    end
end
