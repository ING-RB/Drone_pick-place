classdef (Hidden) SpinnerController < ...
        matlab.ui.control.internal.controller.NumberFieldController
    
    % SpinnerController class is the controller class for
    % matlab.ui.control.Spinner object.
    
    % Copyright 2015-2020 The MathWorks, Inc.
    
    methods
        function obj = SpinnerController(varargin)
            obj@matlab.ui.control.internal.controller.NumberFieldController(varargin{:});
        end
    end
    
    
    methods(Access = 'protected')
        
        function handleEvent(obj, src, event)
            
            if(strcmp(event.Data.Name, 'PropertyEditorEdited'))
                 propertyName = event.Data.PropertyName;
                 propertyValue = event.Data.PropertyValue;
                                
                if(strcmp(propertyName, 'Step'))                                                                        
                                                                    
                        if(isempty(propertyValue))
                            % Coerce '' to 1
                            propertyValue = 1;
                        else
                            propertyValue = convertClientNumbertoServerNumber(obj, propertyValue);
                        end
                         % Update the event data in line
                         setModelProperty(obj, ...
                             propertyName, ...
                             propertyValue, ...
                             event ...
                             );
                else                   
                    handleEvent@matlab.ui.control.internal.controller.NumberFieldController(obj, src, event);
                end
            end
            
            handleEvent@matlab.ui.control.internal.controller.NumberFieldController(obj, src, event);            
            if(strcmp(event.Data.Name, 'ValueChanging'))
                % Handles when the user keeps the Up/Down buttons pressed                
                newValue = obj.convertClientNumbertoServerNumber(event.Data.Value);
                
                % Create event data
                eventData = matlab.ui.eventdata.ValueChangingData(newValue);

                % No model update needed, just emit 'ValueChanging' which in turn will 
                % trigger the user callback
                obj.handleUserInteraction('ValueChanging', event.Data, {'ValueChanging', eventData});                      
            end
            
            
        end
        
    end
end
