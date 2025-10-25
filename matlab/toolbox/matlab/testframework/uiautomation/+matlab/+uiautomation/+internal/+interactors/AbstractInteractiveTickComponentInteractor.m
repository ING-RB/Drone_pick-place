classdef (Abstract) AbstractInteractiveTickComponentInteractor < ...
        matlab.uiautomation.internal.interactors.AbstractComponentInteractor & ...
        matlab.uiautomation.internal.interactors.mixin.ContextMenuable
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2018 The MathWorks, Inc.
    
    methods
        
        function uichoose(actor, value)
            
            narginchk(2, 2);
            
            component = actor.Component;
            p = value2percentage(component, value);
            
            if component.Value == value
                return;
            end
            
            actor.Dispatcher.dispatch(...
                actor.Component, 'uipress', 'Percentage', p);
        end
        
        function uidrag(actor, from, to)
            
            narginchk(3, 3);
            
            component = actor.Component;
            pFrom = value2percentage(component, from);
            pTo   = value2percentage(component, to);
            
            actor.Dispatcher.dispatch(...
                actor.Component, 'uidrag', 'Percentage', [pFrom pTo]);
        end
        
    end
    
end


function perc = value2percentage(component, value)

validateattributes(value,{'double'},{'scalar','nonnan','real'});

lim = component.Limits;
perc = (value - lim(1)) / (lim(2)-lim(1));
if perc < 0 || perc > 1
    error( message('MATLAB:uiautomation:Driver:ValueOutsideLimits') )
end
end