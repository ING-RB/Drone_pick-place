classdef Handler < matlab.mixin.Heterogeneous & handle % Use handle for "unique" and caching
    % Handler - Base class for informal suite creation handlers.
    %   Each handler decides if it can handle the input and if so returns
    %   the test suite as the result of handling the input.

    % Copyright 2022 The MathWorks, Inc.

    properties (Abstract, Constant)
        Precedence (1,1) matlab.unittest.internal.services.informalsuite.HandlerPrecedence;
    end

    methods (Abstract)
        % Create a test suite for the array of tests. The handler's
        % canHandle method must return true for every element of "tests".
        suite = createSuite(handler, tests, options);
    end

    methods (Abstract, Access=protected)
        % Determine if the handler recognizes the test content.
        bool = canHandle(handler, test);
    end

    methods (Access=protected)
        function exception = unhandledTestException(~, ~)
            % Overridable hook method to return a specific exception to
            % indicate why a handler can't handle a value.
            exception = MException.empty;
        end
    end

    methods (Sealed)
        function handler = findFirstSupportedHandler(handlers, test)
            % Return the first handler the supports the input or throw an
            % exception if none found.

            for idx = 1:numel(handlers)
                handler = handlers(idx);
                if handler.canHandle(test)
                    return;
                end
            end

            me = MException(message("MATLAB:unittest:TestSuite:UnrecognizedSuite", test));
            for idx = 1:numel(handlers)
                exception = handlers(idx).unhandledTestException(test);
                if ~isempty(exception)
                    me = me.addCause(exception);
                end
            end
            throwAsCaller(me);
        end

        function varargout = ne(varargin)
            [varargout{1:nargout}] = ne@handle(varargin{:});
        end
    end
end

% LocalWords:  Overridable
