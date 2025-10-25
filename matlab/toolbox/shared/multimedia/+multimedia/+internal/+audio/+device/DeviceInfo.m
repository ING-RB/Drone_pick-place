classdef DeviceInfo < handle
    %DEVICEINFO Information about an Audio device in your system
    %   DeviceInfo defines the properties of an audio device on your system
    %
    
    % Copyright 2010-2024 The MathWorks, Inc.
    
    properties (GetAccess='public', SetAccess='private')
        Name
        ID
        HostApiName
        HostApiID
        NumberOfInputs
        NumberOfOutputs
    end
    
    methods (Access='public', Static)
        function devices = getDevices()
            import multimedia.internal.audio.device.DeviceInfo;
            numDevices = mexAudioDeviceInfo('numDevices');
            
            devices = DeviceInfo.empty(1,0);
            for ii=(1:numDevices)
              devices(ii) = DeviceInfo.getDeviceInfo( ii - 1 ); % ids are zero based 
            end
        end
        
        function devices = getDevicesForDefaultHostApi
            import multimedia.internal.audio.device.DeviceInfo;
            import multimedia.internal.audio.device.HostApi;
            devices = DeviceInfo.getDevices();
            
            % Only list devices that match the Default HostApi
            devices = devices([devices.HostApiID] == HostApi.Default);
        end
        
        function deviceInfo = getDeviceInfo( ID )
            import multimedia.internal.audio.device.DeviceInfo;
            
            numDevices = mexAudioDeviceInfo('numDevices');
            if (ID < 0 || ID >= numDevices)
                deviceInfo = [];
                return;
            end
            
            devInfoStruct = mexAudioDeviceInfo('deviceInfo', ID);
            
            deviceInfo = DeviceInfo(devInfoStruct);
        end
        
        function deviceID = getDefaultInputDeviceID( hostApi )
            deviceID = mexAudioDeviceInfo('defaultInputDeviceID', ...
                double(hostApi));
        end
        
        function deviceID = getDefaultOutputDeviceID( hostApi )
            deviceID = mexAudioDeviceInfo('defaultOutputDeviceID', ...
                double(hostApi));
        end
        
        % Calling reset will repopulate the list of devices if a device has
        % been added or removed.  A device name change will not be captured
        % unless the device was removed and added.
        function reset
            mexAudioDeviceInfo('resetDeviceList');
            clear('getAudioTbxDevInfo'); % audio.internal.getAudioTbxDevInfo
        end
    end
    
    methods (Access='private')
        function obj = DeviceInfo(devInfoStruct)
            obj.Name = devInfoStruct.Name;
            obj.ID = devInfoStruct.ID;
            obj.HostApiName = devInfoStruct.HostApiName;
            obj.HostApiID = devInfoStruct.HostApi;
            obj.NumberOfInputs = devInfoStruct.MaxInputs;
            obj.NumberOfOutputs = devInfoStruct.MaxOutputs;
        end
        
   
    end   
end


