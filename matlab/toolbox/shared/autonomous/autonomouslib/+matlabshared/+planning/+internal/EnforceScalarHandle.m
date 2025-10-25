% EnforceScalarHandle overloads key methods to prevent the creation of
% object arrays. This class supports codegen.
%
% Examples of syntaxes that will error out:
%
%  obj(1)
%  obj(ones(3,3))
%  obj(2) = obj
%  [obj obj] % horzcat
%  [obj;obj] % vertcat
%  obj(1).property
%  repmat(obj,3,3)
%  cat(2,obj,obj)

% NOTE: This is a copy of vision.internal.EnforceScalarHandle

% Copyright 2017-2018 The MathWorks, Inc.

classdef EnforceScalarHandle <  handle & matlab.mixin.internal.Scalar
    methods(Access = public, Static, Hidden)
        % Redirect to enable codegen. We need this until an overloaded
        % subsref is allowed for codegen (g912825).
        function name = matlabCodegenRedirect(~)
            name = 'matlabshared.planning.internal.HandleCodegen';
        end
    end
end
