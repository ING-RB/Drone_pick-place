classdef ReadVars < matlab.io.internal.functions.DetectImportOptions ...
        & matlab.io.internal.functions.ReadVarsWithImportOptions ...
        & matlab.io.internal.functions.HasAliases
    %
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    methods (Access = protected)
        function [rhs,obj] = setSheet(obj,rhs)
            [rhs,obj] = obj.setSheet@matlab.io.internal.functions.DetectImportOptions(rhs);
        end
        
        function val = getSheet(obj,val)
            val = obj.getSheet@matlab.io.internal.functions.DetectImportOptions(val);
        end
    end
    
    methods
        function names = usingRequired(~)
            names = "Filename";
        end
        
        function v = getAliases(func)
            v = [func.getAliases@matlab.io.internal.functions.DetectImportOptions(),...
                 func.getAliases@matlab.io.internal.functions.ReadTableWithImportOptions()];
        end
        
        function [func,supplied,other] = validate(func,varargin)
            [func,supplied,other] = validate@matlab.io.internal.functions.DetectImportOptions(func,varargin{:});
            validateSupportedFileType(func);
            matlab.io.internal.functions.parameter.assertNoRowNamesInputs(supplied);
            matlab.io.internal.functions.parameter.assertNoVariableNameInputs(supplied);
        end
        
        function varargout = execute(func,supplied)
            func.ReadVariableNames = false; supplied.ReadVariableNames = true;
            % With properties all validated, any shared properties don't need to be re-validated.
            % execute calls are written to accept pre-validated inputs
            func.DetectHeader = true;
            func.Options = func.execute@matlab.io.internal.functions.DetectImportOptions(supplied);
            
            [varargout{1:nargout}] = func.execute@matlab.io.internal.functions.ReadVarsWithImportOptions(supplied);
            
        end
        
        function exts = getExtensions(obj)
            exts = obj.getExtensions@matlab.io.internal.functions.DetectImportOptions();
        end
    end
    
    methods (Access = private)
        
        function validateSupportedFileType(func)
            functionName = "readvars";
            if func.FileType == "xml"
                error(message("MATLAB:io:xml:common:UnsupportedFileTypeXML", functionName));
            elseif all(func.FileType ~= ["text", "delimitedtext", "fixedwidth", "spreadsheet"])
                error(message("MATLAB:textio:detectImportOptions:UnsupportedFileTypeForFunction", functionName, func.FileType));
            end
        end
        
    end
    
end
