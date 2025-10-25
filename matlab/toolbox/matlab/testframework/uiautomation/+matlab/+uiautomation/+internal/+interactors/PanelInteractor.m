classdef PanelInteractor < ...
        matlab.uiautomation.internal.interactors.AbstractContainerComponentInteractor
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods
        
        function uipress(actor, pos)
            arguments
                actor
                pos {validatePosition(actor, pos)} = getCenter(actor.Component)
            end
            
            if nargin > 1
                % assume user has provided "Position" argument
                validateUnits(actor);
            end
            
            panel = actor.Component;
            actor.Dispatcher.dispatch(panel, 'uipress', 'X', pos(1),'Y', pos(2));
        end
        
        function uihover(actor, pos)
            arguments
                actor {validateUnits(actor)}
                pos {validatePosition(actor, pos)} = getCenter(actor.Component)
            end
            
            panel = actor.Component;
            actor.Dispatcher.dispatch(panel, 'uihover', 'X', pos(1),'Y', pos(2));
        end
        
        function uicontextmenu(actor, menu, pos)
            arguments
                actor {validateUnits(actor)}
                menu (1,1) matlab.ui.container.Menu {validateParent(actor, menu)}
                pos {validatePosition(actor, pos)} = getCenter(actor.Component)
            end
            
            panel = actor.Component;
            actor.Dispatcher.dispatch(panel, 'uicontextmenu', 'X', pos(1), 'Y', pos(2));
            
            menuInteractor = matlab.uiautomation.internal.InteractorFactory.getInteractorForHandle(menu);
            menuInteractor.uipress();
        end 
    end
end

function pos = getCenter(fig)
currUnits = fig.Units;
c = onCleanup(@()restoreUnits(fig, currUnits));

%switch figure units to pixel for accurate client friedly pixel
%transformations.
fig.Units = 'pixels';
pos = fig.Position([3 4]) ./ 2;

    function restoreUnits(fig, currUnits)
        fig.Units = currUnits;
    end
end