classdef (Hidden) LimitedRangeValueComponent < ...
        matlab.ui.control.internal.model.AbstractLimitedValueComponent

    properties(Dependent, AbortSet)
        Value = [0 100];
    end

    properties(Access = {?matlab.ui.control.internal.model.LimitedValueComponent, ...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.controller.AbstractController})
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateValue = [0 100];
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = LimitedRangeValueComponent(varargin)
            obj@matlab.ui.control.internal.model.AbstractLimitedValueComponent(varargin{:});
        end
    end

    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.Value(obj, newValue)
            % Error Checking
            try
                % Ensure that Value is between Limits
                lowerLimit = obj.PrivateLimits(1);
                upperLimit = obj.PrivateLimits(2);

                validateattributes(newValue, ...
                    {'double'}, ...
                    {'real', 'finite', 'nonempty', 'nondecreasing' ...
                    'size', [1 2],...
                    '>=', lowerLimit, ...
                    '<=', upperLimit});

            catch ME
                messageObj = message('MATLAB:ui:components:invalidRangeValue', ...
                    'Value', 'Limits');

                % MnemonicField is last section of error id
                mnemonicField = 'invalidValue';

                % Use string from object
                messageText = getString(messageObj);

                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);
            end

            % Property Setting
            obj.PrivateValue = newValue;

            obj.markPropertiesDirty({'Value'});
        end

        function value = get.Value(obj)
            value = obj.PrivateValue;
        end
    end

    methods (Access = protected)

        function updatedProperties = updatePropertiesAfterLimitsChange(obj)
            %Ensure value is within the new limits
            obj.PrivateValue(1) = matlab.ui.control.internal.model.PropertyHandling.calibrateValue(obj.PrivateLimits, obj.PrivateValue(1));
            obj.PrivateValue(2) = matlab.ui.control.internal.model.PropertyHandling.calibrateValue(obj.PrivateLimits, obj.PrivateValue(2));
            updatedProperties = {'Value'};
        end

    end
end