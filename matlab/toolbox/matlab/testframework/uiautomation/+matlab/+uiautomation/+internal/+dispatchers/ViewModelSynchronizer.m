classdef ViewModelSynchronizer < matlab.uiautomation.internal.dispatchers.DispatchDecorator
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2019-2023 The MathWorks, Inc.
    
    methods
       
        function dispatch(decorator, model, varargin)
            import matlab.uiautomation.internal.FigureHelper; 
            import matlab.uiautomation.internal.AppContainerHelper; 
            
            if(isa(model, 'matlab.ui.container.internal.AppContainer'))
                helper = AppContainerHelper;
            else
                assertVisibleHierarchy(model);
                helper = FigureHelper;                
            end
            helper.flush(model);
            
            dispatch@matlab.uiautomation.internal.dispatchers.DispatchDecorator( ...
                decorator, model, varargin{:});
            
            helper.flush(model);
        end
        
    end
end

function assertVisibleHierarchy(H)

% Some components (e.g. Tab, AccordionPanel) don't have a Visible property - it depends on the parent.
% Otherwise check its Visible property.
isVisible = @(x) (~isprop(x, 'Visible') || isa(x, 'matlab.ui.container.ContextMenu')) || strcmp(x.Visible, 'on');

while ~isempty(H) && ~isa(H, 'matlab.ui.Root')
    if ~isVisible(H)
        error(message('MATLAB:uiautomation:Driver:VisibleHierarchy'));
    end
    H = H.Parent;
end

end
