classdef Write < matlabshared.blelib.write.descriptor.Interface
%WRITE - Concrete write interface class for descriptors that 
%have "Write" property
    
% Copyright 2019 The MathWorks, Inc.
    
    methods
        function write(obj, client, varargin)
            narginchk(3, 4);
                            
            % Validate optional inputs
            precision = validateOptionalInputs(obj, varargin{2:end});
            
            % Validate data
            data = varargin{1};
            data = matlabshared.blelib.internal.validateDataRange(data, precision);
                
            try
                execute(client,matlabshared.blelib.internal.ExecuteCommands.WRITE_DESCRIPTOR, data);
                % Characteristic that supports either Notify or Indicate of
                % any kind will have a client characteristic configuration
                % descriptor. Writing to the descriptor changes the
                % subscription status
                if client.UUID == matlabshared.blelib.internal.Constants.ClientCharacteristicConfigurationUUID
                    updateSubscription(obj, client);
                end
            catch e
                if string(e.identifier).startsWith("MATLAB:ble:ble:gattCommunication") || ...
                   ismember(e.identifier, ["MATLAB:ble:ble:failToExecuteDeviceDisconnected", ...
                                           "MATLAB:ble:ble:deviceProfileChanged"])
                    throwAsCaller(e);
                else
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:failToWriteDescriptor');
                end
            end
        end
    end
    
    methods(Access = private)
        function precision = validateOptionalInputs(~,varargin)
            % Validate optional input parameters of write method to allow
            % optional precision
            
            p = inputParser;
            validateFcn = @(x) isstring(validatestring(x, matlabshared.blelib.internal.Constants.WritePrecisions));
            addOptional(p, "Precision", "uint8", validateFcn);
            p.parse(varargin{:});
            
            precision = validatestring(p.Results.Precision, matlabshared.blelib.internal.Constants.WritePrecisions);
        end
        
        function updateSubscription(~, client)
            % Update the characteristic subscription status
            output = execute(client, matlabshared.blelib.internal.ExecuteCommands.GET_CHARACTERISTIC_STATUS);
            status = matlabshared.blelib.internal.SubscriptionStatus(output);
            characteristic = client.getParent;
            characteristic.SubscriptionOn = ismember(status, [matlabshared.blelib.internal.SubscriptionStatus.Notify,...
                                                              matlabshared.blelib.internal.SubscriptionStatus.Indicate]);
        end
    end
end