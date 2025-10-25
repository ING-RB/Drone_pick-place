classdef AppContainerAccessMixin < handle
    % Mixin class providing APIs to access the appcontainer handle. This
    % mixin class can be added to client app interfaces where appcontainer
    % access is needed.

    % Copyright 2022 Mathworks Inc.


    properties (Access = protected)
        AppContainer
    end


    methods (Access = {?hwmgr.test.internal.TestCase, ?matlab.hwmgr.internal.AppletRunner, ?matlab.hwmgr.internal.Toolstrip})

        function setDialogParent(obj, dialogParent)
            obj.AppContainer = dialogParent;
        end

    end

    methods (Hidden)
        
        function parent = getDialogParent(obj)
            % This is method is a temporary solution to allow the Arduino
            % IO App to be able to show progress dialogs during
            % intialization. This will be replaced with an API to show
            % uiprogressdialogs via the framework (g2615775) at which point
            % this method should no longer be used.
            parent = obj.AppContainer;
        end
    end

end