classdef ble < matlabshared.blelib.internal.Node & matlab.mixin.CustomDisplay
%BLE Create a connection to a Bluetooth Low Energy peripheral device.
%
%   b = BLE(name) creates a connection to a Bluetooth Low Energy peripheral 
%   device that has the specified name.
%
%   b = BLE(address) creates a connection to a Bluetooth Low Energy 
%   peripheral device that has the specified address. 
%
%   Identify the device name or address using blelist.
%
%   BLE methods:
%   
%   characteristic - Creates an object that represents a characteristic on
%   the Bluetooth Low Energy peripheral.
%
%   BLE properties:
%   
%   Name            - Specifies the peripheral name
%   Address         - Specifies the peripheral address
%   Connected       - Specifies the connection status of the peripheral
%   Services        - Specifies the services on the peripheral
%   Characteristics - Specifies the characteristics on the peripheral
%   
%   Examples: 
%       % Connect to a Bluetooth Low Energy peripheral device with name flex
%       b = ble("flex")
%   
%       % Connect to a Bluetooth Low Energy peripheral device with address 
%       % 0570B282CF53 on Windows
%       b = ble("0570B282CF53")
%
%       % Connect to a Bluetooth Low Energy peripheral with address 
%       % 5E4F4F17-7A25-4AB3-AA67-B68355FB5D78 on Mac
%   	b = ble("5E4F4F17-7A25-4AB3-AA67-B68355FB5D78")
%
%   See also blelist, characteristic
%
%   To model the Bluetooth(R) protocol, use <a href="matlab:if ~isempty(ver('bluetooth')), doc bluetooth, else, web('https://www.mathworks.com/products/bluetooth.html'), end">Bluetooth(R) Toolbox</a>

