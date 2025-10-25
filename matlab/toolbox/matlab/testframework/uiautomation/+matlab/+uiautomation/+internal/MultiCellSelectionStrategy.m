classdef MultiCellSelectionStrategy < matlab.uiautomation.internal.CellSelectionStrategy
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2020 The MathWorks, Inc.
    
    methods(Access=?matlab.uiautomation.internal.CellSelectionStrategy)
        function obj = MultiCellSelectionStrategy()
        end
    end
    
    methods
        
        function select(strategy, actor, cells, options)
            arguments
                strategy
                actor
                cells {mustBeNonempty, validateCells(strategy, actor, cells)}
                options.SelectionMode (1, 1) string {mustBeMember(options.SelectionMode, ...
                    ["contiguous", "discontiguous"])} = "discontiguous";
            end
            
            if ~actor.Component.Multiselect
                error(message('MATLAB:uiautomation:Driver:ComponentNotMultiSelectable'));
            end
            
            cells = sortrows(cells); %sort them irrespective of user input.
            
            %toggle columneditable off to make the gestures robust
            cache = actor.Component.ColumnEditable;
            actor.Component.ColumnEditable = false;
            p = onCleanup(@()resetColumnEditable(actor.Component, cache));
            
            switch options.SelectionMode
                case "contiguous"
                    rangeSelect(strategy, actor, cells);
                case "discontiguous"
                    discreteSelect(strategy, actor, cells);
            end
            
            function resetColumnEditable(component, cache)
                component.ColumnEditable = cache;
            end
        end
        
    end
    
    methods(Access='private')
        
        function rangeSelect(~, actor, cells)
            import matlab.uiautomation.internal.Modifiers;
            
            assert(isequal(size(cells), [2 2]), ...
                message('MATLAB:uiautomation:Driver:IncorrectCellValues'));
            startCell = cells(1, :);
            endCell = cells(2, :);
            
            table = actor.Component;
            
            %given start and end cell, compute everything in between
            u = repelem(startCell(1):endCell(1) , endCell(2)-startCell(2) + 1);
            v = repmat(startCell(2):endCell(2), [1 endCell(1)-startCell(1) + 1]);
            selection = [u' v'];
            
            if isequal(table.SelectionType, 'cell') && ...
                    isequal(table.Selection, selection)
                return;
            end
            
            actor.Dispatcher.dispatch(table, 'uipress', 'row', startCell(1), ...
                'col', startCell(2));
            
            modifier = Modifiers.SHIFT;
            actor.Dispatcher.dispatch(table, 'uipress', 'row', endCell(1), ...
                'col', endCell(2), 'Modifier', modifier);
            
        end
        
        function discreteSelect(~, actor, cells)
            import matlab.uiautomation.internal.Modifiers;
            
            table = actor.Component;
            
            %filter duplicates out
            cells = unique(cells, 'rows');
            
            if isequal(table.SelectionType, 'cell') && ...
                    isequal(table.Selection, cells)
                return;
            end
            
            %clear out previous selections if any
            actor.Dispatcher.dispatch(table, 'uipress', 'row', cells(1, 1), ...
                'col', cells(1, 2));
            
            % g2301897- keyboard multiselection behavior differences for
            % "row" vs "column" selectiontype
            needShift = true;
            if isequal(table.SelectionType, 'row')
                needShift = false;
            end
            
            meta = Modifiers.CTRL;
            for i = 2:size(cells, 1)
                cell = cells(i, :);
                actor.Dispatcher.dispatch(table, 'uipress', 'row', cell(1), ...
                    'col', cell(2), 'Modifier', meta);
                
                if(needShift)
                    shift = Modifiers.SHIFT;
                    actor.Dispatcher.dispatch(table, 'uipress', 'row', cell(1), ...
                    'col', cell(2), 'Modifier', shift);
                end
            end
        end

        function validateCells(~, actor, cells)
            for i = 1: size(cells, 1)
                cell = cells(i, :);
                actor.validateCellIndicialArguments(cell);
            end
        end
    end
end