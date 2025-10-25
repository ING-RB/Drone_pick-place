classdef valueArrayManager < nav.decomp.internal.parenDotMixin
%This function is for internal use only. It may be removed in the future.

%   Copyright 2024 The MathWorks, Inc.

%valueArrayManager Helper for spoofing object-arrays during codegen

%#codegen
    properties
        ManagedGroup
    end
    properties (Abstract,Hidden,Constant)
        ManagedClassType
        Ctor
    end
    methods
        function obj = valueArrayManager(objectArray)
            arguments
                objectArray = {};
            end
            if coder.internal.isConstTrue(isempty(objectArray))
                ctor = str2func(obj.ManagedClassType);
                inputs = repmat(struct('Var',ctor()),0,0);
                coder.varsize('inputs');
                obj.ManagedGroup = inputs;
            else
                mustBeA(objectArray,{'cell','struct',obj.ManagedClassType,obj.Ctor})

                switch class(objectArray)
                    case 'struct'
                        input = objectArray;
                        coder.varsize('input');
                        obj.ManagedGroup = input;
                    case obj.Ctor
                        obj = objectArray;
                    case obj.ManagedClassType
                        input = struct('Var',objectArray);
                        coder.varsize('input');
                        obj.ManagedGroup = input;
                    otherwise
                        error('Not a valid input');
                end
            end
        end

        %% Rearranging
        function newObj = reshape(obj,varargin)
            ctor = str2func(class(obj));
            newObj = ctor(reshape(obj.ManagedGroup,varargin{:}));
        end
        function newObj = permute(obj,varargin)
            ctor = str2func(class(obj));
            newObj = ctor(permute(obj.ManagedGroup,varargin{:}));
        end
        function newObj = transpose(obj,varargin)
            ctor = str2func(class(obj));
            newObj = ctor(transpose(obj.ManagedGroup,varargin{:}));
        end
        function obj = ctranspose(obj,varargin)
            ctor = str2func(class(obj));
            obj = ctor(ctranspose(obj.ManagedGroup,varargin{:}));
        end
        function obj = horzcat(obj,varargin)
            ctor = str2func(class(obj));
            obj.ManagedGroup = horzcat(obj.ManagedGroup,ctor(varargin{:}).ManagedGroup);
        end
        function obj = vertcat(obj,varargin)
            ctor = str2func(class(obj));
            obj.ManagedGroup = vertcat(obj.ManagedGroup,ctor(varargin{:}).ManagedGroup);
        end
        function obj = cat(dim,varargin)
            obj = varargin{1};
            ctor = str2func(class(obj));
            for i = 2:numel(varargin)
                obj.ManagedGroup = cat(dim,obj.ManagedGroup,ctor(varargin{i}).ManagedGroup);
            end
        end

        %% Size, shape, and classification Introspection
        function tf = iscolumn(obj)
            tf = iscolumn(obj.ManagedGroup);
        end
        function tf = isempty(obj)
            tf = isempty(obj.ManagedGroup);
        end
        function tf = isequal(obj)
            tf = isequal(obj.ManagedGroup);
        end
        function tf = isequaln(obj)
            tf = isequaln(obj.ManagedGroup);
        end
        function tf = ismatrix(obj)
            tf = ismatrix(obj.ManagedGroup);
        end
        function tf = isrow(obj)
            tf = isrow(obj.ManagedGroup);
        end
        function tf = isscalar(obj)
            tf = isscalar(obj.ManagedGroup);
        end
        function tf = isvector(obj)
            tf = isvector(obj.ManagedGroup);
        end
        function n = length(obj)
            n = length(obj.ManagedGroup);
        end
        function n = ndims(obj)
            n = ndims(obj.ManagedGroup);
        end
        function tf = ne(obj)
            tf = ne(obj.ManagedGroup);
        end
        function n = numel(obj)
            n = numel(obj.ManagedGroup);
        end
        function sz = size(obj,varargin)
            sz = size(obj.ManagedGroup,varargin{:});
        end
        function type = underlyingType(obj)
            type = obj.ManagedClassType;
        end
        function idx = end(obj,k,n)
            sz = size(obj);
            if k < n
                idx = sz(k);
            else
                idx = prod(sz(k:end));
            end
        end
    end
    methods (Static = true)
        function name = matlabCodegenRedirect(codegenTargetName)
            name = 'nav.decomp.internal.coder.valueArrayManager';
        end
    end
end
