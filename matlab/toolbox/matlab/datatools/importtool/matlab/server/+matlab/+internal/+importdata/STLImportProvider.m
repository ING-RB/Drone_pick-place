% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality for STL file import.

% Copyright 2020-2023 The MathWorks, Inc.

classdef STLImportProvider < matlab.internal.importdata.ImportProvider
    
    methods
        function this = STLImportProvider(filename)
            % Create an instance of an STLImportProvider
            
            arguments
                filename (1,1) string = "";
            end
            
            this = this@matlab.internal.importdata.ImportProvider(filename);
            
            this.FileType = "stl";
            this.HeaderComment = "% " + getString(message("MATLAB:datatools:importdata:CodeCommentSTL"));
        end

        function lst = getSupportedFileExtensions(~)
            lst = "stl";
        end

        function summary = getTaskSummary(task)
            if isempty(task.getFullFilename) || strlength(task.getFullFilename) == 0
                summary = "";
            else
                [~, file, ext] = fileparts(task.getFullFilename);
                summary = getString(message("MATLAB:datatools:importdata:STLSummary", "`" + file + ext + "`"));
            end
        end
        
        function code = getImportCode(this)
            % Returns the import code to be executed.  The code will be
            % something like:
            %
            % sample = imread("sample.stl");
            
            arguments
                this (1,1) matlab.internal.importdata.STLImportProvider
            end
            
            [~, varName, ~] = fileparts(this.getFullFilename);
            varName = this.getUniqueVarName(varName);
            code = varName + " = stlread(""" + this.getFullFilename + """);";
            this.LastCode = code;
        end
    end
end
