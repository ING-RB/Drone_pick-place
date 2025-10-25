function color = defaultprtcolor(varargin)
%DEFAULTPRTCOLOR Retrieve  color mode for the default printer (1=color; 0=mono)

%   Copyright 1984-2023 The MathWorks, Inc.
dev = queryPrintServices('getdefaultandlist');
if ~queryPrintServices('validate', dev)
    dev = matlab.graphics.internal.export.getDefaultPrintDevice();
end
color = queryPrintServices('supportscolor', dev);

end
