classdef stack
%MATLAB Code Generation Private Class


%   Copyright 2017-2019 The MathWorks, Inc.
%#codegen
    properties
        d         % data
        n         % stack size
        fixedSize % is stack resizable
    end
    methods
        function this = stack(eg,n,fixedSize)
        % We assume n is a valid size. eg should be an example for the data to be stored
        % in the stack. fixedSize should be true for a fixed size stack. Pushing
        % past the specified size will error. If not, the stack is dynamically
        % grown as needed.
        %
        % coder.internal.stack is implemented as a value class to avoid handle
        % class allocation limitations. Doing so makes this class more
        % flexible. It is recommended to use the x = foo(x) idiom when invoking
        % "mutator" methods like push and pop:
        %
        %   s = coder.internal.stack(...);
        %   s = s.push(...);
        %   [data,s] = s.pop();
        %
        % Doing so should result in s being passed by reference so that it is
        % modified in place.
            if nargin > 1
                coder.internal.prefer_const(n);
                nint = coder.internal.indexInt(n);
            else
                nint = coder.internal.indexInt(0);
            end
            this.n = coder.internal.indexInt(0);
            if nargin > 2
                coder.internal.prefer_const(fixedSize);
                this.fixedSize = logical(fixedSize);
            else
                this.fixedSize = false;
            end
            scalEg = coder.internal.scalarEg(eg);
            if this.fixedSize
                if coder.target('MATLAB')
                    this.d = repmat(scalEg,[nint,coder.internal.indexInt(1)]);
                else
                    this.d = coder.nullcopy(eml_expand(scalEg,[nint,coder.internal.indexInt(1)]));
                end
            else
                if coder.target('MATLAB')
                    this.d = repmat(scalEg,[coder.ignoreConst(nint),coder.internal.indexInt(1)]);
                else
                    this.d = coder.nullcopy(eml_expand(scalEg,[coder.ignoreConst(nint),coder.internal.indexInt(1)]));
                end
            end
        end
        function this = push(this,x)
            coder.inline('always');
            nd = coder.internal.indexInt(numel(this.d));
            if this.fixedSize
                coder.internal.assert(this.n < nd, ...
                                      'Coder:toolbox:StackPushLimit');
                this.d(this.n+1) = x;
            else
                if this.n == nd
                    this.d = [this.d; x];
                else
                    this.d(this.n+1) = x;
                end
            end
            this.n = this.n+1;
        end
        function y = peek(this)
            coder.inline('always');
            coder.internal.errorIf(this.n <= 0, ...
                                   'Coder:toolbox:StackPeekEmpty');
            y = this.d(this.n);
        end
        function [y,this] = pop(this)
            coder.inline('always');
            coder.internal.errorIf(this.n <= 0, ...
                                   'Coder:toolbox:StackPopEmpty');
            y = this.d(this.n);
            this.n = this.n-1;
        end
        function n = stackSize(this)
        % Returns a coder.internal.indexInt. Cast to double if returning to generic
        % code.
            coder.inline('always');
            n = this.n;
        end
    end
    methods (Access = public, Static = true)
        function c = matlabCodegenNontunableProperties(~)
            c = {'fixedSize'};
        end
    end
end
