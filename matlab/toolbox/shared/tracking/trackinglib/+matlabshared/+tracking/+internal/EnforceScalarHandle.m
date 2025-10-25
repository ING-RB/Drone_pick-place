% EnforceScalarHandle overloads key methods to prevent the creation of
% object arrays. Handle classes that inherit from it will get overloads of
%
% This class supports codegen.
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
%
% Errors are thrown as caller if objects are accessed from the command
% line. Otherwise the full error stack is thrown so that the error can be
% traced.
    
% Copyright 2016-2020 The MathWorks, Inc.
    
classdef EnforceScalarHandle < handle & matlab.internal.mixin.Scalar 
    methods(Access = private, Static)
        % Redirect to enable codegen. We need this until an overloaded
        % subsref is allowed for codegen (g912825).
        function name = matlabCodegenRedirect(~)
            name = 'matlabshared.tracking.internal.enforcescalar.HandleCodegen';
        end
    end
end
