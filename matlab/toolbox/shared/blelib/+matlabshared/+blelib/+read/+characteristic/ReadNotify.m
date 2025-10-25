classdef ReadNotify < matlabshared.blelib.read.characteristic.ReadOnly & matlabshared.blelib.read.characteristic.NotifyOnly
%READNOTIFY - Concrete read interface class for characteristic that
%has both "Read" and ("Notify" or "Indicate") property
    
% Copyright 2019 The MathWorks, Inc.

    methods
        function [value, timestamp] = read(obj, client, varargin)
            narginchk(2, 3);
            % Perform on-demand read when notification is not turned on.
            % Otherwise, read notification data from device
            mode = validateMode(obj, client.SubscriptionOn, varargin{:});
            if ~client.SubscriptionOn
                [value, timestamp] = read@matlabshared.blelib.read.characteristic.ReadOnly(obj, client, mode);
            else
                [value, timestamp] = read@matlabshared.blelib.read.characteristic.NotifyOnly(obj, client, mode);
            end
        end
        
        % Use NotifyOnly version for all notification related methods
        function fcn = getDataAvailableFcn(obj)
            fcn = getDataAvailableFcn@matlabshared.blelib.read.characteristic.NotifyOnly(obj);
        end
        
        function setDataAvailableFcn(obj, client, fcn)
            setDataAvailableFcn@matlabshared.blelib.read.characteristic.NotifyOnly(obj, client, fcn);
        end
        
        function subscribe(obj, client, usercalled, varargin)
            subscribe@matlabshared.blelib.read.characteristic.NotifyOnly(obj, client, usercalled, varargin{:});
        end
        
        function unsubscribe(obj, client)
            unsubscribe@matlabshared.blelib.read.characteristic.NotifyOnly(obj, client);
        end
        
        function displayDataAvailableFcn(obj)
            displayDataAvailableFcn@matlabshared.blelib.read.characteristic.NotifyOnly(obj);
        end
        
        function resetSubscription(obj, client)
            resetSubscription@matlabshared.blelib.read.characteristic.NotifyOnly(obj, client);
        end
    end
    
    methods(Access = private)
        function mode = validateMode(~, subscriptionOn, varargin)
            mode = "latest";
            if nargin > 2
                supportedModes = matlabshared.blelib.internal.Constants.SupportedReadModesNotifyOnly;
                try
                    mode = validatestring(varargin{1}, supportedModes);
                catch
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:invalidModeNotifyOnly', strjoin(supportedModes, ', '));
                end
                % Check if oldest is valid given current subscription
                % status
                if mode == "oldest" && ~subscriptionOn
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:invalidModeReadNotify');
                end
            end
        end
    end
end