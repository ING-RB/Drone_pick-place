classdef CallSuperclass < matlab.mock.actions.MethodCallAction
    % This class is undocumented and may change in a future release.
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties (SetAccess=immutable, GetAccess=private)
        Superclass string;
        ResolvedSuperclass string;
    end
    
    methods
        function action = CallSuperclass(superclass)
            arguments
                superclass (1,1) meta.class;
            end
            action.Superclass = superclass.Name;
            action.ResolvedSuperclass = superclass.ResolvedName;
        end
    end
    
    methods (Hidden)
        function varargout = callMethod(action, ~, methodName, ~, varargin)
            [varargout{1:nargout}] = builtin("_callMockSuperclassMethod", ...
                action.Superclass, action.ResolvedSuperclass, methodName, varargin{:});
        end
    end
end

