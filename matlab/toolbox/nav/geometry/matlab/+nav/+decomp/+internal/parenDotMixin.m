classdef parenDotMixin < ...
        matlab.mixin.indexing.RedefinesDot & ...
        matlab.mixin.indexing.RedefinesParen & ...
        coder.mixin.internal.indexing.Resizable
%This function is for internal use only. It may be removed in the future.

%   Copyright 2024 The MathWorks, Inc.

%parenDotMixin Mixin for spoofing object-arrays paren/dot behavior during codegen

%#codegen
    properties (Abstract)
        ManagedGroup
    end
    properties (Abstract,Hidden,Constant)
        ManagedClassType
    end
    methods (Access=protected)
        %% Dot assigning, querying
        function obj = dotAssign(obj,name,value)
            error('Not supported');
        end
        function obj = dotListAssign(obj,name,value)
            error('Not supported');
        end
        function varargout = dotReference(obj,indexOp)
        %dotReference Support syntax like objArray.<prop> or objArray.<noArgMethod>
            varargout = obj.dotListReference(indexOp);
        end
        function out = dotListReference(obj,indexOp)
        %dotReference Support syntax like objArray.<prop> or objArray.<noArgMethod>

            % Forward call to managed array
            tmp = [obj.ManagedGroup.Var];
            out = cell(numel(tmp),1);
            [out{:}] = deal(tmp.(indexOp.Name));
        end

        %% Element assigning, retrieving
        function newObj = parenReference__(obj,varargin)
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
        function obj = parenAssign__(obj,rhs,varargin)
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
        function varargout = parenReference(obj,indexOp)
            newObj = obj.parenReference__(indexOp(1).Indices{:});
            if numel(indexOp) > 1
                if indexOp(2).Type == "Dot"
                    if coder.internal.isConstTrue(isscalar(newObj))
                        [varargout{1:nargout}] = newObj.(indexOp(2).Name);
                    else
                        [varargout{1:numel(newObj)}] = newObj.(indexOp(2).Name);
                    end
                else
                    varargout = newObj.parenReference(indexOp(2:end));
                end
            else
                varargout = {newObj};
            end
        end
        function obj = parenAssign(obj,indexOp,varargin)
            obj = obj.parenAssign__(varargin{:},indexOp.Indices{:});
        end
        function obj = parenDelete(obj,indexOp)
            obj.ManagedGroup(indexOp.Indices{:}) = [];
        end
        function n = dotListLength(obj,indexOp,indexContext)
            if numel(indexOp) > 1
                tmp = obj.(indexOp(1).Name);
                n = listLength(tmp,indexOp(2:end),indexContext);
            else
                n = numel(obj);
            end
        end
        function n = parenListLength(obj,indexOp,indexContext)
            if numel(indexOp) > 1
                tmp = obj.parenReference__(indexOp(1).Indices{:});
                n = listLength(tmp,indexOp(2:end),indexContext);
            else
                n = 1;
            end
        end
    end

    methods (Static,Hidden)
        function varargout = callFcn(fcn,n,varargin)
            [varargout{1:n}] = fcn(varargin{:});
        end
    end

    methods (Static = true)
        function name = matlabCodegenRedirect(codegenTargetName)
            name = 'nav.decomp.internal.coder.parenDotMixin';
        end
    end
end
