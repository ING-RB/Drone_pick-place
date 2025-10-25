classdef TableInteractor < matlab.uiautomation.internal.interactors.AbstractComponentInteractor
    % This class is undocumented and subject to change in a future release
    
    %   choose(uit, index) - To choose a particular cell in the table
    %   component, specify the cell index as a 1-by-2 array along with the
    %   table component handle. The ColumnEditable property corresponding
    %   to the cell column must be set to false.
    %
    %   choose(uit, index, setting) - To edit a particular cell in the
    %   table component, specify the setting in addition to the cell index.
    %   The setting option must be compatible with the corresponding column
    %   data type. The ColumEditable property of the cell column must be
    %   set to true.
    %
    %   choose(uit, indices, 'SelectionMode', mode) - To select multiple
    %   cells in the table component, specify the cell indices as an N-by-2
    %   array along with an optional SelectionMode name-value pair
    %   arguement. SelectionMode can be specified as 'contiguous' or
    %   discontiguous'. If SelectionMode is not specified, the framework
    %   will default to a discontiguous selection mode.
    %
    %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   % Examples
    %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   Usage 1: Choose an uneditable table cell
    %
    %   f = uifigure;
    %   uit = uitable(f);
    %   d = {'Male',52,true;'Male',40,true;'Female',25,false};
    %   uit.Data = d;
    %   testCase = matlab.uitest.TestCase.forInteractiveUse;
    %   testCase.choose(uit, [1 1])
    %
    %   Usage 2: Edit checkbox cell to set a "true" value
    %
    %   %Set the columnEditable property of uitable to true
    %   uit.ColumnEditable = true;
    %   testCase.choose(uit, [3, 1], true);
    %
    %   Usage 3: Type a numeric value of 50 into the cell [1 2]
    %
    %   uit.ColumnEditable = true;
    %   testCase.type(uit, [1 2], 50);
    %
    %   Usage 4: Select all the cells between cells indices [1 1] and
    %   [3 3]
    %
    %   uitable(uifigure, 'Data', magic(5));
    %   testCase.choose(uit, [1 1; 3 3], 'SelectionMode', 'contiguous');
    %
    %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   press(uit, HeaderType, num) - To press on a header of the table
    %   component, specify the header type and the column index as a name value pair
    %   along with the table component handle. HeaderType can be either
    %   "RowHeader" or "ColumnHeader".
    %
    %   press(uit, 'ColumnToSort', num) - To press on a header of the table
    %   component to sort column data, specify the "ColumnToSort" and the column index
    %   as a name value pair along with the table component handle. The ColumSortable
    %   property of the column must be set to true.
    %
    %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   % Examples
    %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   Usage 1: Press to select a table column
    %
    %   f = uifigure;
    %   uit = uitable(f, 'Data',  magic(4));
    %   testCase = matlab.uitest.TestCase.forInteractiveUse;
    %   testCase.press(uit, 'ColumnHeader', 1)
    %
    %   Usage 2: Press to select a table row
    %
    %   f = uifigure;
    %   uit = uitable(f, 'Data', magic(4));
    %   testCase = matlab.uitest.TestCase.forInteractiveUse;
    %   testCase.press(uit, 'RowHeader', 1)
    %
    %   Usage 3: Sort a table column
    %
    %   f = uifigure;
    %   uit = uitable(f, 'Data', magic(4), 'ColumnSortable', true);
    %   testCase = matlab.uitest.TestCase.forInteractiveUse;
    %   testCase.press(uit, 'ColumnToSort', 1)
    %
    %
    %   See also uitable
    
    % Copyright 2019-2023 The MathWorks, Inc.
    
    methods
        
        function uichoose(actor, cells , varargin)
            arguments
                actor
                cells {mustBeNumeric, validateExactSize}
            end
            arguments(Repeating)
                varargin
            end
            
            import matlab.uiautomation.internal.CellSelectionStrategy;
            
            strategy = CellSelectionStrategy.fromCells(cells);
            strategy.select(actor, cells, varargin{:});
            
        end
        
        function uitype(actor, pos, value)
            arguments
                actor
                pos {validateCellIndicialArguments(actor, pos)}
                value {validateString}
            end
            
            if ~isEditable(actor, pos)
                error( message("MATLAB:uiautomation:Driver:UnEditableTableCell") );
            end
            
            cellType = getCellType(actor, pos(1), pos(2));
            nonTypableDataTypes = ["categorical", "logical"];
            
            if any(cellType == nonTypableDataTypes)
                error( message('MATLAB:uiautomation:Driver:UntypableTableCell') );
            end
            
            text = string(value);
            
            actor.prepareForCellEditing(pos);
            
            % type
            actor.Dispatcher.dispatch(actor.Component, 'uitype', 'row', pos(1), 'col', pos(2), ...
                'Text', text, 'cellType', cellType);
        end
        
        function uicontextmenu(actor, menu, area)
            arguments
                actor
                menu (1,1) matlab.ui.container.Menu {validateParent}
                area (1,:) {validateAreaForContextmenu(actor, area)}
            end

            component = actor.Component;

            if(ischar(area) || isstring(area))
                % Contextmenu can be opened on a Blank area even when data
                % is empty, so, isDataPresent tells us whether table has
                % data or not
                args = struct('Area', area, 'isDataPresent', ~isempty(component.Data));
                actor.Dispatcher.dispatch(component, 'uicontextmenu', args);
            else
                actor.Dispatcher.dispatch(component, 'uicontextmenu', 'row', area(1), 'col', area(2));
            end
            
            actor.pressMenu(menu);
        end
        
        function uipress (actor, options)

            arguments
                actor;
                options.RowHeader (1,1) {mustBeNumeric, mustBePositive, mustBeInteger, validateRowOrColumnNum(actor, 'RowHeader', options.RowHeader)}
                options.ColumnHeader (1,1) {mustBeNumeric, mustBePositive, mustBeInteger, validateRowOrColumnNum(actor, 'ColumnHeader', options.ColumnHeader)}
                options.ColumnToSort (1,1) {mustBeNumeric, mustBePositive, mustBeInteger, validateRowOrColumnNum(actor, 'ColumnToSort', options.ColumnToSort)}
            end

            narginchk(3,3);

            component = actor.Component;
            [option, num] = chooseOption(options);

            if option == "ColumnToSort" && ~isColumnSortable(component, num)
                error( message('MATLAB:uiautomation:Driver:ColumnNotSortable') );
            end
            actor.Dispatcher.dispatch(component, 'uipress', option, true, 'RowOrColumnNumber', num, 'Header', true);
        end
                
        function uidoublepress(actor, pos)
            arguments
                actor
                pos {validateCellIndicialArguments(actor, pos)}
            end
            
            %toggle columneditable off to make the gestures robust
            cache = actor.Component.ColumnEditable;
            actor.Component.ColumnEditable = false;
            p = onCleanup(@()resetColumnEditable(actor.Component, cache));
            
            actor.Dispatcher.dispatch(actor.Component, 'uidoublepress', 'row', pos(1), 'col', pos(2));
            
            function resetColumnEditable(component, cache)
                component.ColumnEditable = cache;
            end
        end
    end
    
    methods(Access=?matlab.uiautomation.internal.CellSelectionStrategy)
        
        function validateCellIndicialArguments(actor, pos)
            validateattributes(pos, {'numeric'}, ...
                {'row', 'integer', 'nonnegative', 'nonzero', 'size', [1 2]});
            
            tableSize = size(actor.Component.Data);
            if pos(1) > tableSize(1) || pos(2) > tableSize(2)
                error( message('MATLAB:uiautomation:Driver:InvalidTableCell') );
            end
        end

        function validateAreaForContextmenu(actor, area)
            if(ischar(area) || isstring(area))
                mustBeTextScalar(area);
                mustBeMember(area, {'blank-area', 'row-header', 'col-header'});
                % If Data is empty, the Row and Column headers don't show up
                if isempty(actor.Component.Data) && ismember(area, {'row-header', 'col-header'})
                    error(message('MATLAB:uiautomation:Driver:NoHeaderFound'));
                end
                return;
            end

            % Validate for cell indices
            validateCellIndicialArguments(actor, area);
        end
        
        function prepareForCellEditing(actor, pos)
            
            % press to bring the cell to "editable" state
            actor.Dispatcher.dispatch(actor.Component, 'uipress', 'row', pos(1), 'col', pos(2), 'focus', true);
            actor.Dispatcher.dispatch(actor.Component, 'uipress', 'row', pos(1), 'col', pos(2));
            
        end
        
        function cellType = getCellType(actor, row, col)
            cf = actor.Component.ColumnFormat;
            if isColumnFormatSpecified(cf, col) 
                if iscell(cf{1, col})
                    % if ColumnFormat is supplied as a 1-by-n vector then
                    % set cellType to be popupmenu
                    cellType = 'popup';
                else
                    cellType = cf{1, col};
                end
            else
                cellData = getCellData(actor, row, col);
                cellType = class(cellData);
            end
        end

        function value = getCellData(actor, row, col)
            
            data = actor.Component.Data;
            
            % Table data
            if istable(data)
                
                if iscell(data.(col))
                    value = data.(col){row};
                else
                    value = data.(col)(row);
                end
                % Non-table data
                % No multicolumn variables allowed in non-table data, so use
                % row and column for indexing
            elseif iscell(data)
                % For non-table data, cell arrays can only contain a mix of
                % numeric, logical, and char values.
                value = data{row, col};
            else
                value = data(row, col);
            end
        end
        
        function bool = isEditable(actor, pos)
            % Basic Rules:
            % - Style Configuration takes a higher priority than
            % uitable.ColumnEditable if there is a conflict
            % - The last added Style takes a higer priority than
            % former added ones
            
            hTable = actor.Component;

            %% Check if cell is editable via style configurations
            % Logic:
            % - Get table with Style equals to Editable
            % - Loop from last item to the first to see if there is any
            %   Configuration target covered the target cell, could be "table" level
            %   "row" level, "column" level or "cell" level
            % - set bool to logical value accordingly, if there is confiugration target
            %   covered the target cell, then return (Rule #2 & #1)
            sc = hTable.StyleConfigurations;
            styleEditableTable = sc(isprop(sc.Style, "Editable"), :);
            if ~isempty(styleEditableTable)
                for index = height(styleEditableTable):-1:1
                    data = styleEditableTable(index, :);
                    if data.Target == "table" || ...
                       (data.Target == "row" && any(ismember(data.TargetIndex{1}, pos(1)))) || ...
                       (data.Target == "column" && any(ismember(data.TargetIndex{1}, pos(2)))) || ...
                       (data.Target == "cell" && any(ismember(data.TargetIndex{1}, pos, 'rows')))
                        bool = data.Style.Editable == "on";
                        return;
                    end
                end
            end
            
            %% Check if target cell is Editable via uitable.ColumnEditable, if no style configuration above covers the target cell 
            value = hTable.ColumnEditable;

            % ColumnEditable is empty
            if isempty(value) 
                bool = false;
                return
            end
            
            % ColumnEditable has one value (apply to all column by default)
            if isscalar(value)
                bool = value;
                return
            end
            
            % ColumnEditable is a vector
            if isvector(value)
                numColumns = size(hTable.Data, 2);
                mask = false(1, numColumns);
                mask(1:size(value, 2)) =  value;
                bool = mask(pos(2));
            end
        
        end

        function validateRowOrColumnNum(actor, option, num)
            hTable = actor.Component;
            if(isequal(option, 'RowHeader'))
               totalNum = height(hTable.Data);
            else
               totalNum = width(hTable.Data);
            end
            if(num > totalNum)
                error( message('MATLAB:uiautomation:Driver:InvalidTableHeader') );
            end
        end
    end

    methods
        function pressMenu(~, menu)
            menuInteractor = matlab.uiautomation.internal.InteractorFactory.getInteractorForHandle(menu);
            menuInteractor.uipress();
        end
    end
end        

function bool = isColumnFormatSpecified(cf, col)
    % This method helps find if a ColumnFormat has been specified
    % to a given column in a uitable
    if(isempty(cf))
        bool = false;
        return;
    end

    bool = numel(cf) >= col && ~isempty(cf{1, col});
end

function bool = isColumnSortable(hTable, col)
    %% Check if target column is Sortable via uitable.ColumnSortable
    value = hTable.ColumnSortable;

    % ColumnSortable is empty
    if isempty(value) 
        bool = false;
        return
    end

    % ColumnSortable has one value (apply to all column by default)
    if isscalar(value)
        bool = value;
        return
    end

    % ColumnSortable is a vector
    if isvector(value)
        numColumns = size(hTable.Data, 2);
        mask = false(1, numColumns);
        mask(1:size(value, 2)) =  value;
        bool = mask(col);
    end
end

function [key, num] = chooseOption(options)
    fields = fieldnames(options);
    key = fields{1};
    num = options.(key);
end

function validateString(value)
validateattributes(value, {'char', 'string'}, {'scalartext'});
end

function validateParent(menu)
if isempty(ancestor(menu, 'matlab.ui.container.ContextMenu'))
    error(message('MATLAB:uiautomation:Driver:InvalidContextMenuOption'));
end
end

function validateExactSize(cells)
validateattributes(cells, {'numeric'}, {'size', [NaN 2]});
end
