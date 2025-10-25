classdef DynamicTabs < handle
    % Mixin to control and manage Dynamic tabs.
    % Should be used with matlabshared.application.Application subclasses,
    % but can be used elsewhere if the subclass has a Toolstrip property
    % (publicly gettable) and the controller(s) used have a
    % getDynamicTabs method.
    %
    % To make a modal tab (a tab that temporarily removes the other tabs)
    % use 2 controllers, one installs the normal tabs and one that installs
    % the modal tab. This will remove all the existing tabs and add the
    % modal.
    %
    % To make a context tab (a tab that appears and disappears based on
    % context) create a normal toolstrip with fixed tabs. When the context
    % tab is not to be shown set the controller to [], when it is pass the
    % context controller.
    %
    % To make a mix of context and modal tabs, use a style similar to the
    % one outlined for modal tabs, but change the output of the
    % getDynamicTabs on the non-modal controller dependent on the
    % current context and directly make a call to updateDynamicTabs when
    % needed.
    
    %   Copyright 2020 The MathWorks, Inc.
    properties (Hidden)
        DynamicTabController
    end
    
    properties (SetAccess = protected, Hidden)
        CurrentDynamicTabs = [];
    end
    
    methods
        function set.DynamicTabController(this, component)
            this.DynamicTabController = component;
            updateDynamicTabs(this);
        end
    end
    
    methods (Access = protected)
        
        % Moved to a method in case a subclass wishes to use a single
        % object for the controller.
        function updateDynamicTabs(this)
            
            currentTabs = this.CurrentDynamicTabs;
            
            % Add the tabs associated with the new scope.
            component = this.DynamicTabController;
            if isempty(component)
                newTabs = [];
            else
                newTabs = getDynamicTabs(component);
            end
            
            % Return early if the tabs are identical (not the same buttons
            % but the same tab handles).
            if isequal(currentTabs, newTabs)
                return;
            end
            
            toolstrip = this.Toolstrip;
            if isempty(toolstrip)
                return;
            end
            
            remove = true(numel(currentTabs), 1);
            toAdd = newTabs;
            for indx = 1:numel(currentTabs)
                if isempty(toAdd)
                    break
                elseif currentTabs(indx) == toAdd(1)
                    remove(indx) = false;
                    toAdd(1) = [];
                elseif isempty(find(currentTabs == toAdd(1), 1, 'first'))
                    break;
                end
            end
            % Remove the old tabs in reverse order to minimize flicker.
            remove = find(remove);
            for indx = numel(remove):-1:1
                try
                    toolstrip.remove(currentTabs(remove(indx))); %#ok<*MCNPN>
                catch ME %#ok<NASGU>
                    % NO OP, can get error on remove in edge cases while UI
                    % is closing down.
                end
            end
            
            % Add the new tabs
            for indx = 1:numel(toAdd)
                toolstrip.add(toAdd(indx));
            end
            
            % Cache the tabs for later removal.
            this.CurrentDynamicTabs = newTabs;
        end
    end
end

% [EOF]
