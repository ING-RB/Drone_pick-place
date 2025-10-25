classdef (Hidden) AbstractProgressIndicator < ...
        matlab.ui.control.internal.model.ComponentModel & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent  & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...
        matlab.ui.control.internal.model.mixin.NonserializableComponent
    %

    % Do not remove above space
    % Copyright 2019-2024 The MathWorks, Inc.
    
    properties(AbortSet, Dependent)
        Value = 0;
        Indeterminate matlab.internal.datatype.matlab.graphics.datatype.on_off = 'off';
    end
    properties(Dependent)
        ProgressColor matlab.internal.datatype.matlab.graphics.datatype.RGBColor = '#268CDD';
    end
    
    properties(Access = 'protected')
        PrivateValue = 0;
        PrivateIndeterminate matlab.internal.datatype.matlab.graphics.datatype.on_off = 'off';
    end
    properties(AbortSet, Hidden)
        ProgressColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBColor = '#268CDD';
        ProgressColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
    end
    methods
        
        function set.Value (obj, val)
            % Error Checking
            try
                % Ensure that Value is between Limits
                lowerLimit = 0;
                upperLimit = 1;
                
                validateattributes(val, ...
                    {'double'}, ...
                    {'scalar', 'finite', 'real', 'nonempty', ...
                    '>=', lowerLimit, ...
                    '<=', upperLimit});
                
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:valueNotInRange', ...
                    'Value', '[0, 1]');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidValue';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateValue = val;
            
            obj.markPropertiesDirty({'Value'});
        end

        function value = get.Value(obj)
            value = obj.PrivateValue;
        end
        
        function set.Indeterminate(obj, val)
            obj.PrivateIndeterminate = val;
            obj.markPropertiesDirty({'Indeterminate'});
        end

        function value = get.Indeterminate(obj)
            value = obj.PrivateIndeterminate;
        end
        
        function set.ProgressColor (obj, val)

            % Update Model
            obj.ProgressColorMode = 'manual';
            obj.ProgressColor_I = val;
        end

        function set.ProgressColor_I(obj, val)

            % Update Model
            obj.ProgressColor_I = val;

            % Update View
            obj.markPropertiesDirty({'ProgressColor'});
        end
        function value = get.ProgressColor(obj)
            value = obj.ProgressColor_I;
        end
        function set.ProgressColorMode(obj, modeValue)
            % Update Model
            obj.ProgressColorMode = modeValue;
            if modeValue == "auto"
                matlab.graphics.internal.themes.refreshThemedValue(obj, 'ProgressColor')
            end
        end
    end
    methods (Static, Access = protected)
        function tmap = getThemeMap()
            tmap = struct(...
                'ProgressColor','--mw-backgroundColor-primary-info');
        end
    end
end
