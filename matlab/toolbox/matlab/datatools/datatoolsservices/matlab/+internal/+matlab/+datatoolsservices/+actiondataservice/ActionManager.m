classdef ActionManager < handle
    % This class starts up the ActionDataService given a manager and
    % initializes all the actions for the service.

    % Copyright 2017-2024 The MathWorks, Inc.

    properties (Access={?matlab.unittest.TestCase, ?internal.matlab.datatoolsservices.actiondataservice.ActionManager}, WeakHandle)
        Manager internal.matlab.variableeditor.MLManager;
    end

    properties (SetAccess='protected', GetAccess='public')
        ActionDataService;
        ActionList;
    end

    methods
        % The Constructor starts up the ActionDataService with the namespace
        % and mode specified. The manager provided is passed in during
        % action initializations.
        function this = ActionManager(manager, remoteProvider, actionDataService)
            arguments
                manager (1,1) internal.matlab.variableeditor.MLManager;
                remoteProvider;
                actionDataService = internal.matlab.datatoolsservices.actiondataservice.ActionDataService(remoteProvider);
            end

            this.ActionDataService = actionDataService;
            this.Manager = manager;
            this.ActionList = containers.Map;
        end

        % This function scans for actions of type 'classType' from the
        % package 'startPath' and instantiates all the actions.
        % A list of all the actions are stored in this.ActionList
        function initActions(this, startPath, classType)
            if (nargin < 1) || isempty(startPath)
              startPath = 'internal';
            end
            mClasses = {};
            try
                mClasses = internal.findSubClasses(char(startPath), char(classType), true);
            catch
            end
           actionsLen = length(mClasses);
           internal.matlab.datatoolsservices.logDebug("ActionManager::initActions", "Number of actions:" + num2str(actionsLen));
           if actionsLen > 0
               for i=1:actionsLen
                    className = mClasses{i}.Name;
                    this.loadAction(className);
               end
               % Actions could be added after Manager/Documents are entirely initialized,
               % Initialize action states.
               this.ActionDataService.initActionStates();
           end
        end

        % Loads specific actions listed via actionClassPath on to the
        % ActionDataService
        function loadActions(this, actionClassPath)
            arguments
                this
                actionClassPath string = string.empty
            end
            for actionClass = actionClassPath
                this.loadAction(actionClass);
            end
            this.ActionDataService.initActionStates();
        end

        % Deletes all the action instances newed up.
        function delete(this)
            actionKeys = keys(this.ActionList);
            for i=1:length(actionKeys)
                delete(this.ActionList(actionKeys{i}));
            end
            if isvalid(this.ActionDataService)
                delete(this.ActionDataService);
            end
            this.ActionList=[];
        end
    end

    methods(Access=private)
        function loadAction(this, actionClass)
            % Creating Action instances by passing in an empty struct
            % for properties and the manager Instance. This properties
            % struct will be configured by individual actions.
            actionInstance = eval([char(actionClass) '(struct, this.Manager)']);
            this.ActionDataService.addAction(actionInstance);
            this.ActionList(actionClass) = actionInstance;
        end
    end
end

