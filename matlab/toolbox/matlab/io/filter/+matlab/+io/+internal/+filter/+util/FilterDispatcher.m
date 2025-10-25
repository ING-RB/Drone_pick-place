classdef (HandleCompatible) FilterDispatcher
%FilterDispatcher   Helper class for writing code that needs to branch
%   on a per-rowfilter level.
%
%   Effectively just an abstraction around a switch statement. But
%   can help avoid a lot of ugly branching code if used well.

%   Copyright 2021 The MathWorks, Inc.

    methods (Abstract)
        varargout = processMissingRowFilter         (dispatcher, filter, varargin);
        varargout = processNegationRowFilter        (dispatcher, filter, varargin);
        varargout = processUnconstrainedRowFilter   (dispatcher, filter, varargin);
        varargout = processSingleVariableRowFilter  (dispatcher, filter, varargin);
        varargout = processMultipleVariableRowFilter(dispatcher, filter, varargin);
    end

    methods
        function varargout = dispatch(dispatcher, filter, varargin)
            internalPackageName = "matlab.io.internal.filter.";
            externalPackageName = "matlab.io.";

            cls = string(class(filter));
            switch cls
                case internalPackageName + "MissingRowFilter"
                    [varargout{1:nargout}] = dispatcher.processMissingRowFilter         (filter, varargin{:});
                case externalPackageName + "RowFilter"
                    [varargout{1:nargout}] = dispatcher.processComposedRowFilter        (filter, varargin{:});
                case internalPackageName + "NegationRowFilter"
                    [varargout{1:nargout}] = dispatcher.processNegationRowFilter        (filter, varargin{:});
                case internalPackageName + "UnconstrainedRowFilter"
                    [varargout{1:nargout}] = dispatcher.processUnconstrainedRowFilter   (filter, varargin{:});
                case internalPackageName + "SingleVariableRowFilter"
                    [varargout{1:nargout}] = dispatcher.processSingleVariableRowFilter  (filter, varargin{:});
                case internalPackageName + "MultipleVariableRowFilter"
                    [varargout{1:nargout}] = dispatcher.processMultipleVariableRowFilter(filter, varargin{:});
                otherwise
                    % Don't recognize this class, so provide a clear error.
                    msgid = "MATLAB:io:filter:filter:InvalidFilterClass";
                    error(message(msgid, cls));
            end
        end

        function varargout = processComposedRowFilter(dispatcher, filter, varargin)
            % "ComposedRowFilter" is the name I'm using for the main public-facing
            % matlab.io.RowFilter class.
            % Provide a default implementation of this since most FilterDispatcher
            % subclasses just need matlab.io.RowFilter to be unwrapped and forwarded
            % to the underlying filter's dispatch method.

            underlyingFilter = getProperties(filter).UnderlyingFilter;

            [varargout{1:nargout}] = dispatcher.dispatch(underlyingFilter, varargin{:});
        end
    end
end
