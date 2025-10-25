classdef (Hidden) WorkspaceDropDownController < ...
        matlab.ui.control.internal.controller.DropDownController

    % WorkspaceDropDownController: This is the controller for the object
    % matlab.ui.control.internal.model.WorkspaceDropDown.

    % Copyright 2018-2024 The MathWorks, Inc.

    methods
        function obj = WorkspaceDropDownController(varargin)
            obj@matlab.ui.control.internal.controller.DropDownController(varargin{:});
        end

        % Triggers a ValueChanged callback if the Value changes as a result
        % of populating the DropDown from the latest variables in the
        % workspace. This can happen when a selected variable was cleared
        % by the user.
        function triggerValueChanged(obj)
            oldValue = obj.Model.Value;

            obj.Model.populateVariables();

            if ~strcmp(obj.Model.Value,oldValue)
                eventData = matlab.ui.eventdata.ValueChangedData(...
                    obj.Model.Value, ...
                    oldValue);
                obj.handleUserInteraction('StateChanged', {}, {'ValueChanged', eventData});
            end
        end

        function excludedPropertyNames = getExcludedComponentSpecificPropertyNamesForView(~)
            % Hook for subclasses to provide a list of property names that
            % needs to be excluded from the properties to sent to the view at Run time

            excludedPropertyNames = {'WorkspaceValue'; 'ValueIndex'};
        end
    end

    methods(Access = 'protected')

        % Override the super's handleEvent
        function handleEvent(obj, src, event)
            % HANDLEEVENT(OBJ, ~, EVENT) this method is invoked each time
            % user changes the state of the component


            % Overriding the super class method because this class needs to
            % handle the DropDownOpening event.
            currVal = obj.Model.Value;
            handleEvent@matlab.ui.control.internal.controller.DropDownController(obj, src, event);

            % obj.Model.Value can change in the super method handleEvent call
            if ~isequal(currVal, obj.Model.Value)
                % Value changed by the user, clear out the
                % NonExistentVariableName if it was set.
                obj.Model.NonExistentVariableName = strings(0);
            end

            if strcmp(event.Data.Name, 'DropDownOpening')
                try
                    obj.triggerValueChanged();
                catch
                    % Ignore errors here.  It's possible the dropdown is deleted
                    % while it was in the process of being opened
                end
            end
        end

        function validIndex = validateItemIndex(obj, itemIndex)
            % VALIDATEITEMINDEX Ensure the given index is in the valid range
            validIndex = itemIndex;
            if isempty(itemIndex)
                validIndex = -1;
            elseif isnumeric(itemIndex) && ...
                    itemIndex > length(obj.Model.Items)
                % The previously selected index is greater than the number
                % of items currently in the dropdown.  This can happen, for
                % example, as variables are cleared.  In this case, reset
                % the previous index.
                validIndex = -1;
            end
        end
    end
end

