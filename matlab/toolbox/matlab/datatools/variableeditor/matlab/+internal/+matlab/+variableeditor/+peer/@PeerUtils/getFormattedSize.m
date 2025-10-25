% Returns the formatted size

% Copyright 2014-2024 The MathWorks, Inc.

function formattedSize = getFormattedSize(s)
    if length(s)>3
        formattedSize = sprintf('%d-D',length(s));
    else
        formattedSize = regexprep(num2str(s),' +', ...
            internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL);
    end
end