classdef (Abstract, HandleCompatible) SimpleBrace < coder.mixin.internal.indexing.Brace
% Coder-specific SimpleBrace implementation

%   Copyright 2019 The MathWorks, Inc.
%#codegen

    methods (Abstract, Access = protected)
        braceRead(obj, indices);
        braceWrite(obj, rhs, indices);
    end

    methods (Access = public)
        function out = braceReference(obj, varargin)
            indices = coder.mixin.internal.indexing.getIndices(varargin{:});
            coder.mixin.internal.indexing.checkIndices(obj, indices);
            out = obj.braceRead(indices{1,:});
        end

        function obj = braceAssign(obj, rhs, varargin)
            indices = coder.mixin.internal.indexing.getIndices(varargin{:});
            coder.mixin.internal.indexing.checkIndices(obj, indices);
            obj = obj.braceWrite(rhs, indices{1,:});
        end

        function varargout = braceListReference(obj, varargin)
            indices = coder.mixin.internal.indexing.getIndices(varargin{:});
            coder.mixin.internal.indexing.checkIndices(obj, indices);
            for i = 1:size(indices,1)
                tmp = obj.braceRead(indices{i,:});
                if iscell(tmp)
                    [varargout{i}] = tmp{:};
                else
                    varargout{i} = tmp;
                end
            end
        end

        function obj = braceListAssign(obj, nrhs, varargin)
            indices = coder.mixin.internal.indexing.getIndices(varargin{nrhs+1:end});
            coder.mixin.internal.indexing.checkIndices(obj, indices);
            coder.internal.errorIf(size(indices,1) > nrhs, 'MATLAB:legacy_two_part:needMoreRhsOutputs');
            for i = 1:nrhs
                obj = obj.braceWrite(varargin{i}, indices{i,:});
            end
        end
    end
end
