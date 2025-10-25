classdef ReadCell < matlab.io.internal.functions.DetectImportOptions ...
        & matlab.io.internal.functions.ReadCellWithImportOptions ...
        & matlab.io.internal.functions.HasAliases
    %
    
    %   Copyright 2018-2021 The MathWorks, Inc.
    
    methods
        function [func,supplied,other] = validate(func,varargin)
            [func,supplied,other] = validate@matlab.io.internal.functions.DetectImportOptions(func,varargin{:});
            validateSupportedFileType(func);
            matlab.io.internal.functions.parameter.assertNoRowNamesInputs(supplied);
            matlab.io.internal.functions.parameter.assertNoVariableNameInputs(supplied);
           
            if supplied.TreatAsMissing
                error(message('MATLAB:textio:readmatrix:UnsupportedTreatAsMissing'));
            end

            for name = ["EmptyValue","DecimalSeparator","ThousandsSeparator","TrimNonNumeric","HexType","BinaryType"]
                if supplied.(name)
                    error(message('MATLAB:textio:textio:UnknownParameter',name));
                end
            end
        end
        
        function C = execute(func,supplied)
            % Variable Names shouldn't be automatically detected for cell,
            % they are just the same as everything else.
            func.ReadVariableNames = false; supplied.ReadVariableNames = true;
            % assume header lines is supplied. even header info should be
            % imported. Only really detecting delimiters.
            if ~supplied.NumHeaderLines && ~(supplied.Range || supplied.DataRange)
                func.NumHeaderLines = 0;
                supplied.NumHeaderLines = true;
            end
            
            % readcell does not detect non-empty header lines
            func.DetectHeader = false;
            
            func.DetectMetaLines = false;
            func.Options = func.execute@matlab.io.internal.functions.DetectImportOptions(supplied);
            if isa(func.Options, "matlab.io.text.TextImportOptions") && ~supplied.Range
                func.Options.DataLines = [1+func.NumHeaderLines,inf];
            end
            C = func.execute@matlab.io.internal.functions.ReadCellWithImportOptions(supplied);
        end
        
        function names = usingRequired(~)
            names = "Filename";
        end
        
        function v = getAliases(obj)
            v = [obj.getAliases@matlab.io.internal.functions.DetectImportOptions(),...
                obj.getAliases@matlab.io.internal.functions.ReadCellText()];
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
            functionName = "readcell";
            if func.FileType == "xml"
                error(message("MATLAB:io:xml:common:UnsupportedFileTypeXML", functionName));
            elseif all(func.FileType ~= ["text", "delimitedtext", "fixedwidth", "spreadsheet"])
                error(message("MATLAB:textio:detectImportOptions:UnsupportedFileTypeForFunction", functionName, func.FileType));
            end
        end
        
    end
    
end

