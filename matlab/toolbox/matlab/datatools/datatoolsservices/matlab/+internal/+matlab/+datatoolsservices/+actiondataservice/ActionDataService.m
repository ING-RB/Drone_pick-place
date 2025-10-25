classdef ActionDataService < handle
    %ACTIONDATASERVICE handle class from the ActionDataService Framework
    
    % This class can be used to perform CRUD operations on a set of actions.
    % The service is initialized with a provider that can be in-memory or
    % remote. The remoteProvider takes care of communication and
    % synchronization with the client.
    
    % Copyright 2017-2023 The MathWorks, Inc.
    
    properties (SetAccess='protected') 
       Actions;     
    end
    
    properties (SetObservable=true, SetAccess='protected')       
       RemoteProvider;
    end 
    
    methods        
       
        function this = ActionDataService(remoteProvider)
            this.RemoteProvider = remoteProvider;           
            this.Actions = containers.Map;          
        end        

        % Allows users to addAction using an action instance or a set of
        % action properties.
        function action = addAction(this, action)           
            if (nargin<2) || isempty(action) 
                error(message('MATLAB:codetools:datatoolsservices:InvalidAction'))
            elseif(isKey(this.Actions, action.ID))
                error(message('MATLAB:codetools:datatoolsservices:DuplicateActionID',action.ID));           
            else
                RemoteAction = this.RemoteProvider.addAction(action);
                this.Actions(action.ID) = RemoteAction;
            end
        end       
        
        % Allows users to update an action's existing properties or add new properties.
        % Users cannot updateAction if the Action was not previously added
        % using addAction or if the properties specified are not {name-value} pairs.
        function updatedAction = updateAction(this, id, varargin)            
            if (isKey(this.Actions, id))
                action = this.Actions(id);
                if (rem(length(varargin{:})-2,2)) ~=0
                    error(message('MATLAB:codetools:datatoolsservices:PropertyValuePairsExpected'));                    
                end
                updatedAction = action.updateActionProperty(varargin{:});
            else               
                error(message('MATLAB:codetools:datatoolsservices:IncorrectActionID', id));                    
            end
        end
        
        % Allows users to remove an action from the ActionDataService. 
        function removeAction(this, id)           
            if (isKey(this.Actions, id))                 
                RemoteAction = this.Actions(id);
                delete(RemoteAction);
                remove(this.Actions, id);
            else               
                error(message('MATLAB:codetools:datatoolsservices:IncorrectActionID', id));                    
            end
        end          
        
        % Enables an action specified by the actionID
        function enableAction(this, id)
            this.updateAction(id, {'Enabled', true});
        end        
        
        % Disables an action specified by the actionID
        function disableAction(this, id)
            this.updateAction(id, {'Enabled', false});
        end        
        
        % Allows users to execute an action by passing in an action instance or 
        % the ID of the Action. Users cannot executeAction if the Action
        % specified does not exist.        
        function executeAction(this, varargin)            
            if isa(varargin{1}, 'internal.matlab.datatoolsservices.actiondataservice.Action')                
                ID = varargin{1}.ID;                
            else 
                ID = varargin{1};
            end            
            if (isKey(this.Actions, ID))
                RemoteAction = this.Actions(ID);
                RemoteAction.executeCallBack(varargin{:});
            else
                error(message('MATLAB:codetools:datatoolsservices:IncorrectActionID', ID));
            end           
        end
        
        % Gets a list of all the actions in the ActionDataService.
        function ActionList = getAllActions(this)
            ActionList = internal.matlab.datatoolsservices.actiondataservice.Action.empty();
            if ~(isempty(this.Actions))
                actionKeys = keys(this.Actions);
                for index = 1:length(actionKeys)
                    RemoteAction = this.Actions(actionKeys{index});

                    % TODO: Cleanup wrapper classes
                    % Our RemoteAction classes have the action as a sub
                    % property instead of extending the action.
                     ActionList(index) = RemoteAction.Action;
                end
            end
        end
        
        % Gets an action specified by the actionID
        function action = getAction(this, actionId)
            action = [];
            if ~(isempty(this.Actions))
                actionKeys = keys(this.Actions);
                for index = 1:length(actionKeys)
                    if isequal(actionKeys{index}, actionId)
                        action = this.Actions(actionKeys{index});
                        break;
                    end                    
                end
            end
        end

        function initActionStates(~)
        end
        
        function delete(this)
            if ~isempty(this.RemoteProvider)
                try
                    delete(this.RemoteProvider);
                    this.RemoteProvider = [];
                catch
                end
            end
        end
    end 
end

