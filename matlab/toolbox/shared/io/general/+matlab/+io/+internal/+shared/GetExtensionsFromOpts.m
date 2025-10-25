classdef GetExtensionsFromOpts < matlab.io.internal.functions.ExecutableFunction
    %
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    methods
        function [func,supplied,other] = validate(func,varargin)
            % Any function using this assumes the options are second
            % argument
            func.Options = varargin{2};
            [func,supplied,other] = validate@matlab.io.internal.functions.ExecutableFunction(func,varargin{:});
        end
        
        function exts = getExtensions(func)
            if isa(func.Options,'matlab.io.text.TextImportOptions')
                exts = matlab.io.internal.FileExtensions.TextExtensions;
            elseif isa(func.Options,'matlab.io.spreadsheet.SpreadsheetImportOptions')
                exts = matlab.io.internal.FileExtensions.SpreadsheetExtensions;
            elseif isa(func.Options,'matlab.io.xml.XMLImportOptions')
                exts = matlab.io.internal.FileExtensions.XMLExtensions;
            elseif isa(func.Options,'matlab.io.html.HTMLImportOptions')
                exts = matlab.io.internal.FileExtensions.HTMLExtensions;
            elseif isa(func.Options,'matlab.io.word.WordDocumentImportOptions')
                exts = matlab.io.internal.FileExtensions.WordDocumentExtensions;
            else
                assert(false,"Not a supported Import Options Type.")
            end
        end
    end
end

