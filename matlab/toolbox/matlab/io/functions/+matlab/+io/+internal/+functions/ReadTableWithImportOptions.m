classdef ReadTableWithImportOptions < matlab.io.internal.functions.ExecutableFunction ...
        & matlab.io.internal.functions.ReadTableWithImportOptionsText ...
        & matlab.io.internal.functions.ReadTableWithImportOptionsSpreadsheet ...
        & matlab.io.internal.functions.ReadTableWithImportOptionsXML ...
        & matlab.io.internal.functions.ReadTableWithImportOptionsHTML ...
        & matlab.io.internal.functions.ReadTableWithImportOptionsWordDocument ...
        & matlab.io.internal.shared.GetExtensionsFromOpts
%

%   Copyright 2018-2024 The MathWorks, Inc.

    properties (Parameter)
        CollectOutput = false;
    end

    methods (Access = protected)
        function val = getSheet(obj,val)
            val = obj.getSheet@matlab.io.internal.functions.ReadTableWithImportOptionsSpreadsheet(val);
        end
    end

    methods
        function [T,func] = executeImpl(func,supplied)
            if isa(func.Options,'matlab.io.text.TextImportOptions')
                [T,func] = func.executeImpl@matlab.io.internal.functions.ReadTableWithImportOptionsText(supplied);
            elseif isa(func.Options,'matlab.io.spreadsheet.SpreadsheetImportOptions')
                [T,func] = func.executeImpl@matlab.io.internal.functions.ReadTableWithImportOptionsSpreadsheet(supplied);
            elseif isa(func.Options,'matlab.io.xml.XMLImportOptions')
                [T,func] = func.executeImpl@matlab.io.internal.functions.ReadTableWithImportOptionsXML(supplied);
            elseif isa(func.Options,'matlab.io.html.HTMLImportOptions')
                [T,func] = func.executeImpl@matlab.io.internal.functions.ReadTableWithImportOptionsHTML(supplied);
            elseif isa(func.Options,'matlab.io.word.WordDocumentImportOptions')
                [T,func] = func.executeImpl@matlab.io.internal.functions.ReadTableWithImportOptionsWordDocument(supplied);
            else
                assert(false);
            end

            if supplied.CollectOutput && func.CollectOutput
                T = matlab.io.text.internal.collectTableOutput(T);
            end
        end

        function T = execute(func,supplied)
            if isa(func.Options,'matlab.io.text.TextImportOptions')
                T = func.execute@matlab.io.internal.functions.ReadTableWithImportOptionsText(supplied);
            elseif isa(func.Options,'matlab.io.spreadsheet.SpreadsheetImportOptions')
                T = func.execute@matlab.io.internal.functions.ReadTableWithImportOptionsSpreadsheet(supplied);
            elseif isa(func.Options,'matlab.io.xml.XMLImportOptions')
                T = func.execute@matlab.io.internal.functions.ReadTableWithImportOptionsXML(supplied);
            elseif isa(func.Options,'matlab.io.html.HTMLImportOptions')
                T = func.execute@matlab.io.internal.functions.ReadTableWithImportOptionsHTML(supplied);
            elseif isa(func.Options,'matlab.io.word.WordDocumentImportOptions')
                T = func.execute@matlab.io.internal.functions.ReadTableWithImportOptionsWordDocument(supplied);
            else
                assert(false);
            end
        end

        function [func,supplied,other] = validate(func,varargin)
            [func,varargin] = extractArg(func,"WebOptions",varargin, 2);
            [func,supplied,other] = validate@matlab.io.internal.shared.GetExtensionsFromOpts(func,varargin{:});
        end
    end
end
