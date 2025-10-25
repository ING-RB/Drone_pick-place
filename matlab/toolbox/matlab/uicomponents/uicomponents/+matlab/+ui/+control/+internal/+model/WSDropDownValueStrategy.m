classdef WSDropDownValueStrategy < matlab.ui.control.internal.model.SelectedTextValueStrategy

    % Selection Value Strategy for the Workspace Dropdown.  Needed to handle
    % cases where the variable may not exist, but can still be set as the value.

    % Copyright 2024 The MathWorks, Inc.

    methods(Access = {?matlab.ui.control.internal.model.StateComponentValueStrategy, ...
            ?matlab.ui.control.internal.model.AbstractStateComponent})

        function value = validateValue(obj, newValue)
            obj.Component.handleNonExistentVariables(newValue);

            value = obj.Component.SelectionStrategy.validateValuePresentInItems(newValue);
        end
    end
end
