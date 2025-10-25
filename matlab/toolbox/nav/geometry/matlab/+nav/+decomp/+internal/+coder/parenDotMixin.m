classdef parenDotMixin < ...
        matlab.mixin.internal.indexing.Paren & ...
        matlab.mixin.internal.indexing.ParenAssign & ...
        coder.mixin.internal.indexing.Dot & ...
        coder.mixin.internal.indexing.Resizable
%This function is for internal use only. It may be removed in the future.

%   Copyright 2024 The MathWorks, Inc.

%parenDotMixin Mixin redirect for spoofing object-arrays paren/dot behavior during codegen

%#codegen
    properties (Abstract)
        ManagedGroup
    end
    properties (Abstract,Hidden,Constant)
        ManagedClassType
    end
    methods
        %% Assigning, retrieving
        function newObj = parenReference(obj,varargin)
            ctor = str2func(class(obj));
            if coder.internal.isConstTrue(isscalar(varargin)) && coder.internal.isConstTrue(isscalar(varargin{:})) && coder.internal.isConstTrue(varargin{:} ~= ':')
                newObj = obj.ManagedGroup(varargin{:}).Var;
            else
                if coder.internal.isConstTrue(isscalar(obj.ManagedGroup(varargin{:})))
                    newObj = obj.ManagedGroup(varargin{:}).Var;
                else
                    newObj = ctor(obj.ManagedGroup(varargin{:}));
                end
            end
        end
        function obj = parenAssign(obj,rhs,varargin)
            ctor = str2func(class(obj));
            if coder.internal.isConstTrue(isempty(rhs))
                obj.ManagedGroup(varargin{:}) = [];
            else
                if coder.internal.isConstTrue(isscalar(varargin)) && coder.internal.isConstTrue(isscalar(varargin{:}))
                    if varargin{:} == numel(obj.ManagedGroup)+1
                        if coder.internal.isConstTrue(isrow(obj))
                            obj.ManagedGroup = [obj.ManagedGroup(:)' ctor(rhs).ManagedGroup(:)'];
                        else
                            obj.ManagedGroup = [obj.ManagedGroup(:); ctor(rhs).ManagedGroup(:)];
                        end
                    else
                        obj.ManagedGroup(varargin{:}) = ctor(rhs).ManagedGroup;
                    end
                else
                    obj.ManagedGroup(varargin{:}) = ctor(rhs).ManagedGroup;
                end
            end
        end
        function obj = dotAssign(obj,name,value) %#ok<INUSD>
            coder.internal.error('MATLAB:index:expected_one_output_for_assignment',numel(obj));
        end
        function varargout = dotReference(obj,name) %#ok<STOUT>
        %dotReference Support syntax like objArray.<prop> or objArray.<noArgMethod>
            ctor = str2func(obj.ManagedClassType);
            if coder.internal.isConstTrue(isprop(ctor(),name))
                coder.internal.assert(false,'nav:geometry:polygondecomposition:InvalidObjectArrayPropAccess',name);
            else
                coder.internal.assert(false,'nav:geometry:polygondecomposition:InvalidObjectArrayMethod',name);
            end
        end
    end
end
