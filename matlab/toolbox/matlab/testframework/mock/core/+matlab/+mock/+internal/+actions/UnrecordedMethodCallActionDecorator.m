classdef UnrecordedMethodCallActionDecorator < matlab.mock.actions.MethodCallAction
    % This class is undocumented and may change in a future release.
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (SetAccess=immutable, GetAccess=private)
        DelegateAction (1,1) matlab.mock.actions.MethodCallAction = ...
            matlab.mock.internal.actions.ReturnEmptyDouble;
    end
    
    methods
        function action = UnrecordedMethodCallActionDecorator(delegateAction)
            action.DelegateAction = delegateAction;
        end
        
        function varargout = callMethod(action, varargin)
            [varargout{1:nargout}] = action.DelegateAction.callMethod(varargin{:});
        end
        
        function entry = addMethodCallRecord(varargin)
            import matlab.mock.internal.ListEntry;
            entry = ListEntry; % Null ListEntry
        end
    end
end

