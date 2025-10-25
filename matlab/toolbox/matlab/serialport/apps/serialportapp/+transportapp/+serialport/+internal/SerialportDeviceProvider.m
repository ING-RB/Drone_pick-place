classdef SerialportDeviceProvider < matlab.hwmgr.internal.DeviceProviderBase
    % SERIALPORTDEVICEPROVIDER provides Hardware Manager with available and
    % busy serial ports.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Access = private)
        AllSerialPorts
    end

    properties (Constant)
        % Device card display labels
        DeviceCardName = string(message("transportapp:serialportapp:DeviceCardName").getString)
        DeviceCardIcon = matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIcon("hwmgrclient", "SerialDeviceCard")
    end

    methods
        function devices = getDevices(obj)
            % Returns the list of serial ports.

            obj.AllSerialPorts = serialportlist("all");

            % Create hardware manager devices for all detected serial ports
            devices = createHwmgrDevices(obj);
        end
    end

    methods (Access = private)
        function devices = createHwmgrDevices(obj)
            % Creates hardware manager devices for all serial ports.

            devices = [];

            for serialPort = obj.AllSerialPorts
                device = matlab.hwmgr.internal.Device(obj.DeviceCardName);
                device.IconID = obj.DeviceCardIcon;

                % Save the Port and BaudRate(default 9600) to be used by
                % the serialport app to form a connection to the
                % serial port.
                device.CustomData.TransportProperties = struct("Port",serialPort,"BaudRate",9600);

                % Set "Port" to the COM port that will be displayed on
                % the device card.
                device.DeviceCardDisplayInfo = ["Port",serialPort];

                device.DeviceAppletData = matlab.hwmgr.internal.data.DataFactory.createDeviceAppletData("transportapp.serialport.internal.SerialportApp");

                devices = [devices device]; %#ok<AGROW>
            end
        end
    end
end
