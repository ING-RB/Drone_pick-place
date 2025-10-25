classdef ClientAppToolstrip < matlab.hwmgr.internal.Toolstrip
    % CLIENTAPPTOOLSTRIP - Toolstrip module specialization for the client
    % app framework.

    % Copyright 2021 The Mathworks, Inc.
    methods (Static)
        function out = getPropsAndCallbacks()
            out =  ... % Property to listen to         % Callback function
                [
                 "UserAddNonEnumDeviceDontSeeDevicePage" "handleUserAddNonEnumDeviceDontSeeDevicePage"; ...
                ];
            outSuper = matlab.hwmgr.internal.Toolstrip.getPropsAndCallbacks();

            out = [outSuper; out];
        end

        function out = getPropsAndCallbacksNoArgs()
            out =  ... % Property to listen to         % Callback function
                [
                     "DisableClientToolstripArea"        "disableClientToolstripArea"; ...
                ];
            outSuper = matlab.hwmgr.internal.Toolstrip.getPropsAndCallbacksNoArgs();

            out = [outSuper; out];
        end
    end
    
    methods
        function obj = ClientAppToolstrip(mediator)
            obj@matlab.hwmgr.internal.Toolstrip(mediator);
        end
        
        function handleUserAddNonEnumDeviceDontSeeDevicePage(obj, descriptor)
            obj.startNonEnumDeviceConfig(descriptor, "DontSeeDevicePage");
        end

        function disableClientToolstripArea(obj)
            % This method is called to disable all but the close session
            % section of a client app toolstrip tab

            % Get the main TS tab
            obj.logAndSet("MainTsTabRequest", true);

            % Add the tab if not already
            if isempty(obj.MainTabGroup.getChildByIndex())
                obj.addCloseSessionButton(obj.NewAppletTsTab);
                obj.addAndSelectTab(obj.NewAppletTsTab);
            end


            allSections = obj.AppletTab.getChildByIndex();
            % Disable all but the last section which is the Close Session
            % section
            for i = 1:numel(allSections)-1
                allSections(i).disableAll();
            end
        end


    end
    
    
end