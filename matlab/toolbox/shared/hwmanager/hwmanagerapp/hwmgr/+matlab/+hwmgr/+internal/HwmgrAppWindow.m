classdef HwmgrAppWindow < matlabshared.mediator.internal.Publisher &...
        matlabshared.mediator.internal.Subscriber & ...
        matlab.hwmgr.internal.MessageLogger
    %HWMGRAPPWINDOW Hardware Manager app window management class

    % Copyright 2021-2022 The MathWorks, Inc.

    properties
        %Window - The web window hosting the page
        Window

        %Url - URL of the start page
        Url

        %CloseRequestCached - Flag on if we have cached close request
        CloseRequestCached = false
    end

    properties(SetObservable)
        HwmgrWindowUrlRequest
    end

    properties (SetObservable, AbortSet)
        %SuspendClose - Flag on if window close will be suspended
        SuspendClose = false
    end

    methods (Static)
        function out = getPropsAndCallbacks()
            out =  ... % Property to listen tos         % Callback function
                [
                "HwmgrWindowUrl"                           "handleHwmgrWindowUrl"
                "SetSuspendClose"                          "handleSetSuspendClose"
                ];
        end

        function out = getPropsAndCallbacksNoArgs()
            out =  ... % Property to listen to         % Callback function
                [
                ];
        end
    end

    methods
        function obj = HwmgrAppWindow(mediator)
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);

            obj.addlistener('SuspendClose', 'PostSet', @(src, evt)obj.handleSuspendCloseChange());
        end

        function handleSuspendCloseChange(obj)
            % SuspendClose property PostSet callback
            if ~obj.SuspendClose && obj.CloseRequestCached
                obj.destroyFramework();
            end
        end

        function subscribeToMediatorProperties(obj, ~ ,~)
            eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);

            eventsAndCallbacksNoArgs = obj.getPropsAndCallbacksNoArgs();
            obj.subscribeWithGatewaysNoArgs(eventsAndCallbacksNoArgs, @obj.subscribe);
        end

        % ------------- Start --- Mediator callbacks ---------------
        function handleHwmgrWindowUrl(obj, url)
            if isempty(obj.Window)
                obj.createWindow(string(url));
            else
                obj.Window.URL = url;
            end
        end

        function handleSetSuspendClose(obj, flag)
            obj.SuspendClose = flag;
        end
        
        % -------------- End ---- Mediator callbacks ---------------

        function createWindow(obj, url)
            obj.Window = matlab.internal.webwindow(url, matlab.internal.getDebugPort());          

            % Callback when user clicks on "x" of Hardware Manager app
            obj.Window.CustomWindowClosingCallback = @(src, event)obj.destroyFramework();
            
            % Callback when MATLAB is closing
            obj.Window.MATLABClosingCallback = @(src, event)obj.handleMATLABClose();

            % Callback when the MATLABWindow process has exited unexpectedly
            obj.Window.MATLABWindowExitedCallback = @(src, event)obj.destroyFramework();

            obj.Window.Title = message('hwmanagerapp:framework:AppName').getString;
            screenSize = get( groot, 'Screensize' );
            obj.Window.Position =  [0.125*screenSize(3), 0.125*screenSize(4), ...
                .75 * screenSize(3), .75*screenSize(4)];
        end

        function closeDisplay(obj)
            % Method invoked by display manager
            % Close the Hardware Manager app UI

            obj.Window.close();
        end

        function show(obj)
            % Method invoked by display manager
            % Bring to front

            obj.Window.bringToFront();
        end

        function showDisplay(obj)
            % Method invoked by display manager
            % Render the display, may call show()
            if isempty(obj.Window)
                obj.logAndSet("HwmgrWindowUrlRequest", true);
            end

            obj.Window.show();
            obj.Window.bringToFront();
        end

        function visible = isShowing(obj)
            if isempty(obj.Window)
                visible = false;
                return
            end

            % Method invoked by display manager
            visible = obj.Window.isVisible();
        end

        function destroyFramework(obj)
            if obj.SuspendClose
                obj.CloseRequestCached = true;
                return;
            end

            obj.CloseRequestCached = false;

            % Close app window then destroy framework
            obj.Window.close();

            % First find the framework instance that corresponds to
            % this window
            allInstances = matlab.hwmgr.internal.HardwareManagerFramework.getAllInstances();
            for i = 1:numel(allInstances)
                if isvalid(allInstances(i)) && allInstances(i).DisplayManager.Window == obj
                    delete(allInstances(i));
                    break;
                end
            end
        end

        function delete(obj)
            if ~isempty(obj.Window) && isvalid(obj.Window)
                obj.Window.close();
                delete(obj.Window);
            end
        end

        function handleMATLABClose(obj)
            % This is called when MATLAB is closing. webwindow will veto
            % MATLAB closing and then fire this callback. So we need to
            % call exit again.
            obj.destroyFramework();
            exit;
        end
    end
end