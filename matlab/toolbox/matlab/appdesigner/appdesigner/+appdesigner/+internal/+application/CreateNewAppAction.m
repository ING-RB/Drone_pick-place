classdef CreateNewAppAction < appdesigner.internal.application.DesktopAction
    % CREATENEWAPPACTION A class representing the action of creating a new blank app.

    % Copyright 2018-2023 The MathWorks, Inc.

    properties(Access=private)
        AppFeatures
    end

    methods
        function obj = CreateNewAppAction(appFeatures)
            narginchk(1,1);
            obj.AppFeatures = appFeatures;
        end

        function runAction(obj, proxyView)
            proxyView.sendEventToClient('createApp', obj.AppFeatures);
        end
    end
end
