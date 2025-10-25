classdef (Hidden) EditFieldController < matlab.ui.control.internal.controller.ComponentController
    % EditFieldController class is the controller class for the EditField
    
    % Copyright 2016 The MathWorks, Inc.
    
    methods
        function obj = EditFieldController(varargin)                      
            obj@matlab.ui.control.internal.controller.ComponentController(varargin{:});

              obj.NumericProperties{end+1} = 'CharacterLimits';
        end
    end    
    
    methods(Access = 'protected')

        function changedPropertiesStruct = handlePropertiesChanged(obj, changedPropertiesStruct)
            if(any(strcmp('CharacterLimits', fieldnames(changedPropertiesStruct))))
                % If the upper limit is Inf, this comes in as a cell array
                % {min, 'Inf'}. Coerce the limits to [min Inf].
                limits = changedPropertiesStruct.CharacterLimits;
                if(iscell(limits))
                    min = limits{1};
                    max = convertClientNumbertoServerNumber(obj, limits{2});
                    newValue = [min max];

                    % Apply to the model
                    obj.Model.CharacterLimits = newValue;
                
                    % Remove the field from the struct since it has
                    % been handled already
                    changedPropertiesStruct = rmfield(changedPropertiesStruct, 'CharacterLimits');
                end  
            end
            
            % Call the superclasses for unhandled properties
            handlePropertiesChanged@matlab.ui.control.internal.controller.ComponentController(obj, changedPropertiesStruct);
        end
        
        function handleEvent(obj, src, event)
            % Allow super classes to handle their events
            handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);
            
            if(strcmp(event.Data.Name, 'ValueChanged'))
                % Handles when the user commits new text in the ui
                % Emit both 'ValueChanged' and 'ValueChanging' events
                
                % Get the previous value
                previousValue = obj.Model.Value;
                
                % Get the new value
                newValue = event.Data.Value;
                
                % Create event data for 'ValueChanged'
                valueChangedEventData = matlab.ui.eventdata.ValueChangedData(newValue, previousValue);
                
                % Update the model and emit both 'ValueChanged' and
                % 'ValueChanging' which will in turn trigger the callbacks
                obj.handleUserInteraction('ValueChanged', event.Data, ...
                    {'ValueChanged', valueChangedEventData, 'PrivateValue', newValue});                
            
            elseif (strcmp(event.Data.Name, 'ValueChanging'))
                % Handles when the user is editing the edit field
                
                newValue = event.Data.Value;
                
                % Create event data for 'ValueChanging'
                valueChangingEventData = matlab.ui.eventdata.ValueChangingData(newValue);

                % Emit 'ValueChanging' which will in turn trigger
                % ValueChangingFcn
                obj.handleUserInteraction('ValueChanging', event.Data, {'ValueChanging', valueChangingEventData});

            elseif (strcmp(event.Data.Name, 'ValueReverted'))
                % The value has changed, so execute a final ValueChangedFcn

                newValue = event.Data.Value;

                % Create event data for 'ValueChanging'
                valueChangingEventData = matlab.ui.eventdata.ValueChangingData(newValue);

                % Emit 'ValueChanging' which will in turn trigger
                % ValueChangingFcn
                obj.handleUserInteraction('ValueChanging', event.Data, {'ValueChanging', valueChangingEventData});
            end
        end
    end
    
    
end