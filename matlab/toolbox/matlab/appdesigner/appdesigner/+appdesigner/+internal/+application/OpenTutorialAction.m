classdef OpenTutorialAction < appdesigner.internal.application.DesktopAction
% OPENTUTORIALACTION A class representing the action of opening a tutorial.

% Copyright 2018-2022 The MathWorks, Inc.

    properties (Access = private)
        TutorialName char
        AppToOpen char
    end

    methods
        function obj = OpenTutorialAction(tutorialName, appToOpen)
            arguments
                tutorialName,
                appToOpen = '';
            end

            obj.TutorialName = tutorialName;
            obj.AppToOpen = appToOpen;
        end

        function runAction(obj, proxyView)
            proxyView.sendEventToClient('openTutorial', {'TutorialName', obj.TutorialName, 'FilePath', obj.AppToOpen});
        end
    end
end
