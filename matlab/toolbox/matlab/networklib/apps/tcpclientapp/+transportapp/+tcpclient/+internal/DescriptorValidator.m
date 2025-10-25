classdef DescriptorValidator < handle
    %DESCRIPTORVALIDATOR class validates and sets tcpclient app properties
    % like Port and ConnectTimeout before user clicks on "Confirm"

    % Copyright 2021 The MathWorks, Inc.

    %% Private Constructor
    methods (Access = private)
        function obj = DescriptorValidator()
        end
    end

    %% Validation functions
    methods (Static)
        function vals = isFieldEmpty(paramMap)
            % Check whether all Configuration Tab fields are non-empty.
            vals = false;

            % Get all configuration tab properties
            keys = paramMap.keys;
            for key = string(keys)
                % Check whether the Configuration tab property is
                % non-empty.
                if isKey(paramMap, key) && isempty(paramMap(key).NewValue)
                    vals = true;
                    return
                end
            end
        end

        function [value, ex] = validateTextFieldValue(paramMap, fieldName, errorID, defaultValue)
            % Helper function to validate any entries made to the Text
            % Fields in the Configuration Tab.

            % Error exception if any
            ex = [];

            % Save the new value if the key exists
            if isKey(paramMap, fieldName)
                value = paramMap(fieldName).NewValue;
            else
                return
            end

            % Check if the value is not empty.
            if isempty(value)
                % Get either the OldValue if valid, or, the default value
                % if OldValue is also empty.
                value = transportapp.tcpclient.internal.DescriptorValidator.getValueForEmptyNewValue(paramMap(fieldName), defaultValue);
                return
            end

            % Address will only be validated when the "Confirm" button is clicked.
            if fieldName == "Address"
                return
            else
                [value, ex] = transportapp.tcpclient.internal.DescriptorValidator.validatePortAndConnectTimeout(paramMap, fieldName, errorID, value, ex);
            end
        end
    end

    %% Helper functions
    methods (Access = private, Static)
        function value = getValueForEmptyNewValue(map, defaultValue)
            % For the paramMap NewValue empty, return the appropriate
            % replacement value, either the paramMap OldValue, or the
            % default value for a field.
            value = map.OldValue;

            if isempty(value)
                % If the OldValue was also empty, set value to the default
                % value.
                value = defaultValue;
            end
            value = num2str(value);
        end

        function [value, ex] = validatePortAndConnectTimeout(paramMap, fieldName, errorID, value, ex)
            % Helper function to validate any entries made to the Port and
            % Connect Timeout Text Fields in the Configuration Tab. It
            % validates the entries, throws an error in case of an invalid
            % entry, and resets the Text Field Value to the last valid value.

            try
                % Try to convert to a double from a char array.
                value = str2double(value);
                % If the double conversion failed, the value is nan.
                % This means that the entered value by the user was not
                % valid. Throw an error.

                if fieldName == "Port"
                    validateattributes(value, "numeric", {">=", 1, "<=", 65535, "scalar","integer"}, "", fieldName);
                elseif fieldName == "ConnectTimeout"
                    validateattributes(value, "numeric", {">=", 1, "scalar"}, "", fieldName);
                end

                % The entered value is valid. Update the
                % respective field to the updated value.
                value = paramMap(fieldName).NewValue;
            catch
                % Exception was thrown when a new value was entered.
                % Set the Field Value to the old value and create the error
                % exception to return to the TcpclientDescriptor class.
                % The value should be returned and hence the error is not
                % being thrown from here.
                value = paramMap(fieldName).OldValue;
                ex = MException(message(errorID));
            end
        end
    end
end