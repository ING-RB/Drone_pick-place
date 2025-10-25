classdef NotifyOnly < matlabshared.blelib.read.characteristic.Interface
%NOTIFYONLY - Concrete read interface class for characteristic that only
%has "Notify" or "Indicate" but no "Read" property
    
% Copyright 2019 The MathWorks, Inc.

    properties(Access = public)
        DataAvailableFcn
    end
    
    properties(Access = private)
        % Subscription status before connection
        DefaultSubscriptionStatus = []
        
        % Internal buffer maintaining all data received
        Buffer (1, :) matlabshared.asyncio.buffer.Buffer = matlabshared.asyncio.buffer.Buffer.empty(1, 0)
        
        % Handle to ElementsAvailable 
        DataListener
    end
    
    properties(Access = private, Constant)
        ReadTimeout = 10
    end
    
    methods
        function obj = NotifyOnly
            obj.Buffer = matlabshared.asyncio.buffer.Buffer;
        end
        
        function [value, timestamp] = read(obj, client, varargin)
            narginchk(2, 3);
            % Validate mode
            mode = validateMode(obj, varargin{:});
            
            value = [];
            timestamp = [];
            if ~client.SubscriptionOn
                % Set usercalled to false to respect existing characteristic setting
                subscribe(obj, client, false);
            end
            
            % Wait till there is data in buffer
            t = tic;
            while(obj.Buffer.NumElementsAvailable == 0 && toc(t) < obj.ReadTimeout)
                % Allow processing callbacks
                pause(1e-3);
            end
            if obj.Buffer.NumElementsAvailable == 0
                matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:noDataAvailable');
                return
            end
            
            % Return value based on requested mode
            if mode == "latest"
                % Flush buffer and return the latest
                output = obj.Buffer.read(obj.Buffer.NumElementsAvailable);
                output = output(end);
            elseif mode == "oldest"
                % Return the oldest in the buffer
                output = obj.Buffer.read(1);
            end
            value = double(output.Data);
            timestamp = datetime(output.Timestamp,'InputFormat','MM/dd/uuuu HH:mm:ss.SSSS');
        end
        
        function fcn = getDataAvailableFcn(obj)
            fcn = obj.DataAvailableFcn;
        end
        
        function setDataAvailableFcn(obj, client, fcn)
            % Validate fcn signature
            if isempty(fcn) && (~ischar(fcn) && ~iscell(fcn)) % [] but not '' or {}
                % Set property without actually unsubscribing on device to
                % allow following reads
                obj.DataAvailableFcn = [];
                return
            end
            if ~isa(fcn,'function_handle') || (nargin(fcn) ~= 2)
                matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:invalidDataAvailableFcn');
            end
            
            % Subscribe to notification or indication if not already
            originalFcn = obj.DataAvailableFcn;
            try
                % Set new function handle to property to get ready for new
                % data after subscribed
                obj.DataAvailableFcn = fcn;
                if ~client.SubscriptionOn
                    % Set usercalled to false to respect existing characteristic setting
                    subscribe(obj, client, false);
                end
            catch e
                % Revert back to original function handle if subscribe
                % fails
                obj.DataAvailableFcn = originalFcn;
                throwAsCaller(e);
            end
        end
        
        function subscribe(obj, client, usercalled, varargin)
            % Subscribe to notification or indication
            
            narginchk(3,4);
            
            if any(ismember(["Notify", "NotifyEncryptionRequired"], client.Attributes))
                type = matlabshared.blelib.internal.SubscriptionStatus.Notify;
            else
                type = matlabshared.blelib.internal.SubscriptionStatus.Indicate;
            end

             % If called from read or set.DataAvailableFcn, usercalled is 
             % false then we TRY to set it to a type that is supported by 
             % the characteristic. Notify takes precedance when 
             % characteristic supports both Indicate and Notify. If any 
             % subscription is already enabled, it respects the existing 
             % setting.
             % If called from characteristic.subscribe, e.g. by user, 
             % usercalled is true then we force set it to a type user 
             % specifies after validation.
            if usercalled && nargin > 3
                type = validateSubscriptionType(obj, varargin{:}, client.Attributes);
            end
            
            % Attempt to set the requested status, meaning only set it
            % if neither notification or indication is enabled, by
            % setting last parameter to true
            try
                status = execute(client,matlabshared.blelib.internal.ExecuteCommands.SUBSCRIBE_CHARACTERISTIC, type, usercalled);
            catch e
                if string(e.identifier).startsWith("MATLAB:ble:ble:gattCommunication") || ...
                   ismember(e.identifier, ["MATLAB:ble:ble:failToExecuteDeviceDisconnected", ...
                                           "MATLAB:ble:ble:deviceProfileChanged"])
                    throwAsCaller(e);
                else
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:failToSubscribeCharacteristic');
                end
            end
            % Set DefaultSubscriptionStatus only the first time subscribe
            % is called to allow restoring it back in object deletion
            if isempty(obj.DefaultSubscriptionStatus)
                obj.DefaultSubscriptionStatus = matlabshared.blelib.internal.SubscriptionStatus(status);
            end
            
            % Hook up data events routing after enabling on the device to
            % give little room for receiving first data to avoid first time
            % calling read throws a warning
            if isempty(obj.DataListener)
                obj.DataListener = listener(obj.Buffer, 'ElementsAvailable', @client.handleData);
                % Set EventCount to 1 to trigger callback on every data
                % received
                obj.Buffer.ElementsAvailableEventCount = 1;
            end
            % Add buffer to notification map stored in transport to
            % allow data routing
            execute(client, matlabshared.blelib.internal.ExecuteCommands.REGISTER_CHARACTERISTIC_BUFFER, obj.Buffer);
            client.SubscriptionOn = true;
        end
        
        function unsubscribe(obj, client)
            % Unsubscribe to both notification and indication
            
            % No need to unsubscribe if subscribe is never called
            if isempty(obj.DefaultSubscriptionStatus)
                return
            end
            
            try
                execute(client,matlabshared.blelib.internal.ExecuteCommands.UNSUBSCRIBE_CHARACTERISTIC);
            catch e
                if string(e.identifier).startsWith("MATLAB:ble:ble:gattCommunication") || ...
                   ismember(e.identifier, ["MATLAB:ble:ble:failToExecuteDeviceDisconnected", ...
                                           "MATLAB:ble:ble:deviceProfileChanged"])
                    throwAsCaller(e);
                else
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:failToUnsubscribeCharacteristic');
                end
            end
            client.SubscriptionOn = false;
            % Flush the buffer to throw away existing data not read by user
            obj.Buffer.flush;
            % Keep buffer and its listener to allow user control
            % notification directly via setting client characteristic
            % configuration descriptor with the given DataAvailableFcn
        end
        
        function displayDataAvailableFcn(obj)
            if isempty(obj.DataAvailableFcn)
                fprintf(' DataAvailableFcn: []\n');
            else
                fprintf(' DataAvailableFcn: %s\n', func2str(obj.DataAvailableFcn));
            end
        end
        
        function resetSubscription(obj, client)
            % Reset characteristic to its original subscription state
            % Because client characteristic configuration value is
            % preserved among bonded devices.
            
            % Nothing to reset if subscribe function is never called on
            % this object.
            if isempty(obj.DefaultSubscriptionStatus)
                return;
            end
            
            try
                % Remove buffer from transport to stop receiving any data
                delete(obj.DataListener);
                execute(client,matlabshared.blelib.internal.ExecuteCommands.UNREGISTER_CHARACTERISTIC_BUFFER);
                % Revert back to originial subscription status, if known
                switch obj.DefaultSubscriptionStatus
                    case matlabshared.blelib.internal.SubscriptionStatus.None
                        execute(client,matlabshared.blelib.internal.ExecuteCommands.UNSUBSCRIBE_CHARACTERISTIC);
                    case {matlabshared.blelib.internal.SubscriptionStatus.Notify,...
                          matlabshared.blelib.internal.SubscriptionStatus.Indicate}
                        % Force set the requested status by setting last
                        % parameter to true
                        execute(client,matlabshared.blelib.internal.ExecuteCommands.SUBSCRIBE_CHARACTERISTIC, obj.DefaultSubscriptionStatus, true);
                    otherwise
                        % No operation
                end
            catch 
                % Suppress all errors
            end
        end
    end
    
    methods(Access = private)
        function mode = validateMode(~, varargin)
            % For characteristic that supports Notify or Indicate, valid 
            % modes are "latest" and "oldest". Default to "latest" if not
            % specified.
            mode = "latest";
            if nargin > 1
                supportedModes = matlabshared.blelib.internal.Constants.SupportedReadModesNotifyOnly;
                try
                    mode = validatestring(varargin{1}, supportedModes);
                catch
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:invalidModeNotifyOnly', strjoin(supportedModes, ', '));
                end
            end
        end
        
        function type = validateSubscriptionType(~, input, attributes)
            % Validate subscribe type is valid and supported by the
            % characteristic
            
            supportedTypes = [];
            if any(ismember(["Notify", "NotifyEncryptionRequired"], attributes))
                supportedTypes = [supportedTypes, "notification"];
            end
            if any(ismember(["Indicate", "IndicateEncryptionRequired"], attributes))
                % On Mac, if both Notify and Indicate exists, only Notify
                % can be enabled, therefore excluding the scenario
                if ~(ismac && ~isempty(supportedTypes))
                    supportedTypes = [supportedTypes, "indication"];
                end
            end
            
            % Validate and correct input
            try
                input = validatestring(input, supportedTypes);
                if input == "notification"
                    type = matlabshared.blelib.internal.SubscriptionStatus.Notify;
                else
                    type = matlabshared.blelib.internal.SubscriptionStatus.Indicate;
                end
            catch
                matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:invalidSubscriptionType', strjoin(supportedTypes,', '));
            end
        end
    end
end