% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents a String Array Output Data Type from Import.

% Copyright 2018-2020 The MathWorks, Inc.

classdef StringArrayOutputType < internal.matlab.importtool.server.output.OutputTypeAdapter
    methods
        function this = StringArrayOutputType
            this@internal.matlab.importtool.server.output.OutputTypeAdapter;
            
            outputStrategy = internal.matlab.importtool.server.output.SingleOutputColumnClassStrategy("string");
            this.setColumnClassStrategy(outputStrategy);
            
            classOptionsStrategy = internal.matlab.importtool.server.output.EmptyColumnClassOptionsStrategy();
            this.setColumnClassOptionsStrategy(classOptionsStrategy);
        end

        function [vars, varNames] = convertFromImportedData(~, s)
            % No conversion needed.  Data is already a string array.
            vars = s;
            varNames = [];
        end
        
        function [code, varsToClear] = getCodeToConvertFromImportedData(~, ~, ~)
            % No conversion needed.  Data is already a string array.
            code = "";
            varsToClear = "";
        end
        
        function code = getFunctionHeaderCode(~)
            % Returns the string array header line for the function
            code = internal.matlab.importtool.server.ImportUtils.getImportToolMsgFromTag("Codgen_StringArrayHeader");
        end
        
        % Returns the function handle of the function used to perform the
        % import.  
        function fcnHandle = getImportFunction(~)
            % Imports using readmatrix
            fcnHandle = @readmatrix;
        end
        
        % Returns the name of the function used to perform the import.
        function fcnHandleName = getImportFunctionName(~)
            % Imports using readmatrix
            fcnHandleName = "readmatrix";
        end
        
        function b = requiresOutputConversion(~)
            b = false;
        end
        
        function s = getOutputTypeInitializerForCodeGen(~)
            % Because string arrays are read in using readmatrix, the
            % initialization for the output type needs to be a string.
            s = "strings(0)";
        end
    end
end
