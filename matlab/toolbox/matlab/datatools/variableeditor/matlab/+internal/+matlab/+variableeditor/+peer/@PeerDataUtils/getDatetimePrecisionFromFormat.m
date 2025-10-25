% Returns the datetime precision from the format

% Copyright 2017-2023 The MathWorks, Inc.

function precision = getDatetimePrecisionFromFormat(formatString)
    if contains(formatString, 's')
        precision = 'second';
    elseif contains(formatString, 'm')
        precision = 'minute';
    elseif (contains(formatString, 'h') || contains(formatString, 'H'))
        precision = 'hour';
    elseif (contains(formatString, 'D') || contains(formatString, 'd') || contains(formatString, 'e'))
        precision = 'day';
    elseif contains(formatString, 'W')
        precision = 'week';
    elseif contains(formatString, 'M')
        precision = 'month';
    elseif contains(formatString, 'Q')
        precision = 'quarter';
    else
        precision = 'year';
    end
end
