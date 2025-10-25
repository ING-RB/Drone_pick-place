classdef AppletBase < handle & matlab.mixin.Heterogeneous ...
        & matlab.hwmgr.internal.DialogMixin ...
        & matlab.hwmgr.internal.SidePanelMixin ...
        & matlab.hwmgr.internal.StatusBarMixin ...
        & matlab.hwmgr.internal.AppContainerAccessMixin ...
        & matlab.hwmgr.internal.ContextMenuMixin ...
        & matlab.hwmgr.internal.ContextualToolstripTabMixin
    %APPLETBASE This is the base clase for creating an
    %applet in hardware manager

    % Copyright 2017-2023 The MathWorks, Inc.


    properties
        ToolstripTabHandle
        RootWindow
        DeviceInfo
        
        % SaveOnDestroyData should be set by applet implementors if it is
        % required that this data should saved to the prefdir and loaded
        % again on next launch and set to AutoLoadedData below
        SaveOnDestroyData

        % AllowMultipleInstances is a logical/boolean flag that controls
        % whether multiple instances of the app can be launched. The
        % default value is enabled/true.
        AllowMultipleInstances (1,1) logical = true
    end
    
    properties (SetAccess = {?matlab.hwmgr.internal.AppletRunner, ?matlab.hwmgr.legacy.AppletRunner, ?matlab.unittest.TestCase}, GetAccess = public)
        % Applet Runner sets this property for clients who save data for
        % auto load
        AutoLoadedData
        
        % Applet Runner sets this property to capture which lifecycle stage
        % the applet is currently in
        AppletState
    end
    
    properties (Access = private)
        CloseAppletFcn = function_handle.empty;
    end
    
    properties(Constant, Abstract)
        DisplayName
    end
    
    methods(Abstract)
        construct(obj)
        run(obj)
        destroy(obj)
        okayToClose = canClose(obj, reason)
    end
    
    % The following methods can optionally be overridden
    methods
        
        function init(obj, hwmgrHandles)
            % This method assigns the contents of hwmgrHandles to Applet Base
            % properties
            
            obj.ToolstripTabHandle = hwmgrHandles.ToolstripTabHandle;
            obj.RootWindow = hwmgrHandles.RootWindow;
            obj.DeviceInfo = hwmgrHandles.DeviceInfo;

            % Grab handles to contextual toolstrip control methods.
            obj.setContextualTabControlFcns(hwmgrHandles.ContextualTabControlFcns);
        end
            
        function visible = isAppletTabVisible(~)
           % This method indicates whether the applet tab should be visible
           % or not.
           %
           % If an app does not intend to use the toolstrip tab, this
           % method can be overridden to return false.
           %
           % The default behavior is to return true (i.e. show the
           % tooltstrip tab for the app).
           visible = true; 
        end
        
        function constructorOptions = getConstructorOptions(obj, ~)
            % Get the function handle to the applet constructor
            constructorOptions = {str2func(class(obj))};
        end
        
        function icon = getIcon(~)
            % Get the icon for the applet to be used in the applet gallery
            % in the hardware manager device tab. This is a default icon.
            % Teams must override this method and provide the correct icon.
           icon = "app"; 
        end
        
        function displayName = getDisplayName(obj, varargin)
           % Default method to return the display name. This method can be
           % overriden a custom display name
           displayName = obj.DisplayName;
        end
    
        function tag = getTagForGalleryButton(obj, ~)
            % Default implementation to construct a display name based tag
            % that will be used for tagging the applet button in the applet
            % gallery on the device tab
            tag = char(upper(strrep(obj.getDisplayName(), ' ', '_')));
        end

        function contextDefs = createContextDefinitions(~)
            contextDefs = [];
        end

    end
    
    
    methods (Sealed)
        function closeApplet(obj, closeReason)
            if ~isempty(obj.CloseAppletFcn)
               obj.CloseAppletFcn(closeReason, obj);
            end
        end
        
        function setCloseAppletFcn(obj, fcnHandle)
           validateattributes(fcnHandle, {'function_handle'}, {});
           obj.CloseAppletFcn = fcnHandle;
        end

        function setActiveContextTags(obj, tags)
           obj.AppContainer.ActiveContexts = tags;
        end

        function contextTags = getActiveContextTags(obj)
            contextTags = obj.AppContainer.ActiveContexts;
        end
        
    end
    
    
    methods(Static)
        supportFlag = isDeviceSupported(device)
    end
    
end

