classdef (Hidden) StateComponentValueStrategy < handle
    % StateComponentValueStrategy
    % Abstract class for value strategy of state components, e.g.
    % listbox, discrete knob, dropdown
    
    % Copyright 2015-2024 The MathWorks, Inc.
    
    properties(Access = 'protected', WeakHandle)
        Component handle = matlab.ui.control.internal.model.AbstractStateComponent.empty();
    end
        
    methods
        function obj = StateComponentValueStrategy(stateComponentInstance)
            obj.Component = stateComponentInstance;
        end
    end
    
    methods(Abstract, ...
            Access = {  ?matlab.ui.control.internal.model.StateComponentValueStrategy, ...
                        ?matlab.ui.control.internal.model.AbstractStateComponent})
        
        % Update selected index after the value strategy got changed to
        % this one such that the selected index remains valid
        calibrateSelectedIndexAfterValueStrategyChange(obj)
        
        % Update selected index after Items or ItemsData was changed.
        % This method assumes that there was no change in Value Strategy. 
        calibrateSelectedIndex(obj, currentValue)
        
        % Validator for the Value property        
        value = validateValue(obj, newValue)
        
        % Returns the selected index given the Value
        index = getIndexGivenValue(obj, value)
        
        % Returns the Value given the selected index
        value = getValueGivenIndex(obj, index) 
    end
    
end

