classdef EventSource < handle
%EventSource    A publisher of hot-plug events. 
% 
%   When a hot-plug device is plugged in, an instance of this class will 
%   publish a DeviceAdded event. When a hot-plug device is removed, an
%   instance of this object will publish a DeviceRemoved event. The data 
%   associated with these events will be an instance of
%   internal.hotplug.EventData.
%
%   Note: Currently only USB hot-plug events are supported.
%
%   Example:
%     es = internal.hotplug.EventSource();
%     lh(1) = addlistener(es, 'DeviceAdded', @(source,info) disp(info));
%     lh(2) = addlistener(es, 'DeviceRemoved', @(source,info) disp(info));
%
%   See also internal.hotplug.EventData     

% Copyright 2010-2022 The MathWorks, Inc.
% $Revision: 1.1.6.2 $  $Date: 2010/07/06 17:13:05 $

    events(NotifyAccess = private)
        % DeviceAdded - A device has been added. 
        % See also internal.hotplug.EventData.
        DeviceAdded
        
        % DeviceRemoved - A device has been removed. 
        % See also internal.hotplug.EventData.
        DeviceRemoved
    end
    
    methods (Access = public)
        %% Lifetime
        function obj = EventSource()
            % Lock EventSource class definition when there are any
            % instances of the EventSource. See g2299621 for more info.
            internal.hotplug.EventSource.lock();
            
            pluginDir = toolboxdir(fullfile('shared','hotpluglib','bin',...
                                            computer('arch')));
            prefix = '';

            % hotplug library prefix is 'libmw' for UNIX and Mac OS X versions of MATLAB.
            % there is no prefix under windows versions of MATLAB
            if ~ispc()
                prefix = 'libmw';
            end
            
            devPlugin = [prefix 'hotplugdevice'];
            convPlugin = [prefix 'hotplugmlconverter'];
            
            % Initialize channel that will handle events.
            options = [];
            obj.Channel = matlabshared.asyncio.internal.Channel(fullfile(pluginDir, devPlugin),...
                                          fullfile(pluginDir, convPlugin),...
                                          Options = options,... 
                                          StreamLimits = [0,0]);
                                      
            obj.start();
        end
    end
    
    methods (Access = private)
        
        %% Lifetime
        function delete(obj)
            stop(obj);
            delete(obj.Channel);
            internal.hotplug.EventSource.unlock();
        end
        
        %% Operations
        function start(obj)
            % Begin notification of events.
            
            obj.CustomEventListener = event.listener(obj.Channel,...
                        'Custom', @obj.onCustomEvent );
            obj.Channel.open();
        end
        
        function stop(obj)
            % End notification of events.
            
            obj.Channel.close();
            delete(obj.CustomEventListener);
        end
        
        %% Event Handlers
        function onCustomEvent(obj, ~, info)
            type = info.Type;
            data = info.Data;
            notify(obj, type, internal.hotplug.EventData(...
                   data.DeviceType, data.VendorID,...
                   data.ProductID, data.ExtraInfo));
        end
    end
    
    methods(Static, Access='private')
        function lock()
            % Lock this class definitionn on the first lock
            if internal.hotplug.EventSource.updateAndFetchLockCount(1) > 0
                if ~mislocked
                    mlock;
                end
            end
        end
        
        function unlock()
            % Unlock this class definition on the last unlock
            if internal.hotplug.EventSource.updateAndFetchLockCount(-1) < 1
                if mislocked
                    munlock;
                end
            end
        end
        
        function count = updateAndFetchLockCount(increment)
            persistent lockCount;
            if isempty(lockCount)
                lockCount = 0;
            end
            lockCount = lockCount + increment;
            count = lockCount;
        end
    end
    
    properties(Access = private)
        % The underlying matlabshared.asyncio.internal.Channel that generates the events.
        Channel
        % A listener to the matlabshared.asyncio.internal.Channel events.
        CustomEventListener;
    end
end



