classdef FileExtensions
% Encapsulates supported file extensions for xml, text, and spreadsheet files
    
    % Copyright 2018-2024 The MathWorks, Inc.

    properties (Constant)
        TextExtensions        = [".txt", ".dat", ".csv", ".log", ".text", ".dlm", ".asc"];
        SpreadsheetExtensions = [".xlsx", ".xls", ".xlsb", ".xlsm", ".xltm", ".xltx", ".ods"];
        XMLExtensions         = ".xml";
        HTMLExtensions        = [".html",".htm",".xhtml",".xhtm"];
        WordDocumentExtensions        = ".docx";
        JSONExtensions        = ".json";
        AllExtensions = [...
            matlab.io.internal.FileExtensions.TextExtensions,...
            matlab.io.internal.FileExtensions.SpreadsheetExtensions,...
            matlab.io.internal.FileExtensions.XMLExtensions,...
            matlab.io.internal.FileExtensions.HTMLExtensions,...
            matlab.io.internal.FileExtensions.WordDocumentExtensions];
    end

    methods (Abstract)
        getFileTypeFromExtension(ext);
    end

    methods (Static)
        function exts = getExtensionsFromType(type)
            type = convertStringsToChars(lower(type));
            switch(type)
                case {'', 'auto'}
                    exts = matlab.io.internal.FileExtensions.AllExtensions;
                case {'text','delimitedtext','fixedwidth'}
                    exts = matlab.io.internal.FileExtensions.TextExtensions;
                case 'spreadsheet'
                    exts = matlab.io.internal.FileExtensions.SpreadsheetExtensions;
                case 'xml'
                    exts = matlab.io.internal.FileExtensions.XMLExtensions;
                case {'html','htm','xhtml','xhtm'}
                    exts = matlab.io.internal.FileExtensions.HTMLExtensions;
                case 'worddocument'
                    exts = matlab.io.internal.FileExtensions.WordDocumentExtensions;
                case 'json'
                    exts = matlab.io.internal.FileExtensions.JSONExtensions;
                otherwise
                    assert(false,"Not a valid file type");
            end
        end
    end
end