% Copyright 2019-2021 The MathWorks, Inc.

    properties(GetAccess = public, SetAccess = private)
        %Name - Peripheral name
        Name
        %Address - Peripheral address
        Address
        %Connected - Peripheral connection status
        Connected
        %Services - Services on the peripheral
        Services
        %Characteristics - Characteristics on the peripheral
        Characteristics
    end
    
    properties(Access = private)
        Transport
        % Flag indicating whether connect has been called successfully to
        % determine whether disconnect shall be called at deletion
        ConnectCalled = false
    end
    
    properties(Access = private, Constant)
        % Map shared across all ble objects to avoid duplicate objects for
        % the same device
        PeripheralsMap = containers.Map
        % Maximum number of retry for connecting to a device when 
        % gattCommunicationUnreachable error is thrown on Windows due to
        % Windows API bug
        NumRetryWhenUnreachable = 3
    end
    
    methods
        function obj = ble(input)
            try
                matlabshared.blelib.internal.validatePlatform;
            catch e
                throwAsCaller(e);
            end
            
            if nargin < 1
                matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:bleCalledWithoutInput');
            end
            
            try
                [found, deviceInfo] = obj.validateAddress(input);
                obj.Transport = matlabshared.blelib.internal.TransportFactory.getInstance.get();
                % There is an interval after each advertisement in which the device listens for connection requests.
                % it is possible to connect directly without scanning for the advertisements. but the device must be
                % advertising in order to be able to connect to it. To ensure the device is connectable, we enforce
                % device need to be discovered by MATLAB once.
                % Scan for devices once and check again
                if ~found
                    obj.Transport.discoverPeripherals(matlabshared.blelib.internal.Constants.DefaultScanTimeout, []);
                    [found, deviceInfo] = obj.validateAddress(input);
                    if ~found
                        matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:undiscoveredDevice');
                    end
                end
            catch e
                throwAsCaller(e);
            end
            % Check if object already exists for the same device
            if isKey(obj.PeripheralsMap, deviceInfo.Address)
                matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:connectionExists');
            end
            obj.Address = deviceInfo.Address;
            obj.Name = deviceInfo.Name;
            obj.PeripheralsMap(obj.Address) = obj.Name;
            
            attempt = 1;
            while attempt <= obj.NumRetryWhenUnreachable
                % Reset all related states
                if obj.ConnectCalled
                    try
                        execute(obj, matlabshared.blelib.internal.ExecuteCommands.DISCONNECT_PERIPHERAL);
                    catch
                        % Swallow all errors
                    end
                end
                obj.ConnectCalled = false;
                obj.Services = [];
                obj.Characteristics = [];
                
                % Connect to device
                try
                    obj.ConnectCalled = true;
                    execute(obj,matlabshared.blelib.internal.ExecuteCommands.CONNECT_PERIPHERAL);
                catch
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:failToConnect');
                end
                % Discover services
                obj.Services = table(strings(0,1), strings(0,1));
                obj.Services.Properties.VariableNames = ["ServiceName","ServiceUUID"];
                obj.Characteristics = table(strings(0,1), strings(0,1), strings(0,1), strings(0,1), cell(0,1));
                obj.Characteristics.Properties.VariableNames = ["ServiceName", "ServiceUUID", "CharacteristicName", "CharacteristicUUID", "Attributes"];
                try
                    suuids = execute(obj, matlabshared.blelib.internal.ExecuteCommands.DISCOVER_SERVICES);
                catch e
                    % Only when gattCommunicationUnreachable is received
                    % will it enter the retry loop. All other failure
                    % scenarios will error immediately. This is only a
                    % Windows error hence no retry is used on Mac. See 
                    % g1998119.
                    if strcmpi(e.identifier, 'MATLAB:ble:ble:gattCommunicationUnreachable') && (attempt < obj.NumRetryWhenUnreachable)
                        attempt = attempt + 1;
                        continue
                    end
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:failToConnect');
                end
                % Discover characteristics
                hasEncounteredUnreachableError = false;
                for sindex = 1:numel(suuids)
                    sinfo = matlabshared.blelib.internal.ServicesCharacteristicsDescriptorsInfo.getInstance.getServiceInfoByUUID(suuids(sindex));
                    obj.Services = [obj.Services; {sinfo.Name, sinfo.UUID}];
                    try
                        characteristics = execute(obj, matlabshared.blelib.internal.ExecuteCommands.DISCOVER_CHARACTERISTICS, sindex);
                    catch e
                        % Only when gattCommunicationUnreachable is received
                        % will it enter the retry loop. Most other failure
                        % scenarios will error immediately. This is only a
                        % Windows error hence no retry is used on Mac. See
                        % g1998119.
                        if strcmpi(e.identifier, 'MATLAB:ble:ble:gattCommunicationUnreachable') && (attempt < obj.NumRetryWhenUnreachable)
                            hasEncounteredUnreachableError = true;
                            attempt = attempt + 1;
                            break
                        end
                        % If service denies access of its characteristics,
                        % throw a warning but continue with rest services
                        % to allow connection
                        if strcmpi(e.identifier, 'MATLAB:ble:ble:gattCommunicationAccessDenied')
                            matlabshared.blelib.internal.localizedWarning('MATLAB:ble:ble:serviceAccessDenied', sinfo.Name, sinfo.UUID);
                            characteristics = [];
                        else
                            matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:failToConnect');
                        end
                    end
                    for characteristic = characteristics
                        sinfo = matlabshared.blelib.internal.ServicesCharacteristicsDescriptorsInfo.getInstance.getServiceInfoByUUID(suuids(sindex));
                        cinfo = matlabshared.blelib.internal.ServicesCharacteristicsDescriptorsInfo.getInstance.getCharacteristicInfoByUUID(sinfo.UUID, characteristic.UUID);
                        attributes = characteristic.Attributes;
                        obj.Characteristics = [obj.Characteristics; {sinfo.Name, sinfo.UUID, cinfo.Name, cinfo.UUID, {attributes}}];
                    end
                end
                % If discover characteristics for-loop exit because of
                % unreachable error, go back to outer for-loop to retry
                if hasEncounteredUnreachableError
                    continue
                end
                
                % Reset Services and Characteristics table to empty instead of
                % the prepared empty table if there is truly no services
                if isempty(suuids)
                    obj.Services = [];
                    obj.Characteristics = [];
                end
                
                % If all passes, break out of retry loop
                break;
            end
        end
        
        function c = characteristic(obj, sid, cid)
            %CHARACTERISTIC Create an object representing the specified characteristic
            % on the Bluetooth Low Energy peripheral device.
            %
            %   c = CHARACTERISTIC(b,servicename,charname) creates an object representing 
            %   the characteristic of the specified name under the service of the 
            %   specified name on the Bluetooth Low Energy peripheral device.
            %
            %   c = CHARACTERISTIC(b,serviceuuid,charuuid) creates an object representing 
            %   the characteristic of the specified UUID under the service of the 
            %   specified UUID on the Bluetooth Low Energy peripheral device.
            %
            %   CHARACTERISTIC methods:
            %   
            %   <a href="matlab:help matlabshared.blelib.Characteristic.read">read</a>        - Reads the characteristic value from the peripheral.
            %   <a href="matlab:help matlabshared.blelib.Characteristic.write">write</a>       - Writes the characteristic value to the peripheral.
            %   <a href="matlab:help matlabshared.blelib.Characteristic.subscribe">subscribe</a>   - Subscribes to notification or indication of the characteristic from the peripheral.
            %   <a href="matlab:help matlabshared.blelib.Characteristic.unsubscribe">unsubscribe</a> - Unsubscribes to both notification and indication of the characteristic from the peripheral.
            %   <a href="matlab:help matlabshared.blelib.Characteristic.descriptor">descriptor</a>  - Creates an object that represents a descriptor of the characteristic on the peripheral.
            %
            %   CHARACTERISTIC properties:
            %   
            %   Name             - Specifies the characteristic name
            %   UUID             - Specifies the characteristic UUID
            %   Attributes       - Specifies the characteristic properties
            %   Descriptors      - Specifies the descriptors of the characteristic 
            %   DataAvailableFcn - Specifies the function handle to be called when
            %                      notification or indication is enabled. Only 
            %                      accessible when the characteristic supports either 
            %                      Notify or Indicate.
            %   
            %   Examples: 
            %       % Create a characteristic object with service name and
            %       characteristic name
            %       b = ble("flex")
            %       c = characteristic(b,"heart rate","body sensor location")
            %
            %       % Create a characteristic object with service UUID(string) and
            %       characteristic UUID(string)
            %       b = ble("flex")
            %       c = characteristic(b,"180d","2a37")
            %
            %       % Create a characteristic object with service UUID(hex) and
            %       characteristic UUID(hex)
            %       b = ble("flex")
            %       c = characteristic(b,0x180d,0x2a37)
            %
            %   See also <a href="matlab:help matlabshared.blelib.Characteristic.read">read</a>, <a href="matlab:help matlabshared.blelib.Characteristic.write">write</a>, <a href="matlab:help matlabshared.blelib.Characteristic.subscribe">subscribe</a>, <a href="matlab:help matlabshared.blelib.Characteristic.unsubscribe">unsubscribe</a>, <a href="matlab:help matlabshared.blelib.Characteristic.descriptor">descriptor</a>

            % validate service and characteristic inputs
            try
                narginchk(3, 3);
                sinfo = validateService(obj, sid);
                cinfo = validateCharacteristic(obj, sinfo, cid);
            catch e
                throwAsCaller(e);
            end
            
            % Check if characteristic already exists
            children = obj.getChildren;
            for child = children'
                if isa(child,'matlabshared.blelib.Characteristic') && ...
                   ((child.ServiceIndex == sinfo.Index) && (child.CharacteristicIndex == cinfo.Index))
                   c = child;
                   return;
                end
            end
            
            % Create characteristic            
            try
                [rinterface, winterface] = matlabshared.blelib.internal.getCharacteristicInterfaceFactory(cinfo.Attributes);
                c = matlabshared.blelib.Characteristic(obj, sinfo, cinfo, rinterface, winterface);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    methods(Access=protected)
        function delete(obj)
            try
                % Only remove it from map when constructor adds it to map
                 if ~isempty(obj.Address)
                    if isKey(obj.PeripheralsMap, obj.Address)
                        remove(obj.PeripheralsMap, obj.Address);
                    end
                end
                % Only disconnect when constructor passes connection
                if obj.ConnectCalled
                    execute(obj, matlabshared.blelib.internal.ExecuteCommands.DISCONNECT_PERIPHERAL);
                end
            catch
                % Suppress all errors in destructor
            end
        end
    end
    
    methods
        function status = get.Connected(obj)
            try
                status = execute(obj,matlabshared.blelib.internal.ExecuteCommands.GET_PERIPHERAL_STATE);
                if ~status
                    matlabshared.blelib.internal.localizedWarning('MATLAB:ble:ble:deviceDisconnected');
                end
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    methods(Access = private)
        function [found, deviceInfo] = validateAddress(~,input)
            % Check input is a valid device address or name that has been
            % discovered by blelist before(by checking saved preference).
            % if so, return both full name and address for the device
             
            % Validate input type and non-empty
            if isempty(input) || (isstring(input) && input == "") || (~isstring(input) && ~ischar(input))
                matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:invalidIdentifier');
            end
            input = string(input);
            
            % Convert xx:xx:xx:xx:xx:xx or xx-xx-xx-xx-xx-xx to xxxxxxxxxxxx
            if regexp(input, "([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}", "match") == input
                input = strrep(input, ":", "");
                input = strrep(input, "-", "");
            end
            
            found = false;
            deviceInfo = [];
            foundDevices = matlabshared.blelib.internal.Utility.getInstance.getDevices;
            if isempty(foundDevices)
                return
            end
            
            % Check to see if input is address
            try
                input = validatestring(input, foundDevices.keys);
                found = true;
                deviceInfo.Address = string(input); % containers.Map stores and returns char instead of string
                deviceInfo.Name    = string(foundDevices(input).Name);
            catch e
                % Swallow only unrecognizedStringChoice error to proceed to
                % next try-catch
                if ~strcmpi(e.identifier, 'MATLAB:unrecognizedStringChoice')
                    throwAsCaller(e);
                end
            end
            
            % Address does not match, then check to see if input is name
            if ~found
                try
                    % Remove duplicate names
                    infos = cell2mat(foundDevices.values);
                    foundNames = string({infos(:).Name});
                    names = unique(foundNames);
                    % Remove empty names
                    names = names(~cellfun('isempty', names));
                    input = validatestring(input, names);
                    matches = strcmpi(foundNames, input);
                    ids = foundDevices.keys;
                    % More than one device found with same name
                    % For example, two devices with different address but same name and input is the name
                    if sum(matches) > 1
                        matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:ambiguousDeviceName', input, strjoin(ids(matches), ','));
                    end
                    found = true;
                    deviceInfo.Address = string(ids(matches));
                    deviceInfo.Name    = string(input);
                catch e
                    % Swallow only unrecognizedStringChoice error to simply
                    % return found false. Otherwise, throw error
                    if ~strcmpi(e.identifier, 'MATLAB:unrecognizedStringChoice')
                        throwAsCaller(e);
                    end
                end
            end
            
            if found && ~foundDevices(deviceInfo.Address).Connectable
                matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:unconnectableDevice');
            end
        end
       
        function sinfo = validateService(obj, input)
            % Check if input is a valid service name or UUID supported on
            % the peripheral and return index of the service in Services
            % table
            
            % Validate data type
            info = matlabshared.blelib.internal.ServicesCharacteristicsDescriptorsInfo.getInstance;
            uuid = info.getServiceUUID(input);
            uuid = info.getShortestUUID(uuid);
            
            try
                uuid = validatestring(uuid, obj.Services.ServiceUUID);
            catch e
                if strcmpi(e.identifier, 'MATLAB:ambiguousStringChoice')
                    throwAsCaller(e);
                else
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:unsupportedService');
                end
            end
            
            sinfo = info.getServiceInfoByUUID(uuid);
            sinfo.Index = find(obj.Services.ServiceUUID == uuid);
        end
       
        function cinfo = validateCharacteristic(obj, sinfo, input)
            % Check if input is a valid characteristic name or UUID supported 
            % on the peripheral and return index of the characteristic for
            % the specified service
            
            % Validate data type
            info = matlabshared.blelib.internal.ServicesCharacteristicsDescriptorsInfo.getInstance;
            uuid = info.getCharacteristicUUID(sinfo.UUID, input);
            uuid = info.getShortestUUID(uuid);
            
            % Find portion of the table that has the same ServiceUUID
            subtable = obj.Characteristics(obj.Characteristics.ServiceUUID == obj.Services.ServiceUUID(sinfo.Index), :);
            try
                uuid = validatestring(uuid, subtable.CharacteristicUUID);
            catch e
                if strcmpi(e.identifier,'MATLAB:ambiguousStringChoice')
                    throwAsCaller(e);
                else
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:unsupportedCharacteristic');
                end
            end
            
            cinfo = info.getCharacteristicInfoByUUID(sinfo.UUID, uuid);
            cinfo.Index = find(subtable.CharacteristicUUID == uuid);
            cinfo.Attributes = subtable.Attributes{cinfo.Index};
       end
    end
    
    methods(Access = {?matlabshared.blelib.Characteristic})
        function output = execute(obj, cmd, varargin)
            output = obj.Transport.execute(cmd, obj.Address, varargin{:});
        end
    end
    
    methods (Access = protected)
        function out = getFooter(~)
            thisObj = inputname(1);
            % only display properties if object still exists and is valid
            out = sprintf('Show <a href="matlab:if exist(''%s'',''var'')&&isa(%s,''ble''),nobodyknows = eval(''%s'');disp(''>>'');disp(nobodyknows.Services);clear nobodyknows; else, disp(''Variable ''''%s'''' does not exist or is no longer valid ble type.''), end">services</a>', thisObj, thisObj, thisObj, thisObj);
            out = [out ' and '];
            out = [out sprintf('<a href="matlab:if exist(''%s'',''var'')&&isa(%s,''ble''),nobodyknows = eval(''%s'');disp(''>>'');disp(nobodyknows.Characteristics);clear nobodyknows; else, disp(''Variable ''''%s'''' does not exist or is no longer valid ble type.''), end">characteristics</a>', thisObj, thisObj, thisObj, thisObj)];
            out = [out newline];
        end
    end
end