classdef (Hidden) StateComponentSelectionStrategy < handle
    % StateComponentSelectionStrategy
    % Abstract class for selection strategy of state components, e.g.
    % listbox, discrete knob
    
    % Copyright 2015-2024 The MathWorks, Inc.
    
    properties(Access = 'protected', WeakHandle)
        Component handle = matlab.ui.control.internal.model.AbstractStateComponent.empty();
    end
        
    methods
        function obj = StateComponentSelectionStrategy(stateComponentInstance)
            obj.Component = stateComponentInstance;
        end
    end
    
    methods(Abstract, ...
            Access = {  ?matlab.ui.control.internal.model.StateComponentSelectionStrategy, ...
                        ?matlab.ui.control.internal.model.StateComponentValueStrategy, ...
                        ?matlab.ui.control.internal.model.AbstractStateComponent})
        
        % Updates the selected index after the strategy has been 
        % changed to this strategy
        calibrateSelectedIndexAfterSelectionStrategyChange(obj)
        
        % Updates the selected index as a result of ItemsData being set
        % to some non-empty value (while it was empty before)
        calibrateSelectedIndexAfterSwitchToDataSpace(obj)
        
        % Updates the selected index as a result of Items being changed. 
        % This method assumes we were and still are in the text space, i.e. 
        % ItemsData was and is still empty
        calibrateSelectedIndexInTextSpace(obj, currentSelectedText)
        
        % Updates the selected index as a result of Items or ItemsData
        % being changed. This method assumes we were and still are in the 
        % data space, i.e. ItemsData was and is still not empty.
        calibrateSelectedIndexInDataSpace(obj, currentSelectedData)
        
        
        % Validate that Value is an element of Items
        newValue = validateValuePresentInItems(obj, newValue)
        
        % Validate that Value is an element of ItemsData
        newValueData = validateValuePresentInItemsData(obj, newValueData)
        
        % Validator for the Value property        
        value = validateValueIndex(obj, newValue)
        
        % Returns the selected text given the selected index
        value = getSelectedTextGivenIndex(obj, index)
        
         % Returns the selected data given the selected index
        value = getSelectedDataGivenIndex(obj, index)

        % Returns the selected index given the selected text 
        index = getIndexGivenSelectedText(obj, value)
        
        % Returns the selected index given the selected data 
        index = getIndexGivenSelectedData(obj, valueData)

        % Returns the value index given the selected index 
        index = getValueIndexGivenSelectedIndex(obj, index)
        
    end
    
end

