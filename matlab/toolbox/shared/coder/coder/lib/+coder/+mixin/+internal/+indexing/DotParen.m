classdef (Abstract, HandleCompatible) DotParen
% Coder-specific DotParen implementation

%   Copyright 2019 The Mathworks, Inc.
%#codegen

    methods (Abstract, Access = public)
        % dotParenReference implements obj.fname(...).
        out = dotParenReference(obj, fname, varargin);

        % dotParenAssign implements obj.fname(...) = rhs.
        out = dotParenAssign(obj, fname, rhs, varargin);

        % dotParenEnd implements obj.name(end).
        % Clients override this method to
        % forward to the named element's end.
        % k is the index in the expression using the end syntax.
        % n is the total number of indices in the expression.
        ind = dotParenEnd(obj, name, k, n);
    end

    methods(Access = public)
        % dotParenSpan implements obj.name(:).
        % Clients may override this method to
        % implement more efficient mechanisms.
        % spanningRange is the interval 1:obj.dotParenEnd(1).
        function out = dotParenSpan(obj, name, spanningRange)
            out = obj.dotParenReference(name, spanningRange);
            out = out(:);
        end
    end
end
