function list = bluetoothlist(varargin)
%BLUETOOTHLIST Scan nearby Bluetooth Classic devices.
%
%   list = BLUETOOTHLIST returns a table with information about found 
%   Bluetooth Classic devices.
%
%   list = BLUETOOTHLIST(Name, Value) returns a table using optional 
%   name-value pair arguments. Valid name-value pair is Timeout.
%
%   Examples: 
%       % Scans nearby Bluetooth Classic devices
%       list = bluetoothlist
%
%       % Scans nearby Bluetooth Classic devices for specified time
%       list = bluetoothlist("Timeout",10)
%
%   See also bluetooth

% Copyright 2020 The MathWorks, Inc.

    % Verify function is called on supported platforms, e.g. Windows and Mac
    try
        matlab.bluetooth.internal.validatePlatform;
    catch e
        throwAsCaller(e);
    end
    
    % Verify input parameters
    narginchk(0, 2);
    p = inputParser;
    p.CaseSensitive = false;
    id = "MATLAB:bluetooth:bluetoothlist:invalidTimeout";
    validateFcn = @(x) assert(isnumeric(x)&&isscalar(x)&&(x>=5), id, getString(message(id)));
    addParameter(p, "Timeout", [], validateFcn);
    try
        parse(p,varargin{:});
    catch e
        throwAsCaller(e);
    end
    
    % Scan current nearby devices
    try
        transport = matlab.bluetooth.internal.Factory.getListTransport;
        foundDevices = discoverDevices(transport, p.Results.Timeout);
    catch e
        throwAsCaller(e);
    end
    
    % Print blelist cross-reference text only when no output argument is specified
    if nargout == 0
        disp(getString(message("MATLAB:bluetooth:bluetoothlist:blelistReference")));
    end
    
    % Throw a warning when no device is found
    if isempty(foundDevices)
        id = "MATLAB:bluetooth:bluetoothlist:noDeviceFound";
        sWarningBacktrace = warning("off", "backtrace");
        warning(id, getString(message(id)));
        warning(sWarningBacktrace.state, "backtrace");
    end
    list = foundDevices;
end

