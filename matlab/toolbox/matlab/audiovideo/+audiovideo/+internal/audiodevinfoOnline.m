function devInfo = audiodevinfoOnline(varargin)
%AUDIODEVINFODESKTOP Helper function for Audio device information on ML Desktop.

%   Copyright 2020-2022 The MathWorks, Inc.

% Local Constants
INPUT = 1;
OUTPUT = 0;

try
    switch nargin
        case 0
            devInfo = localGetAllDevices();
        case 1
            devInfo = localGetDeviceCount(varargin{:});
        case 2
            if isnumeric(varargin{2})
                devInfo = localGetDeviceName(varargin{:});
            else
                devInfo = localGetDeviceID(varargin{:});
            end
        case 3
            % NOT SUPPORTED for ML Online
            if strcmpi(varargin{3}, 'DriverVersion')
                warning(message('MATLAB:audiovideo:audiodevinfo:unsupportedDVSyntax'));
                devInfo = [];
            else
                error(message('MATLAB:audiovideo:audiodevinfo:invalidParameter'));
            end
        case 4
            devInfo = localFindDeviceWith(varargin{:});
        case 5
            devInfo = localDoesDeviceSupport(varargin{:});
    end
catch e
    throwAsCaller(e);
end


    function devices = localGetAllDevices()
        import audiovideo.internal.audio.utility

        % Return a structure of all input and output devices on the current system
        [success, audioOutputDeviceList, ~, audioInputDeviceList, ~, errorMsg] = ....
            audiovideo.internal.audio.utility.enumerateAudioDevicesOnBrowser;

        if ~success && ~isempty(errorMsg)
            throwAsCaller(MException('MATLAB:audiovideo:audiodevinfo:enumFailed', errorMsg));
        else
            audioDeviceList = [];

            % We have to remove the duplicate entries from the list.
            % There is usually an entry for a 'default' device and
            % another one which might correspond to 'communication' device.
            % If there are duplicates, remove the one with longer name
            isInputDeviceUnique = utility.getIsDeviceUnique(audioInputDeviceList);
            for ii=find(isInputDeviceUnique) % for all non-zero occurences in the array
                audioDeviceList = localAddDeviceInfo(audioInputDeviceList{ii}, INPUT, audioDeviceList);
            end
            inputDevices = audioDeviceList;

            isOutputDeviceUnique = utility.getIsDeviceUnique(audioOutputDeviceList);
            for ii=find(isOutputDeviceUnique) % for all non-zero occurences in the array
                audioDeviceList = localAddDeviceInfo(audioOutputDeviceList{ii}, OUTPUT, audioDeviceList);
            end

            if isempty(inputDevices)
                outputDevices = audioDeviceList;
            else
                outputDevices = audioDeviceList(length(inputDevices)+1:end);
            end
        end

        devices.input = inputDevices;
        devices.output = outputDevices;
    end

    function devices = localAddDeviceInfo( deviceInfo, IO, devices )

        devices(end+1).Name = deviceInfo;
        devices(end).DriverVersion = '';
        % devices IDs are zero based
        devices(end).ID = size(devices,2) - 1;
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

        devices = localGetDevicesByType(IO);
        deviceIndex = find([devices.ID] == ID);
        try
            deviceName = devices(deviceIndex).Name;
        catch
            error(message('MATLAB:audiovideo:audiodevinfo:invalidID'));
        end
    end

    function deviceID = localGetDeviceID(IO, name)

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

    function deviceID = localFindDeviceWith(IO, rate, bits, chans)

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


    function supported = localDoesDeviceSupport(mode, deviceID, sampleRate, numBits, numChannels)
        supported = true;
        if numBits ~= 24
            supported = false;
            return;
        end
        try
            localValidateDeviceType(mode);
            switch(mode)
                case INPUT
                    % Try creating audio recorder object for the specified
                    % parameters to verify if it's supported.
                    recObj = audiorecorder(sampleRate, numBits, numChannels, deviceID);
                    record(recObj);
                    stop(recObj);
                    clear recObj;
                case OUTPUT
                    y = zeros(int32(sampleRate),numChannels);
                    a = audioplayer(y, sampleRate, numBits, deviceID);
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


    function localValidateDeviceType(IO)
        if ~isempty(IO) && isnumeric(IO) && (IO == INPUT || IO == OUTPUT)
            return; % Valid value
        end

        error(message('MATLAB:audiovideo:audiodevinfo:invalidDeviceType'));
    end
end
