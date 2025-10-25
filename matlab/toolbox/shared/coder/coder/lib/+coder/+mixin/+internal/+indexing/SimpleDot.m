classdef (Abstract, HandleCompatible) SimpleDot < coder.mixin.internal.indexing.Dot
% Coder-specific SimpleDot implementation

%   Copyright 2019 The MathWorks, Inc.
%#codegen

    methods (Abstract, Access = protected)
        dotRead(obj, name);
        dotWrite(obj, name, value);
    end

    methods (Access = public)
        function out = dotReference(obj, name)
            out = obj.dotRead(name);
        end

        function obj = dotAssign(obj, name, value)
            obj = obj.dotWrite(name, value);
        end

        % @see g1963969
        % function varargout = dotListReference(obj, name)

        % @see g1963969
        % function obj = dotListAssign(obj, name, varargin)
    end
end

