classdef AppOpenObserver < handle
%

%   Copyright 2021-2024 The MathWorks, Inc.

    properties
        AppModel = []
    end

    properties (Access = private)
        Observer
        AppModelListener
        AppClientLoadedEventHasFired = false;
    end

    events
        AppClientLoaded
    end

    methods
        function obj = AppOpenObserver(observer, appModel)
            narginchk(1, 2);
            obj.Observer = observer;

            if nargin == 2
                obj.AppModel = appModel;
            end

            obj.AppModelListener = addlistener(obj.Observer, 'AppOpened', @obj.handleAppOpened);
        end
    end

    methods (Access = private)
        function handleAppOpened(obj, ~, event)
            appModel = event.AppModel;

            % When a listener triggers, AppModel may have a chance to be closed in App Designer, 
            % for instance, as g3404897 showed, the error came from the below code to access ~appModel.CodeGenerated.
            if isempty(appModel) || ~isvalid(appModel)
                return;
            end

            obj.AppModel = appModel;

            function tryToNotifyAppClientLoadedEvent(appModel)
                if isvalid(appModel) && ~obj.AppClientLoadedEventHasFired ...
                        && appModel.CodeGenerated && ~isempty(appModel.IsDirty)
                    obj.AppClientLoadedEventHasFired = true;
                    obj.notify('AppClientLoaded', appdesigner.internal.application.observer.AppOpenedEventData(appModel));
            
                end
            end

            % Since we do not need this event to be synchronous, we can get
            % rid of using waitfor() as before.
            % waitfor() is so easy to get MATLAB hang whenever there's feval call 
            % from JS side that is not dequed at PPE, so it's better to
            % only use it when synchronous execution is needed.
            % See g3513785 for more info.
            if ~appModel.CodeGenerated
                addlistener(appModel, 'CodeGenerated','PostSet', ...
                    @(~, ~)tryToNotifyAppClientLoadedEvent(appModel));
            end
            if isempty(appModel.IsDirty)
                addlistener(appModel, 'IsDirty','PostSet', ...
                    @(~, ~)tryToNotifyAppClientLoadedEvent(appModel));
            end
            
            % If any of the above is not true, at the end try to fire the event 
            tryToNotifyAppClientLoadedEvent(appModel);            
        end
    end
end
