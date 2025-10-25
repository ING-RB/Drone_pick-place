classdef (Sealed, ConstructOnLoad=true) EditField < ...
        matlab.ui.control.internal.model.ComponentModel & ...        
        matlab.ui.control.internal.model.mixin.EditableComponent & ...
        matlab.ui.control.internal.model.mixin.HorizontallyAlignableComponent & ...
        matlab.ui.control.internal.model.mixin.FontStyledComponent & ...
        matlab.ui.control.internal.model.mixin.BackgroundColorableComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent & ...
        matlab.ui.control.internal.model.mixin.PlaceholderComponent & ...
        matlab.ui.control.internal.model.mixin.Layoutable & ...     
        matlab.ui.control.internal.model.mixin.FocusableComponent
    %

    % Do not remove above white space
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        
        Value = '';

        CharacterLimits = [0 Inf];

        InputType = 'text';

    end
    
    properties(NonCopyable, Dependent, AbortSet)
                
        ValueChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
        
        ValueChangingFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end

    properties(Dependent, AbortSet, Hidden)

    end
    
    properties(Access = {?appdesservices.internal.interfaces.model.AbstractModel})
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        
        PrivateValue = '';

        PrivateCharacterLimits = [0 Inf];

        PrivateInputType = 'text';

    end
    
    properties(NonCopyable, Access = 'private')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set        
        
        PrivateValueChangedFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
        
        PrivateValueChangingFcn matlab.internal.datatype.matlab.graphics.datatype.Callback = [];
    end
    
    events(NotifyAccess = {?appdesservices.internal.interfaces.model.AbstractModel})        
        ValueChanged
        
        ValueChanging
    end
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = EditField(varargin)
            %

            % Do not remove above white space
            % Defaults
            defaultSize = [100, 22];
			obj.PrivateInnerPosition(3:4) = defaultSize;
			obj.PrivateOuterPosition(3:4) = defaultSize;
            obj.Type = 'uieditfield';
            
            parsePVPairs(obj,  varargin{:});
            
            % Wire callbacks
            obj.attachCallbackToEvent('ValueChanged', 'PrivateValueChangedFcn');
            obj.attachCallbackToEvent('ValueChanging', 'PrivateValueChangingFcn');
        end
        % ----------------------------------------------------------------------
        
        function set.Value(obj, newValue)
            % Error Checking
            try
                newValue = matlab.ui.control.internal.model.PropertyHandling.validateText(newValue);
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidTextValue', ...
                    'Value');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidText';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Check if the value is within the length limits
            if (~obj.isValueWithinLimits(newValue))
                messageObj = message('MATLAB:ui:components:valueLengthNotInRange', ...
                    'Value', 'CharacterLimits');
                
                % MnemonicField is last section of error id
                mnemonicField = 'valueLengthNotInRange';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
            end

            % Check if the value is valid according to InputType
            if ~obj.isValueValidBasedOnInputType(newValue)
                messageObj = message('MATLAB:ui:components:invalidValueText', ...
                    'Value', 'InputType');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidValueText';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
            end
            
            % Property Setting
            obj.PrivateValue = newValue;
            
            % Update View
            markPropertiesDirty(obj, {'Value'});
        end
        
        function value = get.Value(obj)
            value = obj.PrivateValue;
        end
        
        % ----------------------------------------------------------------------

        function set.CharacterLimits(obj, newValue)
            try
                % Ensure the input is a 2-element double vector with increasing
                % values
                validateattributes(newValue, ...
                    {'numeric'}, ...
                    {'vector', 'nondecreasing', 'real', 'nonnan','>=', 0, 'numel', 2});
    
                % Ensure that there is at most one infinite value and that
                % the non-infinite values are integers
                validateattributes(newValue(~isinf(newValue)), ...
                    {'numeric'}, ...
                    {'integer', 'nonempty'});
                
                % Reshape to row
                newValue = matlab.ui.control.internal.model.PropertyHandling.getOrientedVectorArray(newValue, 'horizontal');

            catch ME
                messageObj = message('MATLAB:ui:components:invalidCharacterLimits', ...
                    'CharacterLimits');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidCharacterLimits';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
                
            end
            
            % Property Setting
            obj.PrivateCharacterLimits = newValue;
            
            % Update Value if it is no longer valid
            % If Value is already empty, it does not change and should not
            % be marked dirty
            if ~obj.isValueWithinLimits(obj.Value) && strlength(obj.PrivateValue) ~= 0
                obj.PrivateValue = '';
                % Dirty
                obj.markPropertiesDirty({'CharacterLimits', 'Value'});
            else
                % Dirty
                obj.markPropertiesDirty({'CharacterLimits'});
            end
        end
        
        function value = get.CharacterLimits(obj)
            value = obj.PrivateCharacterLimits;
        end

        % ----------------------------------------------------------------------
        function set.InputType(obj, newValue)
            % Error checking
            try
                newValue = validatestring(newValue, ...
                    {'text', 'letters', 'digits', 'alphanumerics'});
            catch ME
                messageObj = message('MATLAB:ui:components:invalidFourStringEnum', ...
                    'InputType','text','letters','digits','alphanumerics');
                
                % MnemonicField is last section of error id
                mnemonicField = 'invalidFourStringEnum';
                
                % Use string from object
                messageText = getString(messageObj);
                
                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
            end

            % Property Setting
            obj.PrivateInputType = newValue;

            % Update Value if it is no longer valid
            if ~obj.isValueValidBasedOnInputType(obj.Value)
                obj.PrivateValue = '';
                % Dirty
                obj.markPropertiesDirty({'InputType', 'Value'});
            else
                % Dirty
                obj.markPropertiesDirty({'InputType'});
            end

        end

        function value = get.InputType(obj)
            value = obj.PrivateInputType;
        end

        % ----------------------------------------------------------------------        
        function set.ValueChangedFcn(obj, newValue)
            % Property Setting            
            obj.PrivateValueChangedFcn = newValue;
            
            % Dirty
            obj.markPropertiesDirty({'ValueChangedFcn'});
        end
        
        function value = get.ValueChangedFcn(obj)
            value = obj.PrivateValueChangedFcn;
        end
        
        % ----------------------------------------------------------------------
        
        function set.ValueChangingFcn(obj, newValue)
            % Property Setting            
            obj.PrivateValueChangingFcn = newValue;
            
            % Dirty
            obj.markPropertiesDirty({'ValueChangingFcn'});
        end
        
        function value = get.ValueChangingFcn(obj)
            value = obj.PrivateValueChangingFcn;
        end
        
    end
   
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)
        
        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            names = {'Value',...
                ...Callbacks
                'ValueChangedFcn', ...
                'ValueChangingFcn'};
                
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = obj.Value;
        
        end
    end


    methods(Access = private)
        function valueWithinLimits = isValueWithinLimits(obj,value)
            % ISVALUEWITHINLIMITS Return whether Value is within the limits
            % defined by CharacterLimits.

            valueWithinLimits = strlength(value) >= obj.PrivateCharacterLimits(1) && ...
                    strlength(value) <= obj.PrivateCharacterLimits(2);
        end

        function valueValid = isValueValidBasedOnInputType(obj, value)
            % ISVALUEVALIDBASEDONINPUTTYPE Return whether Value is valid based
            % on the constraints specified by InputType

            % Empty text is valid for all input types
            if strlength(value) == 0
                valueValid = true;
                return
            end

            % Check that the value matches the specified pattern
            switch obj.PrivateInputType
                case 'text'
                    valueValid = true;
                case 'letters'
                    p = lettersPattern;
                    valueValid = matches(value, p);
                case 'digits'
                    p = digitsPattern;
                    valueValid = matches(value, p);
                case 'alphanumerics'
                    p = alphanumericsPattern;
                    valueValid = matches(value, p);
            end
        end
    end
    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 

           % sObj is the serialization content for obj 
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj, obj);
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableComponent(sObj);
        end 

    end
end

