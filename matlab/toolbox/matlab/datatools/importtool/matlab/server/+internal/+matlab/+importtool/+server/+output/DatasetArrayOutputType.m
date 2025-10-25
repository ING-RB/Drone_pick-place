% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents a Dataset Array Output Data Type from Import.

% Copyright 2018-2019 The MathWorks, Inc.

classdef DatasetArrayOutputType < internal.matlab.importtool.server.output.OutputTypeAdapter
    methods
        function [vars, varNames] = convertFromImportedData(~, tbl)
            % Convert from table to dataset array
            vars = table2dataset(tbl);
            vars.Properties.DimNames = {'Observations'  'Variables'};
            varNames = [];
        end
        
        function [code, varsToClear] = getCodeToConvertFromImportedData(~, varName, ~)
            % Generates the code to convert from a table to a dataset array
            code = varName + " = table2dataset(" + varName + ");";
            code(2) = varName + ".Properties.DimNames = {'Observations'  'Variables'};";
            varsToClear = "";
        end
        
        function code = getFunctionHeaderCode(~)
            % Returns the dataset header line for the function
            code = internal.matlab.importtool.server.ImportUtils.getImportToolMsgFromTag("Codgen_DatasetHeader");
        end
    end
end
