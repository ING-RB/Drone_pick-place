classdef (Abstract, HandleCompatible) Dot
% Coder-specific Dot implementation

%   Copyright 2019 The MathWorks, Inc.
%#codegen

    methods (Abstract, Access = public)
        dotReference(obj, name);
        dotAssign(obj, name, value);
        % @see g1963969
        % dotListReference(obj, name)
        % @see g1963969
        % dotListAssign(obj, name, varargin)
    end
end

