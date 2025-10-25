function [convertedData,info] = convertFromText(varopts,textdata,whitespace)
% Converts a text array according to the rules of a variable import options object.

% Copyright 2020-2022 The MathWorks, Inc.

    if nargin < 3
        whitespace = sprintf(' \b\t');
    end
    [convertedData, info] = matlab.io.text.internal.TextConverter.convert(varopts,...
        textdata, whitespace);
end
