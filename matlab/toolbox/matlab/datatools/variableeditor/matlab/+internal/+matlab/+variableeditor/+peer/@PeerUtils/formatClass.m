% returns the formatted class based on the type of data. Summarybar descriptions
% in VE have a more descriptive format for complex/sparse numeric types.

% Copyright 2014-2023 The MathWorks, Inc.

function formattedClass = formatClass(cdata)
    if isa(cdata, 'internal.matlab.variableeditor.NullValueObject')
        % Treat the internal NullValueObject as not having a class (we don't
        % want it to show in the summary of a variable, for example).
        formattedClass = '';
    else
        %TODO: need to account for global variables
        cClass = strsplit(class(cdata), ".");
        formattedClass = cClass{end};
        type='';
        try
            if (isnumeric(cdata) && ~isreal(cdata))
                type='complex ';
            end
            if (issparse(cdata))
                if ~isreal(cdata)
                    type='sparse complex ';
                else
                    type='sparse ';
                end
            end
        catch
            % Ignore any errors, assume not sparse or complex
        end
        formattedClass = [type formattedClass];
    end
end