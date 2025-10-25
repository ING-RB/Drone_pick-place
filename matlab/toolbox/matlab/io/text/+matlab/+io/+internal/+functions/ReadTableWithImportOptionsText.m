classdef ReadTableWithImportOptionsText < matlab.io.internal.functions.ExecutableFunction &...
        matlab.io.internal.functions.AcceptsReadableFilename &...
        matlab.io.internal.functions.AcceptsImportOptions &...
        matlab.io.internal.functions.AcceptsDateLocale &...
        matlab.io.internal.shared.EncodingInput &...
        matlab.io.internal.shared.ReadTableInputs &...
        matlab.io.internal.shared.HasOmitted
    %

    % Copyright 2018-2020 The MathWorks, Inc.

    properties (Parameter)
        MaxRowsRead(1,1) double = inf;
    end

    methods
        function [T,func] = executeImpl(func,supplied)
            checkWrongParamsWrongType(supplied)
            usingRowNames = (func.Options.RowNamesColumn > 0);
            if func.ReadRowNames && ~usingRowNames
                func.Options.RowNamesColumn = 1;
            elseif supplied.ReadRowNames && ~func.ReadRowNames && usingRowNames
                func.Options.RowNamesColumn = 0;
            end

            if ~supplied.ReadVariableNames ...
                    && func.Options.namesAreGenerated() ...
                    && func.Options.VariableNamesLine > 0
                func.ReadVariableNames = true;
                supplied.ReadVariableNames = true;
            end

            readVarNames = func.Options.VariableNamesLine > 0 && supplied.ReadVariableNames && func.ReadVariableNames;
            if ~readVarNames
                func.Options.VariableNamesLine = 0;
            end
            
            % Use the override encoding
            if supplied.Encoding
                if isempty(func.Encoding)
                    func.Encoding = func.detectEncodingFromFilename(func.LocalFileName);
                end
                func.Options.Encoding = func.Encoding;
            end

            % Use the override date locale.
            if supplied.DateLocale
                % Validate the locale
                dates = strcmp(func.Options.VariableTypes,'datetime');
                if any(dates)
                    func.Options = func.Options.setvaropts(dates,'DatetimeLocale',func.DateLocale);
                end
            end

            rdr = matlab.io.text.internal.TabularTextReader(func.Options, ...
                struct('Filename',func.LocalFileName, ...
                'OutputType','table', ...
                'DateLocale',func.DateLocale, ...
                'MaxRowsToRead',func.MaxRowsRead));

            [T, info] = rdr.read();
            func.Omitted = info.Omitted;
        end
        
        function T = execute(func, supplied)
            T = func.executeImpl(supplied);
        end
    end
end

%%
function checkWrongParamsWrongType(supplied)
persistent params
if isempty(params)
    getParams = @(me) string({me.PropertyList([me.PropertyList.Parameter]).Name});
    params = getParams(?matlab.io.internal.functions.ReadTableWithImportOptionsSpreadsheet);
    params = setdiff(params, [getParams(?matlab.io.internal.shared.ReadTableInputs), ...
                             getParams(?matlab.io.internal.functions.AcceptsReadableFilename)]);
end
matlab.io.internal.utility.assertUnsupportedParamsForFileType(params,supplied,'text')
end
