classdef (Sealed, ConstructOnLoad=true) Slider < ...
        ... % Shared slider functionality
        matlab.ui.control.internal.model.mixin.SliderComponent & ...
        matlab.ui.control.internal.model.LimitedValueComponent
    %

    % Do not remove above white space
    % Copyright 2013-2024 The MathWorks, Inc.

    properties (Dependent)
        Step double = .1
    end

    properties (Dependent, NeverAmbiguous, AbortSet)
        StepMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end

    properties(Access = {...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.controller.AbstractController})
        PrivateStep double = .1
        PrivateStepMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = Slider(varargin)
            %

            % Do not remove above white space
            obj@matlab.ui.control.internal.model.LimitedValueComponent(varargin{:});
            obj@matlab.ui.control.internal.model.mixin.SliderComponent(varargin{:});
            
            % Position defaults
            locationOffset = [7 30];
            obj.PrivateOuterPosition(1:2) = obj.PrivateInnerPosition(1:2) - locationOffset;
            obj.PrivateOuterPosition(3:4) = [166 39];
            obj.PrivateInnerPosition(3:4) = [150 3];

            obj.HasMargins = true;
            obj.IsSizeFixed = [false true];

            obj.Type = 'uislider';

            parsePVPairs(obj,  varargin{:});
        end
    end

    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function step = get.Step(obj)
            step = obj.PrivateStep;
        end

        function set.Step(obj, step)
            % Type check
            try 
                % step should be a numeric value.
                % NaN, Inf, empty are not accepted
                validateattributes(...
                    step, ...
                    {'double'}, ...
                    {'scalar', 'real', 'nonempty', 'finite', 'nonnan', 'positive'} ...
                );

            catch ME

                messageObj = message('MATLAB:ui:components:invalidStep', ...
                    'Step');

                % MnemonicField is last section of error id
                mnemonicField = 'invalidStep';

                % Use string from object
                messageText = getString(messageObj);

                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);

            end

            obj.PrivateStep = step;

            obj.PrivateStepMode = 'manual';

            % Update View
            obj.markPropertiesDirty({'Step', 'StepMode'});
        end

        function stepMode = get.StepMode(obj)
            stepMode = obj.PrivateStepMode;
        end

        function set.StepMode(obj, newValue)
            % Type check
            try
                newMode = matlab.ui.control.internal.model.PropertyHandling.processMode(obj, newValue);
            catch ME
                messageObj = message('MATLAB:ui:components:invalidTwoStringEnum', ...
                    'StepMode', 'auto', 'manual');

                % MnemonicField is last section of error id
                mnemonicField = 'invalidStepMode';

                % Use string from object
                messageText = getString(messageObj);

                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);

            end

            % Property Setting
            obj.PrivateStepMode = newMode;

            % If StepMode is auto, update the Step property based on the Limits
            if strcmp(newValue, 'auto')
                obj.updateStepFromLimits();
                obj.markPropertiesDirty({'Step', 'StepMode'});
            else
                obj.markPropertiesDirty({'StepMode'});
            end
        end
    end

    methods(Access = protected)
        function updateStepFromLimits(obj)
            if strcmp(obj.StepMode,'auto')
                obj.PrivateStep = (obj.Limits(2) - obj.Limits(1))/1000;
            end
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
                'Limits',...
                'MajorTicks',...
                'MajorTickLabels',...
                'Orientation',...
                ...Callbacks
                'ValueChangedFcn', ...
                'ValueChangingFcn'};

        end

        function str = getComponentDescriptiveLabel(obj)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            str = num2str(obj.Value);

        end

        function dirtyProperties = updatePropertiesAfterOrientationChanges(obj, oldOrientation, newOrientation)
            obj.updatePositionPropertiesAfterOrientationChange(oldOrientation, newOrientation);

            % Push to view values that are certain
            % Do not push estimated OuterPosition to the view
            dirtyProperties = {
                'AspectRatioLimits',...
                'IsSizeFixed',...
                'InnerPosition'...
                };
        end

        function updatedProperties = updatePropertiesAfterLimitsChange(obj)
            % Update Step property based on the limits
            obj.updateStepFromLimits();
            updatedProperties = updatePropertiesAfterLimitsChange@matlab.ui.control.internal.model.LimitedValueComponent(obj);
            updatedProperties = ['Step', updatedProperties];
        end
    end
    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 

           % sObj is the serialization content for obj 
           modifyOutgoingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.control.internal.model.mixin.FontStyledComponent(sObj);
        end 
    end
end