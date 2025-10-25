classdef (Hidden) LimitedValueComponent < ...
        matlab.ui.control.internal.model.AbstractLimitedValueComponent

    properties(Dependent, AbortSet)
        Value = 0;
    end

    properties(Access = {...
             ?appdesservices.internal.interfaces.model.AbstractModel, ...
             ?appdesservices.internal.interfaces.controller.AbstractController})
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateValue = 0;
    end

    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = LimitedValueComponent(varargin)
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
                    {'scalar', 'real', 'finite', 'nonempty', ...
                    '>=', lowerLimit, ...
                    '<=', upperLimit});

            catch ME
                messageObj = message('MATLAB:ui:components:valueNotInRange', ...
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
            obj.PrivateValue = matlab.ui.control.internal.model.PropertyHandling.calibrateValue(obj.PrivateLimits, obj.PrivateValue);
            updatedProperties = {'Value'};
        end

    end
end
