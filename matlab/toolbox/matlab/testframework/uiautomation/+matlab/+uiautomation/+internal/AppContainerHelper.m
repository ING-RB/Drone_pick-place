classdef AppContainerHelper     
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2023 The MathWorks, Inc.
    
    methods
        
        function flush(~, component)
            
            appcontainer = ancestor(component, 'matlab.ui.container.internal.AppContainer');
            if isempty(appcontainer)
                return;
            end
            
            pollForViewReady(appcontainer);
            
        end
        
    end
    
    methods (Static, Hidden)
        
        function current = strict(bool)
            persistent pValue;
            if isempty(pValue)
                % initialize
                pValue = false;
            end
            
            current = pValue;
            if nargin>0
                pValue = bool;
            end
        end
        
    end
    
end

function pollForViewReady(container)
import matlab.uiautomation.internal.AppContainerHelper;
import matlab.ui.container.internal.appcontainer.AppState;

t0 = tic;
while ~isequal(container.State, AppState.TERMINATED) && toc(t0) <= 60
    % wait until the container is ready
    if container.Visible && isequal(container.State, AppState.RUNNING)
        break;
    end
end

if AppContainerHelper.strict()
    assert(isequal(container.State, AppState.RUNNING), "Container was not view-ready");
end

end

% LocalWords:  appcontainer
