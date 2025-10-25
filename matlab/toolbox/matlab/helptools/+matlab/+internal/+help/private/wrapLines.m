function str = wrapLines(str, wantHyperlinks)
    str = matlab.internal.display.printWrapped(str, lineLength, wantHyperlinks);
end

%   Copyright 2021-2022 The MathWorks, Inc.
