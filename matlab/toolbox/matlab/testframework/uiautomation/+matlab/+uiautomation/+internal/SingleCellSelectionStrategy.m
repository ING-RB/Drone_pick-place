classdef SingleCellSelectionStrategy < matlab.uiautomation.internal.CellSelectionStrategy
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2020 - 2024 The MathWorks, Inc.
    
    methods(Access=?matlab.uiautomation.internal.CellSelectionStrategy)
        function obj = SingleCellSelectionStrategy()
        end
    end
    
    methods
        function select(strategy, actor, cell, cellData, options)
            arguments
                strategy
                actor
                cell (1, 2) {double, validateCellIndicialArguments(actor, cell)}
                cellData = [];
                options.SelectionMode (1, 1) string {mustBeMember(options.SelectionMode, ...
                    ["contiguous","discontiguous"]), ...
                    validateSelectionModeForSingleCellStrategy(strategy, options.SelectionMode)} = "discontiguous";
            end

            % Cell needs to be edited only if more than 3 parameters are
            % supplied
            editing = nargin > 3;
            cellType = actor.getCellType(cell(1), cell(2));
            isNoOp = false;
            if editing
                %User wants to edit cells
                if ~isEditable(actor, cell)
                    error(message("MATLAB:uiautomation:Driver:UnEditableTableCell") );
                end
                
                switch cellType
                    case 'logical'
                        [cellData, isNoOp] = strategy.forLogicalCell(actor, cell, cellData);
                    case 'categorical'
                        [cellData, isNoOp] = strategy.forCategoricalCell(actor, cell, cellData);
                    case 'popup'
                        [cellData, isNoOp] = strategy.forPopupCell(actor, cell, cellData);
                    otherwise
                        error(message("MATLAB:uiautomation:Driver:UnsupportedTableCellColumnFormat"));               
                end
            else
                if strcmp(cellType, 'logical')
                    % User wants to edit cells, without passing boolean
                    % parameter
                    if ~isEditable(actor, cell)
                        error( message("MATLAB:uiautomation:Driver:UnEditableTableCell") );
                    end
                    [cellData, isNoOp] = strategy.forLogicalCell(actor, cell, cellData);
                else
                    % Select without editing a categorical or popup or char cell
                    if strategy.isCellSelected(actor, cell) && strategy.isSingleCellSelected(actor)
                        % If cell is already selected, this will result in
                        % a noop
                        isNoOp = true;
                    end
                end
            end

            if isNoOp
                %value is already set, so don't go to client
                return;
            end

            actor.Dispatcher.dispatch(actor.Component, 'uipress', 'row', cell(1), 'col', cell(2), ...
                'cellType', cellType, 'cellEditing', editing, 'setting', cellData);
        end
    end

    methods(Access = private)
        function [cellData, isNoOp] = forLogicalCell(~, actor, cell, cellData)
            data = actor.getCellData(cell(1), cell(2));
            isNoOp = false;
            if isempty(cellData)
                % If cellData isn't provided by user and the cell is
                % editable then flip the logical data on the cell
                cellData = ~data;
            else
                % If cellData is provided ascertain if its a No-op or not
                % else use cellData to dispatch press on the checkbox
                validateattributes(cellData, {'logical'}, {'scalar'});
                if cellData == data
                    %value is already set, so don't go to client
                    isNoOp = true;
                end
            end
        end

        function [cellData, isNoOp] = forCategoricalCell(strategy, actor, cell, cellData)
            isNoOp = false;
            [data, index] = strategy.validateCategoricalInputForSingleCellStrategy(actor, cell, cellData);

            if index == strategy.getDropDownIndex(actor, data, cell(1), cell(2))
                %value is already set, so don't go to client
                isNoOp = true;
                return;
            end
            cellData = index;
            actor.prepareForCellEditing(cell);
        end

        function [cellData, isNoOp] = forPopupCell(strategy, actor, cell, cellData)
            cFData = actor.Component.ColumnFormat;
            cFData = string(cFData{1, cell(2)});
            index = find(cFData == cellData);
            isNoOp = false;

            if(isempty(index))
                error(message("MATLAB:uiautomation:Driver:UnknownPopupOptionSupplied"));
            end

            if index == strategy.getPopUpIndex(actor, cFData, cell(1), cell(2))
                %value is already set, so don't go to client
                isNoOp = true;
                return;
            end

            cellData = index;

            if (numel(cellData) > 1)
                % The popout accepts duplicate values. We will
                % pick the first one by default.
                cellData = cellData(1);
            end
            actor.prepareForCellEditing(cell);
        end

        function [data, index] = validateCategoricalInputForSingleCellStrategy(~, actor, cell, cellData)  
            import matlab.uiautomation.internal.SingleLineTextValidator;
            import matlab.uiautomation.internal.UISingleSelectionStrategy;

            data = actor.Component.Data;
            cellStrategy = UISingleSelectionStrategy(SingleLineTextValidator, categories(data{:,cell(2)}));
            index = cellStrategy.validate(cellData);
        end

        function validateSelectionModeForSingleCellStrategy(~, selectionMode)
            if strcmp(selectionMode, 'contiguous')
               error( message("MATLAB:uiautomation:Driver:UnsupportedSelectionModeForSingleCellStrategy"));
            end
        end

        function cellData = getColData(~, data, col)
            if istable(data) || iscell(data)
                cellData = data{:, col};
            else
                cellData = data(:, col);
            end
        end

        function index = getDropDownIndex(strategy, actor, data, row, col)
            currData = actor.getCellData(row, col);
            data = categories(strategy.getColData(data, col));
            index = find(data == currData);
        end

        function index = getPopUpIndex(~, actor, cFData, row, col)
            currData = actor.getCellData(row, col);
            index = find(cFData == currData);
        end

        function bool = isCellSelected(~, actor, cell)
            component = actor.Component;
            selection = component.Selection;
            selectionType = component.SelectionType;
            if isempty(selection)
                bool = false;
            else
                switch selectionType
                    case 'row'
                        bool = any(cell(1) == selection);
                    case 'column'
                        bool = any(cell(2) == selection);
                    otherwise
                        % If cell is already selected or among selected
                        % cells, then return true
                        bool = ismember(cell, selection, 'rows');
                end
            end
        end

        function bool = isSingleCellSelected(~, actor)
            component = actor.Component;
            selection = component.Selection;
            selectionType = component.SelectionType;
            bool = (selectionType == "cell" && isequal(size(selection), [1 2])) || isscalar(selection);
        end
    end
end
