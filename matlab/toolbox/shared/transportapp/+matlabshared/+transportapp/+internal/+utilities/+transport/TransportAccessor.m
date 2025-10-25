classdef TransportAccessor < matlabshared.transportapp.internal.utilities.ITestable

    %TRANSPORTACCESSOR performs getter and setter operations on the
    %transport object.

    % Copyright 2021-2022 The MathWorks, Inc.

    properties(SetAccess = immutable)
        % The handle to the transport.
        Transport

        % The data available property name (NumBytesAvailable or
        % NumDatagramsAvailable).
        DataAvailablePropertyName (1,1) string = "NumBytesAvailable"
    end

    properties
        % Listener for a change in the data available property
        % (NumBytesAvailable or NumDatagramsAvailable).
        DataAvailableListener
    end

    properties (Dependent, GetObservable, SetAccess = private)
        % Placeholder property to get DataAvailablePropertyName
        % (i.e. NumBytesAvailable or NumDatagramsAvailable).
        NumDataAvailable
    end

    properties (SetObservable, SetAccess = private)
        % Placeholder property to set DataAvailablePropertyName
        % (i.e. NumBytesAvailable or NumDatagramsAvailable).
        ObservableDataAvailable
    end

    properties(Dependent)
        Timeout
        ByteOrder
        Terminator
    end

    properties (Constant)
        ByteOrderValues = ["little-endian", "big-endian"]

        % List of the TransportAccessor properties on which the setter can
        % be invoked.
        LocalPropertySetterList (1, :) string = ...
            ["Timeout", "ByteOrder", "Terminator"]
    end

    %% Lifetime
    methods
        function obj = TransportAccessor(varargin)
            narginchk(1,2);
            obj.Transport = varargin{1};
            if nargin == 2
                obj.DataAvailablePropertyName = varargin{2};
            end
        end

        function connect(obj)
            obj.DataAvailableListener = listener(obj, "NumDataAvailable", "PostGet", ...
                @(src, evt)obj.handlePropertyEvents(src, evt));
        end

        function disconnect(obj)
            if isvalid(obj.DataAvailableListener)
                delete(obj.DataAvailableListener);
            end
        end
    end

    %% Getters and Setters for Transport Properties
    methods

        %% Getters
        function val = get.NumDataAvailable(obj)
            val = obj.Transport.(obj.DataAvailablePropertyName);
        end

        function val = get.Timeout(obj)
            val = obj.Transport.Timeout;
        end

        function value = get.ByteOrder(obj)

            value = internal.matlab.editorconverters.datatype.StringEnumeration(...
                obj.Transport.ByteOrder, obj.ByteOrderValues);
        end

        function value = get.Terminator(obj)

            term = obj.Transport.Terminator;
            if iscell(term)
                readTerminator = term{1};
                writeTerminator = term{2};
            else
                readTerminator = term;
                writeTerminator = term;
            end

            if isnumeric(readTerminator)
                readTerminator = string(readTerminator);
            end

            if isnumeric(writeTerminator)
                writeTerminator = string(writeTerminator);
            end

            value = obj.getTerminatorClassHook(readTerminator, writeTerminator);
        end

        %% Setters
        function set.Timeout(obj, val)
            obj.Transport.Timeout = val;
        end

        function set.ByteOrder(obj, value)
            if isa(value, "internal.matlab.editorconverters.datatype.StringEnumeration")
                val = value.Value;
            else
                val = value;
            end
            obj.Transport.ByteOrder = val;
        end

        function set.Terminator(obj, value)
            % Set the internal transport's terminator property.

            if isa(value, "matlabshared.transportapp.internal.utilities.transport.TerminatorClass")
                configureTerminator(obj.Transport, translateTerminator(obj, value.ReadTerminator.Value), ...
                    translateTerminator(obj, value.WriteTerminator.Value));
            elseif iscell(value)
                cellTerminatorValueSet(obj, value);
            else
                numericTerminatorValueSet(obj, value);
            end

            function cellTerminatorValueSet(obj, value)
                % If the terminator values are of type cell

                if isscalar(value)
                    configureTerminator(obj.Transport, translateTerminator(obj, value{1}));
                else
                    configureTerminator(obj.Transport, translateTerminator(obj, value{1}), ...
                        translateTerminator(obj, value{2}));
                end
            end

            function numericTerminatorValueSet(obj, value)
                % If the terminator is numeric in nature

                if isscalar(value)
                    configureTerminator(obj.Transport, translateTerminator(obj, value));
                else
                    configureTerminator(obj.Transport, translateTerminator(obj, value(1)), ...
                        translateTerminator(obj, value(2)));
                end
            end
        end
    end

    %% Public Helper methods
    methods
        function setPropertyOnOriginalObject(obj, propertyName, propertyValue)
            % Set the PropertyNameValue property that publishes it's value
            % to the MATLABCodeGenerator class for generating MATLAB code
            % for property setters.

            arguments
                obj
                propertyName (1, 1) string
                propertyValue
            end

            % Temporarily disable hotlinks in error messages for
            % readability in hardware manager dialog.
            currVal = feature("hotlinks");
            cleanup = onCleanup(@() feature("hotlinks", currVal));
            feature("hotlinks", false);

            % For a property that exists on the TransportAccessor, call the
            % setter on the TransportAccessor directly. This will also
            % invoke the set logic for these properties that exist on the
            % TransportAcessor class.
            %
            % For any other transport specific properties, call the
            % property setter on the transport directly. This will only set
            % the property to the specified value - the setter logic needs
            % to be implemented before calling setPropertyOnOriginalObject
            % on such properties.
            if any(propertyName == obj.LocalPropertySetterList)
                obj.(propertyName) = propertyValue;
            else
                obj.Transport.(propertyName) = propertyValue;
            end
        end
    end

    %% Other Helper methods
    methods (Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function handlePropertyEvents(obj, ~, ~)
            obj.ObservableDataAvailable = obj.Transport.(obj.DataAvailablePropertyName);
        end

        function value = translateTerminator(obj, value)
            % Get the translated terminator value from the terminator
            % entry.

            if isnumeric(value)
                return
            end

            % If the terminator value is not one of - "CR", "LF", or
            % "CR/LF"
            validTerminators = obj.getValidTerminators();
            if ~any(value == validTerminators)
                value = str2double(value);
            end
        end

        function validTerminators = getValidTerminators(~)
            validTerminators = matlabshared.transportapp.internal.utilities.transport.TerminatorClass.TerminatorDropDownValues;
        end
    end

    %% Hook Methods
    methods(Access = {?matlabshared.transportapp.internal.utilities.ITestable})
        function terminatorObj = getTerminatorClassHook(~, readTerminator, writeTerminator)
            terminatorObj = matlabshared.transportapp.internal.utilities.transport.TerminatorClass ...
                (readTerminator, writeTerminator);
        end
    end
end
