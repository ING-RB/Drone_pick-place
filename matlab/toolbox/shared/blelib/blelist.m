function list = blelist(varargin)
%BLELIST Scan nearby Bluetooth Low Energy peripheral devices.
%
%   list = BLELIST returns a table with information about nearby Bluetooth 
%   Low Energy peripheral devices that are advertising but not connected.
%
%   list = BLELIST(Name, Value) returns the table using optional name-value
%   pairs before scanning.
%
%   Examples: 
%       % Scans all nearby Bluetooth Low Energy peripherals
%       list = blelist
%
%       % Scans nearby Bluetooth Low Energy peripherals for specified time
%       list = blelist("Timeout", 10)
%
%       % Scans nearby Bluetooth Low Energy peripherals whose name starts
%       % with "UA" 
%       list = blelist("Name","UA")
%
%       % Scans nearby Bluetooth Low Energy peripherals that advertise the
%       specified services
%       list = blelist("Services","heart rate")
%       list = blelist("Services",0x180d)
%   	list = blelist("Services","180d")
%   	list = blelist("Services",["heart rate","running speed"])
%
%   See also ble

% Copyright 2019-2021 The MathWorks, Inc.

    try
        matlabshared.blelib.internal.validatePlatform;
    catch e
        throwAsCaller(e);
    end

    % Parse and validate input parameters
    p = inputParser;
    p.CaseSensitive = false;
    addParameter(p,'name', []);
    addParameter(p,'timeout', matlabshared.blelib.internal.Constants.DefaultScanTimeout);
    addParameter(p,'services', []);
    try
        parse(p,varargin{:});
        if ~ismember('name', p.UsingDefaults)
            name = validateName(p.Results.name);
        else
            name = p.Results.name;
        end
        if ~ismember('timeout', p.UsingDefaults)
            timeout  = validateTimeout(p.Results.timeout);
        else
            timeout = p.Results.timeout;
        end
        if ~ismember('services', p.UsingDefaults)
            services = validateServices(p.Results.services);
        else
            services = p.Results.services;
        end
    catch e
        % Rethrow BLE specific error messages if needed
        switch e.identifier
            case 'MATLAB:InputParser:ParamMustBeChar'    % blelist(20)
                e = MException('MATLAB:ble:ble:invalidNameValue', getString(message('MATLAB:ble:ble:invalidNameValue')));
            case 'MATLAB:InputParser:UnmatchedParameter' % blelist('random',1)
                e = MException('MATLAB:ble:ble:invalidNVPair', getString(message('MATLAB:ble:ble:invalidNVPair', strjoin(p.Parameters, ', '))));
            case 'MATLAB:InputParser:ParamMissingValue'  % blelist('name')
                param = regexp(e.message, '(?<='').*(?='')','match'); % find param name with missing value
                param = param{1};
                if ~ismember(param, p.Parameters) % b = blelist('random')
                    e = MException('MATLAB:ble:ble:invalidNVPair', getString(message('MATLAB:ble:ble:invalidNVPair', strjoin(p.Parameters, ', '))));
                end
            otherwise
        end
        throwAsCaller(e);
    end

    % Scan peripherals with specified values, if any
    try
        factory = matlabshared.blelib.internal.TransportFactory.getInstance();
        transport = factory.get();
        list = transport.discoverPeripherals(timeout, services);
    catch e
        if string(e.identifier).startsWith("MATLAB:ble:ble:bluetoothOperation")
            throwAsCaller(e);
        end
        switch e.identifier
            case {'MATLAB:ble:ble:unsupportedMacOS',...
                  'MATLAB:ble:ble:invalidMacBluetoothState',...
                  'MATLAB:ble:ble:macBluetoothPoweredOff',...
                  'MATLAB:ble:ble:macBluetoothNotAuthorized'}
                throwAsCaller(e);
            otherwise
                throwAsCaller(MException('MATLAB:ble:ble:failToScan', getString(message('MATLAB:ble:ble:failToScan'))));
        end
    end
    
    % Print bluetoothlist cross-reference text only when no output argument is specified
    if nargout == 0
        disp(getString(message("MATLAB:ble:ble:bluetoothlistReference")));
    end
    
    % Filter non-empty result with starting string in name, if specified
    if ~isempty(list) && ~isempty(name)
        toDelete = ~list.Name.startsWith(string(name), 'IgnoreCase', true);
        list(toDelete, :) = [];
        % Update Index
        for index = 1:height(list)
            list.Index(index) = index;
        end
        % In case list is now 0×N empty table
        if isempty(list)
            list = [];
        end
    end
    
    if isempty(list)
        if isempty(name)
            matlabshared.blelib.internal.localizedWarning('MATLAB:ble:ble:noDeviceFound');
        else
            matlabshared.blelib.internal.localizedWarning('MATLAB:ble:ble:noDeviceWithNameFound');
        end
    end
end

function output = validateName(name)
    % Check if name is a valid single string or char
    if isempty(name) || ... % name is empty, e.g. [], {}, ''
       ~(ischar(name) || isStringScalar(name)) % name is not a char or scalar string
        matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:invalidNameValue');
    end
    output = name;
end

function output = validateTimeout(timeout)
    % Check if timeout is a numeric value within valid range
    if isempty(timeout) ||... % value is empty
       ~(isinteger(timeout) || isfloat(timeout))||... % value is non-integer
       numel(timeout) ~= 1 ||... % value is an array
       timeout <= matlabshared.blelib.internal.Constants.MinScanTimeout ||...
       timeout >= matlabshared.blelib.internal.Constants.MaxScanTimeout
       matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:invalidTimeoutValue',...
                                                    num2str(matlabshared.blelib.internal.Constants.MinScanTimeout),...
                                                    num2str(matlabshared.blelib.internal.Constants.MaxScanTimeout));
    end
    output = timeout;
end

function uuids = validateServices(services)
    % Check if services contains valid service name strings or UUID strings
    % or UUID hex values. Convert all services to UUID strings.
    % special case - [] or {} excluding ''
    if isempty(services)
        matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:invalidServiceUUIDValue');
    end
    info = matlabshared.blelib.internal.ServicesCharacteristicsDescriptorsInfo.getInstance;
    % Convert all kinds of input to cellstr for uniform indexing
    if isnumeric(services) % 0x1800 or [0x1801 0x1800]
        services = num2cell(services);
    end
    if ischar(services) || isstring(services) % '1800' or "1800" or ["1800","180d"]
        services = cellstr(services);
    end
    uuids = strings(1, numel(services));
    for index = 1:numel(services)
        % Check if string is empty
        if isempty(services{index})
            matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:invalidServiceUUIDValue');
        end
        % Check if string is valid name or UUID
        uuids(index) = info.getServiceUUID(services{index});
    end
    % Remove duplicates
    uuids = unique(uuids);
end