classdef HwmgrAppController < matlabshared.mediator.internal.Publisher &...
        matlabshared.mediator.internal.Subscriber &...
        matlab.hwmgr.internal.MessageLogger
    %HWMGRAPPCONTROLLER The Hardware Manager app controller class

    % Copyright 2021-2022 The MathWorks, Inc.

    properties (SetObservable)
        MakeHwmgrWindowBusy
        RefreshDeviceList
        RefreshPlugins
        SelectDeviceByIndex
        SelectDeviceByPriority
    end

    methods (Static)
        function out = getPropsAndCallbacks()
            out =  ... % Property to listen to         % Callback function
                [
                    "DeviceSelectedOnStartPage"         "handleDeviceSelectedOnStartPage"; ...
                ];
        end

        function out = getPropsAndCallbacksNoArgs()
            out =  ... % Property to listen to         % Callback function
                [
                    "RefreshRequired"               "handleRefreshRequired"; ...
                    "SelectLastUsedDevice"              "handleSelectLastUsedDevice"; ...
                ];
        end
    end


    methods
        function obj = HwmgrAppController(mediator)
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);
        end

        function subscribeToMediatorProperties(obj, ~ ,~)
            eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);

            eventsAndCallbacksNoArgs = obj.getPropsAndCallbacksNoArgs();
            obj.subscribeWithGatewaysNoArgs(eventsAndCallbacksNoArgs, @obj.subscribe);
        end

        function refreshHwmgr(obj, doSoftLoad)
            % This method is called whenever the hardware manager is
            % refreshed. 
            
            arguments
               obj
               doSoftLoad (1,1) logical = true;
            end
            
            obj.makeHwmgrBusy();
            oc = onCleanup(@()obj.removeHwmgrBusy());
            
            obj.logAndSet("RefreshPlugins", doSoftLoad);
            obj.logAndSet("RefreshDeviceList", doSoftLoad);
        end

        function makeHwmgrBusy(obj)
            obj.logAndSet("MakeHwmgrWindowBusy", true);
        end

        function removeHwmgrBusy(obj)
            obj.logAndSet("MakeHwmgrWindowBusy", false);
        end

        function handleRefreshRequired(obj)
            obj.refreshHwmgr();
        end

        function handleDeviceSelectedOnStartPage(obj, deviceIndex)
            obj.logAndSet("SelectDeviceByIndex", deviceIndex);
        end

        function handleSelectLastUsedDevice(obj)
            obj.logAndSet("SelectDeviceByPriority", [-1]);
        end
    end
end
