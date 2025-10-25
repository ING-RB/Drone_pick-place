classdef (Hidden) InterpretableComponent < appdesservices.internal.interfaces.model.AbstractModelMixin
    % This undocumented class may be removed in a future release.

    % This is a mixin parent class for all visual components that have an
    % 'Interpreter' property
    %
    % This class provides all implementation and storage for
    % 'Interpreter'

    % Copyright 2023 The MathWorks, Inc.

    properties (Dependent, AbortSet)
        Interpreter = 'none';
    end

    properties(Access = 'protected')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control for each property
        %
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set

        PrivateInterpreter = 'none';
    end


    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function set.Interpreter(obj, newValue)
            % Error Checking
            try
                newInterpreter = matlab.ui.control.internal.model.PropertyHandling.processEnumeratedString(...
                    obj, ...
                    newValue, ...
                    {'none', 'html', 'latex', 'tex'});
            catch ME %#ok<NASGU>
                messageObj = message('MATLAB:ui:components:invalidFourStringEnum', ...
                    'Interpreter', 'none', 'html', 'latex', 'tex');

                % MnemonicField is last section of error id
                mnemonicField = 'invalidInterpreter';

                % Use string from object
                messageText = getString(messageObj);

                % Create and throw exception
                exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj, mnemonicField, messageText);
                throw(exceptionObject);

            end

            % Property Setting
            obj.PrivateInterpreter = newInterpreter;

            % Update View
            markPropertiesDirty(obj, {'Interpreter'});
        end

        function value = get.Interpreter(obj)
            value = obj.PrivateInterpreter;
        end
    end


end
