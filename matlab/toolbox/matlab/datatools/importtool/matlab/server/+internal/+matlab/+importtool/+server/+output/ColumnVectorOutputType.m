% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents Column Vector Output Data Type from Import.

% Copyright 2018-2022 The MathWorks, Inc.

classdef ColumnVectorOutputType < internal.matlab.importtool.server.output.OutputTypeAdapter & ...
        internal.matlab.importtool.server.output.OutputColumnNameStrategy

    methods
        function this = ColumnVectorOutputType
            this@internal.matlab.importtool.server.output.OutputTypeAdapter;
            this.setColumnNameStrategy(this);
        end

        function [vars, varNames] = convertFromImportedData(~, tbl)
            % Extract the variables from the table as separate variables.
            % Ideally there would be an extractVariables table method to do
            % this.
            varNames = string(tbl.Properties.VariableNames);
            vars = cell(size(varNames));
            count = length(varNames);
            for idx = 1:count
                vars{idx} = tbl.(idx);
            end
        end

        function [code, clearVarName] = getCodeToConvertFromImportedData(this, varName, imopts)
            % Generates the code to convert from a table to separate column
            % vectors
            clearVarName = string(varName);
            if ismember('omitvar', [imopts.ImportErrorRule, imopts.MissingRule])
                % Columns we want to assign may have been excluded due to other
                % rules.  Use a loop instead, which will do the assignments
                % based on the table variables
                code(1) = "for idx = 1:length(" + varName + ".Properties.VariableNames)";
                code(2) = "eval(" + varName + ".Properties.VariableNames{idx} + "" = " + ...
                    varName + ".(idx);"");";
                code(3) = "end";
                clearVarName(2) = "idx";
            elseif length(imopts.SelectedVariableNames) == 1
                code = imopts.SelectedVariableNames(1) + " = " + varName + "." + ...
                    imopts.SelectedVariableNames(1);
                if ~this.showLastOutput
                    code = code + ";";
                end
            else
                % Do the assignments one by one.  For example:
                %     Index = tbl.Index;
                %     Temperature = tbl.Temperature;
                code = strings(length(imopts.SelectedVariableNames), 1);
                for idx = 1:length(imopts.SelectedVariableNames)
                    v = imopts.SelectedVariableNames(idx);
                    code(idx) = v + " = " + varName + "." + v + ";";
                end
            end
        end

        function code = getFunctionHeaderCode(~)
            % Returns the column vectors header line for the function
            code = internal.matlab.importtool.server.ImportUtils.getImportToolMsgFromTag("Codgen_ColumnVectorsHeader");
        end

        function columnNames = getColumnNamesForImport(~, defaultColumnNames)
            % Column vectors require avoiding all shadowing, so the user doesn't
            % end up creating variables with Matlab identifier names, or names
            % which overwrite workspace variable names.
            avoidShadow = struct('isAvoidSomeShadows', false, ...
                'isAvoidAllShadows', true);
            varNames = evalin('base', 'who');
            columnNames = internal.matlab.importtool.server.ImportUtils.getDefaultColumnNames(...
                varNames, defaultColumnNames, -1, avoidShadow, false);
        end
    end
end
