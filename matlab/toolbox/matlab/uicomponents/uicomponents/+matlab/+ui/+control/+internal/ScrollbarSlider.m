classdef (Hidden, Sealed, ConstructOnLoad=true) ScrollbarSlider < ...
        matlab.ui.control.internal.model.LimitedValueComponent & ...
        matlab.ui.control.internal.model.mixin.BackgroundColorableWithNoneComponent & ...
        matlab.ui.control.internal.model.mixin.OrientableComponent & ...
        matlab.ui.control.internal.model.mixin.LimitsComponent & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer
    % This undocumented class may be removed in a future release.

    % This is an internal scrollbar component which is used by the
    % UIControl Redirect to render the Slider style.
    % Copyright 2023 The MathWorks, Inc.

    properties (Dependent, AbortSet)
        Step = [0.01 0.1]
    end

    properties (Access = private)
        PrivateStep = [0.01 0.1]
    end

    properties (Access = protected, Constant)
        % Implement abstract properties
        ValidOrientations cell = {'horizontal', 'vertical'};
    end

    methods
        function obj = ScrollbarSlider(varargin)
            % Orientation default
            obj.PrivateOrientation = 'horizontal';

            obj.Type = 'uiscrollbarslider';

            % Mark as not serializable because
            % - component is internal and not customer-visible
            % - currently, component is only used in the UIControl Redirect
            % which does not need to save its backing component
            obj.Serializable = 'off';

            parsePVPairs(obj, varargin{:});
        end
    end

    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods

        % -----------------------------------------------------------------
        % Getter/setter for Step
        % -----------------------------------------------------------------
        function set.Step(obj, newStep)
            % Error Checking
            % Step must be:
            % numeric
            % >= 1e-6
            % <= 1
            % 1x2 vector
            % step(1) <= step(2)
            % nonsparse
            %
            % These rules are identical to the validation for the UIControl
            % SliderStep property and datatype.

            try
                validateattributes(newStep, ...
                    {'numeric'}, ...
                    {'size', [1, 2], ...
                    'nondecreasing', ...
                    'nonsparse', ...
                    '>=', 1e-6, ...
                    '<=', 1});
            catch ME
                messageObj = message('MATLAB:ui:components:invalidStepDataType', ...
                    'Step');

                % MnemonicField is last section of error id
                mnemonicField = 'invalidStep';

                messageText = getString(messageObj);

                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
            end
            
            obj.PrivateStep = newStep;

            obj.markPropertiesDirty({'Step'});
        end

        function step = get.Step(obj)
            step = obj.PrivateStep;
        end
    end

    methods (Access = protected)

        function dirtyProperties = updatePropertiesAfterOrientationChanges(obj, oldOrientation, newOrientation)
            obj.updatePositionPropertiesAfterOrientationChange(oldOrientation, newOrientation);

            % Push to view values that are certain
            % Do not push estimated OuterPosition to the view
            dirtyProperties = {
                'InnerPosition' ...
                };
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
            
            names = {'Value', ...
                'Limits', ...
                'Step', ...
                'Orientation', ...
                ...Callbacks
                'ValueChangedFcn', ...
                'ValueChangingFcn' ...
                }; 
        end
        
        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = obj.Type;
        end
    end
    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 

           % sObj is the serialization content for obj 
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableWithNoneComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.BackgroundColorableWithNoneComponent(sObj);
        end 

    end 
end