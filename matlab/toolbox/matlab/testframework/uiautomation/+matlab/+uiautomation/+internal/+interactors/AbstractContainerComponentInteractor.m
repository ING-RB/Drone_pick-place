classdef AbstractContainerComponentInteractor < ...
        matlab.uiautomation.internal.interactors.AbstractComponentInteractor
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2020 - 2023 The MathWorks, Inc.
    
    methods (Access = protected)
        function validateUnits(actor, ~)
            container = actor.Component;
            if container.Units ~= "pixels"
                error(message('MATLAB:uiautomation:Driver:UnitsMustBePixels'));
            end
        end

        function xyInPixelUnits = convertToPixelUnits(actor, xy)
            container = actor.Component;
            fig = ancestor(container, 'figure');
            posInPixelUnits = hgconvertunits(fig, [xy(1) xy(2) 0 0], container.Units, 'pixels', container);
            xyInPixelUnits = posInPixelUnits(1:2);
        end
        
        function validatePosition(~, value)
            validateattributes(value, {'numeric'}, ...
                {'row', 'real', 'finite', 'size', [1 2]});
        end
        
        function validateParent(~, menu)
            if isempty(ancestor(menu, 'matlab.ui.container.ContextMenu'))
                error(message('MATLAB:uiautomation:Driver:InvalidContextMenuOption'));
            end
        end
    end
end