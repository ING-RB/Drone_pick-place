% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality for Parquet file import.

% Copyright 2020-2023 The MathWorks, Inc.

classdef ParquetImportProvider < matlab.internal.importdata.ImportProvider
        
    methods
        function this = ParquetImportProvider(filename)
            % Create an instance of an ParquetImportProvider

            arguments
                filename (1,1) string = "";
            end
            
            this = this@matlab.internal.importdata.ImportProvider(filename);
            
            this.FileType = "parquet";
            this.HeaderComment = "% " + getString(message("MATLAB:datatools:importdata:CodeCommentParquet"));
        end

        function lst = getSupportedFileExtensions(~)
            lst = "parquet";
        end

        function summary = getTaskSummary(task)
            if isempty(task.getFullFilename) || strlength(task.getFullFilename) == 0
                summary = "";
            else
                [~, file, ext] = fileparts(task.getFullFilename);
                summary = getString(message("MATLAB:datatools:importdata:ParquetSummary", "`" + file + ext + "`"));
            end
        end
        
        function code = getImportCode(this)
            % Returns the import code to be executed.  The code will be
            % something like:
            %
            % sample = imread("sample.parquet");

            arguments
                this (1,1) matlab.internal.importdata.ParquetImportProvider
            end
            
            [~, varName, ~] = fileparts(this.getFullFilename);
            varName = this.getUniqueVarName(varName);
            code = varName + " = parquetread(""" + this.getFullFilename + """);";
            this.LastCode = code;
        end
    end
end
