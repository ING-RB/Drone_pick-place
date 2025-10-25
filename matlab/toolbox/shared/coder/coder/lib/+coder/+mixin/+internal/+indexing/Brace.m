classdef (Abstract, HandleCompatible) Brace
% Coder-specific Brace implementation

%   Copyright 2019 The Math Works, Inc.
%#codegen

    methods (Abstract, Access = public)
        braceReference(obj, varargin);
        braceAssign(obj, rhs, varargin);
        braceListReference(obj, varargin);
        braceListAssign(obj, nrhs, varargin);
    end
end
