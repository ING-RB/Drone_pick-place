classdef (Abstract) DispatchDecorator < matlab.uiautomation.internal.UIDispatcher
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2017-2018 The MathWorks, Inc.
    
    properties (SetAccess = immutable)
        Delegate
    end
    
    methods
        
        function decorator = DispatchDecorator(delegate)
            decorator.Delegate = delegate;
        end
        
        function dispatch(decorator, varargin)
            decorator.Delegate.dispatch(varargin{:});
        end
        
    end
    
end