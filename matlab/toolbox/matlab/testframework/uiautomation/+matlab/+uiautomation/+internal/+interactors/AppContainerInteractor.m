classdef AppContainerInteractor < matlab.uiautomation.internal.interactors.AbstractContainerComponentInteractor
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2023 The MathWorks, Inc.
    
    methods

        function uilock(actor, bool)
            if strcmp(actor.Component.Visible, 'off')
                queueLockForInvisibleAppContainer(actor, bool)
                return;
            end
            
            actor.Dispatcher.dispatch(...
                actor.Component, 'uilock', 'Value', bool);
        end
        
    end
    
    methods (Access = private)
        
        function queueLockForInvisibleAppContainer(actor, bool)
            appcontainer = actor.Component;
            cls = ?matlab.ui.container.internal.AppContainer;
            prop = findobj(cls.PropertyList, 'Name', 'Visible');
            L = event.proplistener(appcontainer, prop, 'PostSet', @(o,e)actor.doLockAndDeleteListener(bool));
            setappdata(appcontainer, 'uilockListener', L);
        end
        
        function doLockAndDeleteListener(actor, bool)
            appcontainer = actor.Component;
            rmappdata(appcontainer, 'uilockListener');
            actor.uilock(bool)
        end
    end
end

% LocalWords:  uilock
