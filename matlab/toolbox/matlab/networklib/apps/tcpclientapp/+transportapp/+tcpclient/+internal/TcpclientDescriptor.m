classdef TcpclientDescriptor < matlab.hwmgr.internal.DeviceParamsDescriptor & ...
        matlabshared.testmeasapps.internal.dialoghandler.DescriptorDialogCompatibleMixin & ...
        matlabshared.mediator.internal.Publisher & ...
        matlabshared.testmeasapps.internal.dialoghandler.DialogMixin & ...
        matlabshared.testmeasapps.internal.ITestable
    %TCPCLIENTDESCRIPTOR class creates the DeviceParamsDescriptor object
    % and also does the following:
    % 1. It sets the Icon for the tcpclient app Widgets.
    % 2. It validates the tcpclient app Address property when user clicks
    % on "Confirm". It also validates the TCP/IP connection.
    % 3. Creates the hardware manager device when user clicks on "Confirm"

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (Constant)
        Tag = "Tcpclient Descriptor"

        AddressDefault = ""

        PortDefault = ""

        ConnectTimeoutDefault = "10"

        MapTopicID = "tcpip_app_csh"

        TooltipText = message("transportapp:tcpclientapp:TooltipText").getString();

        TransferDelayDropdownValues (1, :) string = [string(message("transportapp:tcpclientapp:EnabledValue").getString), ...
            string(message("transportapp:tcpclientapp:DisabledValue").getString)]

        TransferDelayDropdown containers.Map = ...
            containers.Map(transportapp.tcpclient.internal.TcpclientDescriptor.TransferDelayDropdownValues, [true, false])

        DeviceCardIcon = matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIcon("hwmgrclient", "TCPClientDeviceCard")
    end

    %% Lifetime
    methods
        function obj = TcpclientDescriptor(mediator, name)
            narginchk(2, 2)

            % Create the DescriptorProperties and use it for the creation of the
            % DeviceParamsDescriptor object.
            descriptorProperties = transportapp.tcpclient.internal.DescriptorProperties;
            descriptorProperties.Name = name;
            descriptorProperties.TopicID = transportapp.tcpclient.internal.TcpclientDescriptor.MapTopicID;
            descriptorProperties.TooltipText = transportapp.tcpclient.internal.TcpclientDescriptor.TooltipText;

            % Call base constructors
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.testmeasapps.internal.dialoghandler.DialogMixin(mediator);
            obj@matlab.hwmgr.internal.DeviceParamsDescriptor(...
                descriptorProperties.Name, ...
                descriptorProperties.MATLABDocMap, ...
                descriptorProperties.TopicID, ...
                descriptorProperties.TooltipText, ...
                descriptorProperties.Enabled);
            obj.DisplayName = getString(message("transportapp:tcpclientapp:DeviceCardName"));
        end
    end

    %% Abstract method implementation
    methods
        function validateParams(~, paramMap)
            % This function is called internally by Hardware Manager when
            % the "Confirm" button is clicked. If this method errors out,
            % the Tcpclient Descriptor is not created.

            import transportapp.tcpclient.internal.DescriptorValidator

            % Check that all properties are non-empty.
            if DescriptorValidator.isFieldEmpty(paramMap)
                throw(MException(message("transportapp:tcpclientapp:FieldsEmpty")));
            end

            % Validate the IP address or hostname entered
            if isKey(paramMap, "Address")
                value = paramMap("Address").NewValue;
                resolvedStruct = matlabshared.network.internal.mex.resolve(string(value));

                % mex.resolve resolves Address and HostName. It returns an
                % Error when either of the two are not resolved. In the app,
                % the Address field needs to be checked to confirm that the
                % IP Address was not resolved(invalid) as a non-empty Error
                % field could mean that the HostName was not resolved but the
                % Address could have resolved.
                if resolvedStruct.Address == "" && resolvedStruct.Error ~= ""
                    errorID = "transportapp:tcpclientapp:InvalidAddress";
                    completeMsg = string(message(errorID, value).getString) ...
                        + newline + resolvedStruct.Error;
                    throw(MException(errorID, completeMsg));
                end
            end

            % Validate the parameters by forming a connection.
            % Automatically disconnects and clears the connection when
            % tcpclientObj goes out of scope.
            try
                tcpclientObj = matlabshared.network.internal.TCPClient(string(paramMap("Address").NewValue), ...
                    str2double(paramMap("Port").NewValue));
                connect(tcpclientObj);
            catch ex
                ex = MException(ex.identifier, message("transportapp:tcpclientapp:ConnectionError").getString);
                throw(ex);
            end
        end

        function device = createHwmgrDevice(obj, paramMap)
            % This function is called internally by Hardware Manager that
            % creates the actual Hardware Manager Device.

            % Create a Hardware Manager device
            device = matlab.hwmgr.internal.Device(obj.DisplayName);

            % Device card icon
            device.IconID = obj.DeviceCardIcon;

            % Create the Device card for the TCP/IP device. The device card
            % shows - Address and Port
            device.DeviceCardDisplayInfo = [ ...
                getString(message("transportapp:tcpclientapp:DeviceCardAddress")), string(paramMap("Address").NewValue); ...
                getString(message("transportapp:tcpclientapp:DeviceCardPort")), string(paramMap("Port").NewValue)
                ];

            device.CustomData.TransportProperties.Address = string(paramMap("Address").NewValue);
            device.CustomData.TransportProperties.Port = string(paramMap("Port").NewValue);
            device.CustomData.TransportProperties.ConnectTimeout = string(paramMap("ConnectTimeout").NewValue);

            device.DeviceAppletData = matlab.hwmgr.internal.data.DataFactory.createDeviceAppletData("transportapp.tcpclient.internal.TcpclientApp");
            device.CustomData.TransportProperties.EnableTransferDelay = obj.TransferDelayDropdown(string(paramMap("TransferDelay").NewValue));
        end

        function icon = getIcon(~)
            % This function is called internally by Hardware Manager when
            % it tries to create the tcpclient app Widget.
            icon =  matlabshared.testmeasapps.internal.themeableiconrepository.IconRepository.getIcon("hwmgrclient", "TCPClientDeviceCard_Descriptor");
        end
    end

    %% Callback functions for validation
    methods
        function value = addressValuesFcn(obj, paramMap)
            % This function validates and sets the user entry to the
            % Address Property.

            import transportapp.tcpclient.internal.DescriptorValidator

            [value, ex] = DescriptorValidator.validateTextFieldValue(paramMap, "Address", ...
                "", obj.AddressDefault);
            if ~isempty(ex)
                handleErrorProxy(obj, ex);
            end
        end

        function value = portValuesFcn(obj, paramMap)
            % This function validates and sets the user entry to the
            % Port Property.

            import transportapp.tcpclient.internal.DescriptorValidator

            [value, ex] = DescriptorValidator.validateTextFieldValue(paramMap, "Port", ...
                "transportapp:tcpclientapp:InvalidPort", obj.PortDefault);
            if ~isempty(ex)
                handleErrorProxy(obj, ex);
            end
        end

        function value = connectTimeoutValuesFcn(obj, paramMap)
            % This function validates and sets the user entry to the
            % ConnectTimeout Property.

            import transportapp.tcpclient.internal.DescriptorValidator

            [value, ex] = DescriptorValidator.validateTextFieldValue(paramMap, "ConnectTimeout", ...
                "transportapp:tcpclientapp:InvalidConnectTimeout", obj.ConnectTimeoutDefault);
            if ~isempty(ex)
                handleErrorProxy(obj, ex);
            end
        end

        function value = transferDelayValuesFcn(obj, paramMap)
            % This function returns the dropdown list for Transfer Delay.

            if isempty(paramMap("TransferDelay").NewValue)
                value = obj.TransferDelayDropdownValues;
            else
                value.Value = paramMap("TransferDelay").NewValue;
                value.List = obj.TransferDelayDropdownValues;
            end
        end
    end
end
