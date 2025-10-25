classdef ReadMatrix < matlab.io.internal.functions.DetectImportOptions ...
        & matlab.io.internal.functions.ReadMatrixWithImportOptions ...
        & matlab.io.internal.functions.HasAliases
    
    %
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    methods
        function [func,supplied,other] = validate(func,varargin)
            [func,supplied,other] = validate@matlab.io.internal.functions.DetectImportOptions(func,varargin{:});
            validateSupportedFileType(func);
            
            matlab.io.internal.functions.parameter.assertNoRowNamesInputs(supplied);
            matlab.io.internal.functions.parameter.assertNoVariableNameInputs(supplied);
            
            if supplied.TextType || supplied.DatetimeType || supplied.DurationType
                error(message('MATLAB:textio:readmatrix:UnsupportedTypeParam'));
            end
        end
        
        function A = execute(func,supplied)
            % If a "Range", or "DataRange" is supplied, then
            % it should always overrule all other detection heuristics.
            % In other words, the output matrix should always look like
            % whatever content is in the specified range.
            % We refer to this behavior as "preserving" the range.
            if supplied.Range || supplied.DataRange
                % Don't detect Metadata Lines.
                % Treat them like ordinary data.
                func.DetectMetaLines = false;
                % Don't detect Header Lines.
                % Treat them like ordinary data.
                func.DetectHeader = false;
                if ~supplied.NumHeaderLines
                    func.NumHeaderLines = 0;
                end
            end
            
            supplied.ReadVariableNames = true;
            func.ReadVariableNames = false;

            func.Options = func.execute@matlab.io.internal.functions.DetectImportOptions(supplied);
            func.Options = setvartype(func.Options,func.OutputType);
            func.Options = setVariableProps(func,supplied,func.Options);
           
            A = func.execute@matlab.io.internal.functions.ReadMatrixWithImportOptions(supplied);
        end
        
        function names = usingRequired(~)
            names = "Filename";
        end
        
        function v = getAliases(obj)
            v = [obj.getAliases@matlab.io.internal.functions.DetectImportOptions(),...
                obj.getAliases@matlab.io.internal.functions.ReadMatrixText()];
        end
        
        function exts = getExtensions(obj)
            exts = obj.getExtensions@matlab.io.internal.functions.DetectImportOptions();
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
    
    methods (Access = private)
        
        function validateSupportedFileType(func)
            functionName = "readmatrix";
            if func.FileType == "xml"
                error(message("MATLAB:io:xml:common:UnsupportedFileTypeXML", functionName));
            elseif all(func.FileType ~= ["text", "delimitedtext", "fixedwidth", "spreadsheet"])
                error(message("MATLAB:textio:detectImportOptions:UnsupportedFileTypeForFunction", functionName, func.FileType));
            end
        end
        
    end
    
end

