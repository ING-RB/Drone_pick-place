function openPort = getDebugPort()
%getDebugPort()   finds the debug  Network Port

% Copyright 2020-2023 The MathWorks, Inc.

% Disable debug port if we are not in MW env
if isempty(getenv("MW_INSTALL"))
    openPort = 0;
    return;
end

if feature('webui')
    if getenv("MW_STARTER_JSD_DEBUG_PORT")
        envPort = str2double(getenv("MW_STARTER_JSD_DEBUG_PORT"));
        openPort = int32(envPort);
        return;
    end
end

openPort = matlab.internal.cef.getDebugPort();
