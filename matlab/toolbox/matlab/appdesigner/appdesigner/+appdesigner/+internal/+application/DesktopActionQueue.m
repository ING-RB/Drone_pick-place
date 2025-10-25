classdef DesktopActionQueue < handle
% DESKTOPACTIONQUEUE A class that tracks the actions that must be delayed until App Designer is fully started.
% Enforces some restrictions on the ordering of these actions - Apps must be opened first, then a new app created,
% then finally a tutorial opened.  These actions can be performed before App Designer is started, but they will
% not actually occur until that point.

% Copyright 2018-2023 The MathWorks, Inc.

    properties (Access = private)
        AppCreationActions appdesigner.internal.application.CreateNewAppAction,
        AppOpeningActions appdesigner.internal.application.OpenAppAction,
        TutorialOpeningActions appdesigner.internal.application.OpenTutorialAction
    end

    methods
        function obj = DesktopActionQueue()
            obj.reset();
        end

        function openTutorial(obj, tutorialName, appToOpen)
            arguments
                obj,
                tutorialName,
                appToOpen = '';
            end

            % Enqueue an action to open a tutorial.
            obj.TutorialOpeningActions(end + 1) = appdesigner.internal.application.OpenTutorialAction(tutorialName, appToOpen);
        end

        function openApp(obj, filePath)
            % Enqueue an action to open an existing app.
            if ~obj.hasAppOpeningAction(filePath)
                obj.AppOpeningActions(end + 1) = appdesigner.internal.application.OpenAppAction(filePath);
            end
        end

        function createNewApp(obj, appFeatures)
            % Enqueue an action to create a new app.
            % Only one new app can be created on startup.

            if isempty(obj.AppCreationActions)
                obj.AppCreationActions(end + 1) = appdesigner.internal.application.CreateNewAppAction(appFeatures);
            end
        end

        function openAppDetails(obj, filePath)
            % Enqueue an action to open the App Details dialog for an existing app.
            openingAction = obj.findAppOpeningAction(filePath);

            if isempty(openingAction)
                openingAction = appdesigner.internal.application.OpenAppAction(filePath);
                obj.AppOpeningActions(end + 1) = openingAction;
            end

            openingAction.whenAppLoaded('ShowAppDetails');
        end

        function flush(obj, proxyView)
            % Perform all the actions in the queue.
            % Arguments:
            %   proxyView - used to send messages over peer model to
            %     the App Designer client.
            for ix = 1:length(obj.AppOpeningActions)
                obj.AppOpeningActions(ix).runAction(proxyView);
            end

            for ix = 1:length(obj.AppCreationActions)
                obj.AppCreationActions(ix).runAction(proxyView);
            end

            for ix = 1:length(obj.TutorialOpeningActions)
                obj.TutorialOpeningActions(ix).runAction(proxyView);
            end

            obj.reset();
        end
    end

    methods (Access = private)

        function reset(obj)
            % Clear out the queue.
            obj.AppCreationActions = appdesigner.internal.application.CreateNewAppAction.empty();
            obj.AppOpeningActions = appdesigner.internal.application.OpenAppAction.empty();
            obj.TutorialOpeningActions = appdesigner.internal.application.OpenTutorialAction.empty();
        end

        function openingAction = findAppOpeningAction(obj, filename)
            % Finds an existing AppOpeningAction in the queue
            % with the passed filename, to avoid adding duplicates.
            openingAction = [];

            for ix = 1:length(obj.AppOpeningActions)
                if strcmpi(obj.AppOpeningActions(ix).getFilePath(), filename)
                    openingAction = obj.AppOpeningActions(ix);
                    break;
                end
            end
        end

        function hasAction = hasAppOpeningAction(obj, filename)
            hasAction = ~isempty(obj.findAppOpeningAction(filename));
        end
    end
end
