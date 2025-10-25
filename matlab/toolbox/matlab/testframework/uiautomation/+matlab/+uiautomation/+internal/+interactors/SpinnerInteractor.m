classdef SpinnerInteractor < ...
        matlab.uiautomation.internal.interactors.AbstractComponentInteractor & ...
        matlab.uiautomation.internal.interactors.mixin.NumericTypable & ...
        matlab.uiautomation.internal.interactors.mixin.ContextMenuable
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2019 The MathWorks, Inc.
    
    methods
        
        function uipress(actor, updown)
            
            narginchk(2, 2);
            
            updown = validatestring(updown, {'up', 'down'});
            
            actor.Dispatcher.dispatch(actor.Component, 'uipress', 'Direction', updown);
        end
        
    end
    
end