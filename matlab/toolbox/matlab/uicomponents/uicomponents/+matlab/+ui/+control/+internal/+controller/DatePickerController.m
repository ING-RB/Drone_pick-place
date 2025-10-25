classdef (Hidden) DatePickerController < matlab.ui.control.internal.controller.ComponentController
    % DatePickerController class is the controller class for the DatePicker
    
    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties (Constant, Access = private)
        CachedDateObject = datetime('now');
    end
    
    methods
        function obj = DatePickerController(varargin)
            obj@matlab.ui.control.internal.controller.ComponentController(varargin{:});
        end
    end
    
    methods(Access = 'protected')
        
        function propertyNames = getAdditionalPropertyNamesForView(obj)
            % Get additional properties to be sent to the view
            
            propertyNames = getAdditionalPropertyNamesForView@matlab.ui.control.internal.controller.ComponentController(obj);
            
            % Non - public properties that need to be sent to the view
            propertyNames = [propertyNames; {...
                'ViewLanguage';...
                'InputFormat';...
                }];
        end
        
        function viewPvPairs = getPropertiesForView(obj, propertyNames)
            % GETPROPERTIESFORVIEW(OBJ, PROPERTYNAME) returns view-specific
            % properties, given the PROPERTYNAMES
            %
            % Inputs:
            %
            %   propertyNames - list of properties that changed in the
            %                   component model.
            %
            % Outputs:
            %
            %   viewPvPairs   - list of {name, value, name, value} pairs
            %                   that should be given to the view.
            import appdesservices.internal.util.ismemberForStringArrays;
            viewPvPairs = {};
            
            % Properties from Super
            viewPvPairs = [viewPvPairs, ...
                getPropertiesForView@matlab.ui.control.internal.controller.ComponentController(obj, propertyNames), ...
                ];

            checkFor = ["Value", "ViewLanguage", "DisplayFormat"];
            isPresent = ismemberForStringArrays(checkFor, propertyNames);
            
            % Handle Value/ViewLanguage
            if isPresent(1) && isPresent(2)
                
                viewPvPairs = [viewPvPairs, ...
                    {'ViewLanguage',  obj.getViewLanguage()} ...
                    ];
            end
            
            if isPresent(3)
                % Limits must be of size 1x2
                viewPvPairs = [viewPvPairs, ...
                    {'InputFormat',  obj.getInputFormatForView(obj.Model.DisplayFormat)} ...
                    ];
            end
        end
        
        function handleEvent(obj, src, event)
            % Allow super classes to handle their events
            handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);
            
            if(strcmp(event.Data.Name, 'ValueChanged'))
                % Handles when the user commits new text in the ui
                % Emit both 'ValueChanged' and 'ValueChanging' events
                
                % Get the previous value
                previousValue = obj.Model.Value;
                
                newValue = obj.convertNaTStr(event.Data.Value);
                newValue.Format = obj.Model.DisplayFormat;
                % Create event data for 'ValueChanged'
                valueChangedEventData = matlab.ui.eventdata.ValueChangedData(newValue, previousValue);
                
                % Update the model and emit both 'ValueChanged' and
                % 'ValueChanging' which will in turn trigger the callbacks
                obj.handleUserInteraction('ValueChanged', event.Data, ...
                    {'ValueChanged', valueChangedEventData, 'PrivateValue', newValue});
                
            end
        end

        function handlePropertiesChanged(obj, changedPropertiesStruct)
            if isfield(changedPropertiesStruct, 'Value')
                changedPropertiesStruct.Value = obj.convertNaTStr(changedPropertiesStruct.Value);
            end
            handlePropertiesChanged@matlab.ui.control.internal.controller.ComponentController(obj, changedPropertiesStruct);
        end
    end
        
    methods(Static)
        function inputFormat = getInputFormatForView(displayFormat)
            % GETINPUTFORMATFORVIEW - Compute the format the end user will use when
            % entering dates in the edit field
            % displayFormat - format the end user has chosen for the uidatepicker
            % dateObject - sample date object provided so a new one does not need to be
            %              created
            
            s = settings;
            defaultFormat = matlab.internal.datetime.filterTimeIdentifiers(...
                s.matlab.datetime.DefaultDateFormat.FactoryValue);
            
            dateObject = matlab.ui.control.internal.controller.DatePickerController.CachedDateObject;
            % if the format is the factory default or all numeric, use that
            if isNumericOnly(displayFormat, dateObject)
                
                % Display Format is all numeric
                inputFormat = displayFormat;
            else
                
                % Display Format has alpha representation of month or day
                % Use Localized numeric representation of component
                if isNumericOnly(defaultFormat, dateObject)
                    inputFormat = defaultFormat;
                else
                    % Since CJK is numeric, if the default is not numeric, the default
                    % is US (dd-MMM-uuuu)
                    inputFormat = 'MM/dd/uuuu';
                end
            end
            
        end 
        
        function viewLanguage = getViewLanguage()
            % GETVIEWLANGUAGE - retrieve the view language used in the calendar            
            s = settings;
            viewLanguage = s.matlab.datetime.DisplayLocale.ActiveValue;
        end

        function outValue = convertNaTStr(inValue)
            % Convert string "NaT" to NaT datetime object or just pass the value through.
            if strcmp(inValue, 'NaT')
                outValue = NaT;
            else
                outValue = inValue;
            end
        end
    end
end


function isNumericOnly = isNumericOnly(format, dateObject)
            % ISNUMERICONLY - returns true if the format is rendered without day or
            % month names in localized text
            % format - format the end user has chosen for the uidatepicker
            % dateObject - sample date object provided so a new one does not need to be
            %              created
            
            dateObject.Format = format;
            if isempty(regexprep(char(dateObject), '[\W\d]', ''))
                isNumericOnly = true;
            else
                isNumericOnly = false;
            end
            
        end
