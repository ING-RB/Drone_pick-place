classdef TcpclientDeviceProvider < matlab.hwmgr.internal.DeviceProviderBase
    % TCPCLIENTDEVICEPROVIDER provides Hardware Manager with non-enumerable
    % device descriptors.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties(Access = {?matlabshared.transportapp.internal.utilities.ITestable, ...
            ?transportapp.tcpclient.internal.TcpclientDeviceProvider})
        Mediator

        % Descriptor Object
        TcpclientDescriptor
    end

    properties (Constant)
        % The Name of the configuration tab property section
        PropertiesSection = message("transportapp:tcpclientapp:PropertiesSection").getString
    end

    %% DeviceProviderBase template methods implemented
    methods
        function devices = getDevices(~)
            % Provide the list of discoverable ICT devices to Hardware
            % Manager. This returns empty as TCP/IP devices not detected.
            devices = [];
        end

        function descriptor = getDeviceParamDescriptors(obj)
            % Provide the list of non-enumerable devices to Hardware
            % Manager.

            % If descriptors have not been created, create the device
            % descriptors for the first time
            if isempty(obj.TcpclientDescriptor)
                createTcpclientDeviceDescriptor(obj);
            end

            % Return the descriptors to Hardware Manager to show under
            % "Device List"
            descriptor = obj.TcpclientDescriptor;
        end
    end

    %% Helper Methods
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable, ...
            ?transportapp.tcpclient.internal.TcpclientDeviceProvider})
        function createTcpclientDeviceDescriptor(obj)
            % Create the Tcpclient descriptors for the first time.

            % Create mediator
            obj.Mediator =  matlabshared.mediator.internal.Mediator;

            obj.TcpclientDescriptor = createDescriptor(obj);

            % Connect the mediator
            obj.Mediator.connect;
        end

        function tcpclientDescriptor = createDescriptor(obj)
            % Create and return the Tcpclient descriptor

            tcpclientDescriptor = transportapp.tcpclient.internal.TcpclientDescriptor ...
                (obj.Mediator, message("transportapp:tcpclientapp:DescriptorCardName").getString);

            % Populate the configuration tab.
            tcpclientDescriptor = addParametersToDescriptor(obj, tcpclientDescriptor);
        end

        function tcpclientDescriptor = addParametersToDescriptor(obj, tcpclientDescriptor)
            % Add parameters to the descriptor object. This populates the
            % tcpclient app configuration tab parameters.

            fieldLabel = @(msgLabel) message("transportapp:tcpclientapp:" + msgLabel + "Label").getString();

            % Create the configuration tab properties for the tcpclient app
            tcpclientDescriptor.addParameter('Address', fieldLabel("Address"), 'EditField', ...
                @tcpclientDescriptor.addressValuesFcn, function_handle.empty, obj.PropertiesSection);
            tcpclientDescriptor.addParameter('Port', fieldLabel("Port"), 'EditField', ...
                @tcpclientDescriptor.portValuesFcn, function_handle.empty, obj.PropertiesSection);
            tcpclientDescriptor.addParameter('ConnectTimeout', fieldLabel("ConnectTimeout"), 'EditField', ...
                @tcpclientDescriptor.connectTimeoutValuesFcn, function_handle.empty, obj.PropertiesSection);
            tcpclientDescriptor.addParameter('TransferDelay', fieldLabel("TransferDelay"), 'DropDown', ...
                @tcpclientDescriptor.transferDelayValuesFcn, function_handle.empty, obj.PropertiesSection);
        end
    end
end
