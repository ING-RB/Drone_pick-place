classdef (Abstract, HandleCompatible) Paren
% Coder-specific Paren implementation

%   Copyright 2018-2019 The Math Works, Inc.
%#codegen

    methods (Abstract, Access = public)
        parenReference(obj, varargin);
        parenAssign(obj, rhs, varargin);
        parenDelete(obj, varargin);
    end

    methods(Access = public)
        % parenReferenceSpan implements obj(:).
        % Clients may override this method to use
        % knowledge about their data to boost efficiency,
        % or to implement specific semantics.
        function out = parenReferenceSpan(obj, spanningRange)
            out = obj.parenReference(spanningRange);
            out = out(:);
        end
    end
end
