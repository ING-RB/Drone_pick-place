classdef (Hidden) AbstractGaugeComponent < ...
        matlab.ui.control.internal.model.ComponentModel & ...
        matlab.ui.control.internal.model.mixin.EnableableComponent & ...
        matlab.ui.control.internal.model.mixin.VisibleComponent & ...
        matlab.ui.control.internal.model.mixin.TooltipComponent & ...
        matlab.ui.control.internal.model.mixin.PositionableComponent & ...
        matlab.ui.control.internal.model.mixin.BackgroundColorableComponent & ...
        matlab.ui.control.internal.model.mixin.ScaleColorsComponent & ...
        matlab.ui.control.internal.model.mixin.TickComponent & ...
        matlab.ui.control.internal.model.mixin.LimitsComponent


    % This undocumented class may be removed in a future release.

    % This is the parent class for all gauge components.
    %
    % It provides all properties specific to gauges.

    % Copyright 2011-2021 The MathWorks, Inc.

    properties(Dependent, AbortSet)
        Value = 0;
    end


    properties(Access = 'protected')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, beacuse sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateValue = 0;

    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = AbstractGaugeComponent(varargin)

            % Super
            obj = obj@matlab.ui.control.internal.model.mixin.TickComponent(varargin{:});

        end
    end

    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.Value(obj, newValue)
            % Error Checking
            try
                validateattributes(newValue, ...
                    {'numeric'}, ...
                    {'scalar', 'finite', 'nonempty', 'real'});

                % convert any non-double to a double
                finalValue = double(newValue);
            catch ME
                messageObj = message('MATLAB:ui:components:invalidValue', ...
                    'Value');

                % MnemonicField is last section of error id
                mnemonicField = 'invalidValue';

                % Use string from object
                messageText = getString(messageObj);

                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
            end

            % Property Setting
            obj.PrivateValue = finalValue;

            obj.markPropertiesDirty({'Value'});
        end

        function value = get.Value(obj)
            value = obj.PrivateValue;
        end
    end

    methods(Access = 'protected')

        function updatedProperties = updatePropertiesAfterLimitsChange(obj)
            %Update the Scale Color Limits
            updatedProperties = updatePropertiesAfterLimitsChange@matlab.ui.control.internal.model.mixin.ScaleColorsComponent(obj);

        end
    end
end
