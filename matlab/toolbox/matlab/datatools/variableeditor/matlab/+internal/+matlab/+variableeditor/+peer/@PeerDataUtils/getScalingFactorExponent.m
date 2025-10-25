% Gets the scaling factor exponent

% Copyright 2017-2023 The MathWorks, Inc.

function exponent = getScalingFactorExponent(scalingFactorString)
    exponent = 1;
    if ~isempty(scalingFactorString)
        exponent = log10(str2double(strtrim(strrep(scalingFactorString, '*', ''))));
    end
end
