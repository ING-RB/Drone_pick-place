classdef ReadCellText < matlab.io.internal.functions.ExecutableFunction ...
        & matlab.io.internal.functions.AcceptsReadableFilename ...
        & matlab.io.internal.functions.AcceptsImportOptions ...
        & matlab.io.internal.functions.AcceptsDateLocale ...
        & matlab.io.internal.shared.EncodingInput ...
        & matlab.io.internal.shared.ReadTableInputs ...
        & matlab.io.internal.functions.AcceptsDatetimeTextType ...
        & matlab.io.internal.functions.AcceptsDurationType
    %
    
    % Copyright 2018-2022 The MathWorks, Inc.
    properties (Parameter)
        MaxRowsRead(1,1) double = inf;
    end
    
    methods
        
        function C = execute(func, supplied)
            checkWrongParamsWrongType(supplied);
            % Use the override encoding
            if supplied.Encoding
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

            reader = matlab.io.text.internal.TabularTextReader(func.Options,...
                        struct('Filename',func.LocalFileName,...
                               'OutputType','cell',...
                               'DateLocale',func.DateLocale,...
                               'MaxRowsToRead',func.MaxRowsRead,...
                               'DatetimeType',func.DatetimeType,...
                               'DurationType',func.DurationType,...
                               'TextType',func.TextType));
                   
            C = reader.read();
        end
    end
end

function checkWrongParamsWrongType(supplied)
persistent params
if isempty(params)
    me = {?matlab.io.internal.functions.AcceptsSheetNameOrNumber, ...
        ?matlab.io.internal.functions.AcceptsUseExcel};
    params = cell(1,numel(me));
    for i = 1:numel(me)
        params{i} = string({me{i}.PropertyList([me{i}.PropertyList.Parameter]).Name});
    end
    params = [params{:}];
end
matlab.io.internal.utility.assertUnsupportedParamsForFileType(params,supplied,'text');
end
