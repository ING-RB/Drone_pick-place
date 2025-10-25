classdef(Abstract) CellSelectionStrategy
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods(Abstract)
        %subclass must implement select method
        select(~, actor, varargin);
    end
    
    methods(Static)
        function strategy = fromCells(tableCell)
            import matlab.uiautomation.internal.SingleCellSelectionStrategy;
            import matlab.uiautomation.internal.MultiCellSelectionStrategy;
            
            %individual strategies will enforce more validation on the
            %table cell.
            if numel(tableCell) > 2
                strategy = MultiCellSelectionStrategy();
            else
                strategy = SingleCellSelectionStrategy();
            end
        end
    end
end