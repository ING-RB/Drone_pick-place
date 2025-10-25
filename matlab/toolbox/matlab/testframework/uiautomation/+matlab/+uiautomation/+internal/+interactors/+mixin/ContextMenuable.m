classdef ContextMenuable < handle
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2019 The MathWorks, Inc.
    
    methods(Sealed)
        
        function uicontextmenu(actor, menu)
            
            arguments
                actor
                menu (1,1) matlab.ui.container.Menu {validateParent}
            end
            
            container = actor.Component;
            actor.Dispatcher.dispatch(container, 'uicontextmenu');
            
            menuInteractor = matlab.uiautomation.internal.InteractorFactory.getInteractorForHandle(menu);
            menuInteractor.uipress();
        end
        
    end
    
end

function validateParent(menu)
if isempty(ancestor(menu, 'matlab.ui.container.ContextMenu'))
    error(message('MATLAB:uiautomation:Driver:InvalidContextMenuOption'));
end
end