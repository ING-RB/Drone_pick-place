function devInfo = audiodevinfoDesktop(varargin)
%AUDIODEVINFODESKTOP Helper function for Audio device information on ML Desktop.

%   Copyright 2020-2022 The MathWorks, Inc.

% Local Constants
INPUT = 1;
OUTPUT = 0;

switch nargin
    case 0
        devInfo = localGetAllDevices();
    case 1
        devInfo = localGetDeviceCount(varargin{:});
    case 2
        if ischar(varargin{2})
            devInfo = localGetDeviceID(varargin{:});
        else
            devInfo = localGetDeviceName(varargin{:});
        end
    case 3
        devInfo = localGetDriverVersion(varargin{1}, varargin{2});
    case 4
        devInfo = localFindDeviceWith(varargin{:});
    case 5
        devInfo = localDoesDeviceSupport(varargin{:});
end


    function devices = localGetAllDevices()
        import multimedia.internal.audio.device.DeviceInfo;

        % Return a structure of all input and output devices on the current system
        deviceList = DeviceInfo.getDevicesForDefaultHostApi();

        inputDevices = [];
        outputDevices = [];
        for ii=1:length(deviceList) % devices IDs are zero based
            inputDevices = localAddDeviceInfo(deviceList(ii), INPUT, inputDevices);
            outputDevices = localAddDeviceInfo(deviceList(ii), OUTPUT, outputDevices);
        end

        devices.input = inputDevices;
        devices.output = outputDevices;
    end

    function devices = localAddDeviceInfo( deviceInfo, IO, devices )
        localValidateDeviceType(IO);

        if ~localHasType(deviceInfo, IO);
            return;
        end

        devices(end+1).Name = deviceInfo.Name;
        devices(end).DriverVersion = deviceInfo.HostApiName;
        devices(end).ID = deviceInfo.ID;
    end

    function numDevices = localGetDeviceCount(IO)
        devices = localGetAllDevices();

        localValidateDeviceType(IO);
        switch(IO)
            case INPUT
                numDevices = length(devices.input);
            case OUTPUT
                numDevices = length(devices.output);
        end
    end

    function deviceName = localGetDeviceName(IO, ID)
        import multimedia.internal.audio.device.DeviceInfo;

        localValidateDeviceType(IO);

        deviceInfo = DeviceInfo.getDeviceInfo(ID);
        if ~localHasType(deviceInfo, IO)
            error(message('MATLAB:audiovideo:audiodevinfo:invalidID'));
        end

        deviceName = deviceInfo.Name;
    end

    function deviceID = localGetDeviceID(IO, name)
        localValidateDeviceType(IO);

        devices = localGetDevicesByType(IO);
        if isempty(devices)
            error (message('MATLAB:audiovideo:audiodevinfo:invalidDeviceName'));
        end

        idx = strfind({devices.Name}, name);
        deviceIndex = find( cellfun( @(x) ~isempty(x), idx, 'UniformOutput', true) );

        if isempty(deviceIndex)
            error (message('MATLAB:audiovideo:audiodevinfo:invalidDeviceName'));
        end

        if ~isscalar(find(deviceIndex))
            error(message('MATLAB:audiovideo:audiodevinfo:multipleDevicesWithSameName', name));
        end

        deviceID = devices(deviceIndex).ID;
    end

    function driverVersion = localGetDriverVersion(IO, ID)
        import multimedia.internal.audio.device.DeviceInfo;

        localValidateDeviceType(IO);

        deviceInfo = DeviceInfo.getDeviceInfo(ID);

        if ~localHasType(deviceInfo, IO)
            error(message('MATLAB:audiovideo:audiodevinfo:invalidID'));
        end

        driverVersion = deviceInfo.HostApiName;

    end

    function deviceID = localFindDeviceWith(IO, rate, bits, chans)
        localValidateDeviceType(IO);

        devices = localGetDevicesByType(IO);

        for ii = 1:length(devices)
            if (localDoesDeviceSupport(IO, devices(ii).ID, rate, bits, chans))
                deviceID = devices(ii).ID;
                return;
            end
        end

        % No Device found
        deviceID = -1;
    end


    function supported = localDoesDeviceSupport(IO, ID, rate, bits, chans)
        supported = true;
        try
            % Validate device type input
            localValidateDeviceType(IO);
            switch(IO)
                case INPUT
                    a = audiorecorder(rate, bits, chans, ID);
                    record(a);
                    stop(a);
                case OUTPUT
                    y = zeros(int32(rate),chans);
                    a = audioplayer(y, rate, bits, ID );
                    play(a);
                    stop(a);
                otherwise
                    supported = false;
            end
        catch exception %#ok<NASGU>
            supported = false;
        end
    end

    function devices = localGetDevicesByType(IO)
        devices = localGetAllDevices();
        switch(IO)
            case INPUT
                devices = devices.input;
            case OUTPUT
                devices = devices.output;
        end
    end

    function hasType = localHasType(deviceInfo, IO)
        if isempty(deviceInfo)
            hasType = false;
            return;
        end

        if IO == INPUT
            hasType = deviceInfo.NumberOfInputs > 0;
        elseif IO == OUTPUT
            hasType = deviceInfo.NumberOfOutputs > 0;
        end
    end

    function localValidateDeviceType(IO)
        if ~isempty(IO) && isnumeric(IO) && (IO == INPUT || IO == OUTPUT)
            return; % Valid value
        end

        error(message('MATLAB:audiovideo:audiodevinfo:invalidDeviceType'));
    end
end
