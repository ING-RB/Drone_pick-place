classdef (Abstract, HandleCompatible) SimpleParen < coder.mixin.internal.indexing.Paren
% Coder-specific SimpleParen implementation

%   Copyright 2018-2019 The MathWorks, Inc.
%#codegen

    methods (Abstract, Access = protected)
        parenRead(obj, indices);
        parenWrite(obj, rhs, indices);
    end

    methods (Access = public)
        function out = parenReference(obj, varargin)
            coder.mixin.internal.indexing.checkIndices(obj, varargin{:});
            out = obj.parenRead(varargin{:});
        end

        function obj = parenAssign(obj, rhs, varargin)
            coder.mixin.internal.indexing.checkIndices(obj, varargin{:});
            obj = obj.parenWrite(rhs, varargin{:});
        end

        function obj = parenDelete(obj, ~)
        % Client code must override parenDelete
            coder.internal.errorIf(true, 'Coder:builtins:ElementDeletionUnsupported', class(obj));
        end
    end
end
