classdef AcceptsFileType < matlab.io.internal.functions.ExecutableFunction
%

%   Copyright 2018-2024 The MathWorks, Inc.


    properties (Abstract, Constant, Access = protected)
        SupportedFileTypes(1, :) string;
    end

    properties (Parameter)
        FileType = ''
    end

    methods
        function func = set.FileType(func,rhs)
            isCorrectString = isstring(rhs) && isscalar(rhs) && ...
                ~ismissing(rhs) && rhs ~= "";
            isCorrectChar = ischar(rhs) && ~isempty(rhs);
            if ~isCorrectString && ~isCorrectChar
                error(message("MATLAB:textio:textio:IncorrectTypeFileType"));
            end
            rhs = strip(string(rhs));
            func.FileType = char(validatestring(rhs,func.SupportedFileTypes, ...
                "","'FileType'"));
        end

        function exts = getExtensions(func)
            exts = matlab.io.internal.FileExtensions.getExtensionsFromType(func.FileType);
        end

        function filetype = getFileTypeFromExtension(func,defaultType)
            arguments
                func
                defaultType(1,1) = missing
            end
            
            assert(~ismissing(func.FilenameValidated),...
                "Implementation Error: cannot call this method before validating ""Filename""");
            
            ext = string(func.Extension);

            if any(strcmpi(ext,matlab.io.internal.FileExtensions.SpreadsheetExtensions))
                filetype = 'spreadsheet';
            elseif any(strcmpi(ext,matlab.io.internal.FileExtensions.XMLExtensions))
                filetype = 'xml';
            elseif any(strcmpi(ext,matlab.io.internal.FileExtensions.JSONExtensions))
                filetype = 'json';
            elseif any(strcmpi(ext,matlab.io.internal.FileExtensions.HTMLExtensions))
                filetype = 'html';
            elseif any(strcmpi(ext,matlab.io.internal.FileExtensions.WordDocumentExtensions))
                filetype = 'worddocument';
            elseif ~ismissing(defaultType) && ~(strlength(ext)>0) || any(strcmpi(ext, matlab.io.internal.FileExtensions.TextExtensions))
                filetype = defaultType;
            else
                if strlength(ext) == 0
                    if func.FileType == "auto"
                        error(message("MATLAB:io:xml:readstruct:FileTypeAutoWithNoFileExtension",func.InputFilename))
                    else
                        error(message('MATLAB:io:xml:readstruct:NoFileExtension',func.InputFilename));
                    end
                else
                    error(message('MATLAB:textio:detectImportOptions:UnrecognizedExtension',ext));
                end
            end
            if ~any(filetype==func.SupportedFileTypes)
                % error for files with known extensions, but the function
                % doesn't support them.
            end
        end
    end
end
