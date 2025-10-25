function [result, info] = convertStringToHomogeneousType(str, varopts)
%

%   Copyright 2024 The MathWorks, Inc.

    whitespace = sprintf(' \t\n\r');

    [result, info] = matlab.io.text.internal.convertFromText(varopts, str, whitespace);
end
