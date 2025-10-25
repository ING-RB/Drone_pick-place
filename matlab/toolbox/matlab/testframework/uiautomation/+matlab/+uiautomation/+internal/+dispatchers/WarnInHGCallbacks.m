classdef WarnInHGCallbacks < matlab.uiautomation.internal.dispatchers.DispatchDecorator
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2017-2024 The MathWorks, Inc.
    
    methods
        
        function decorator = WarnInHGCallbacks(delegate)
            decorator@matlab.uiautomation.internal.dispatchers.DispatchDecorator(delegate);
        end
        
        function dispatch(decorator, varargin)
            if ~isempty(gcbo) && ...
                ... skip warning if gesture is chooseDialog or dismissDialog
                ~ismember(string(varargin{2}), ["chooseDialog", "dismissDialog"])

                warning( message('MATLAB:uiautomation:Driver:WarnInHGCallbacks') );
            end
            dispatch@matlab.uiautomation.internal.dispatchers.DispatchDecorator( ...
                decorator, varargin{:});
        end
        
    end
    
end