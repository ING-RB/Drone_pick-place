classdef TableDataBrowser < matlab.ui.internal.databrowser.AbstractDataBrowser
    % Parent class for embedding a table-style data browser in your app.
    %
    % To use it, create a subclass and add it to AppContainer.
    %
    % Constructor:
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.TableDataBrowser">TableDataBrowser</a>    
    %
    % Properties:
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.CheckValidVarName">CheckValidVarName</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.GenerateValidVarName">GenerateValidVarName</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.Name">Name</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.NameColumnIndex">NameColumnIndex</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.SingleRowSelection">SingleRowSelection</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.Table">Table</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.Title">Title</a>    
    %
    % Public Methods:
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.addToAppContainer">addToAppContainer</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.positionFigureOnAppContainer">positionFigureOnAppContainer</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.setPreferredHeight">setPreferredHeight</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.AbstractDataBrowser.setPreferredWidth">setPreferredWidth</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.hilite">hilite</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.updateUI">updateUI</a>    
    %
    % Protected Methods:
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.CellEditCallback">CellEditCallback</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.DoubleClickCallback">DoubleClickCallback</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.RenameCallback">RenameCallback</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.SelectionCallback">SelectionCallback</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.buildUI">buildUI</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.cleanupUI">cleanupUI</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.connectUI">connnectUI</a>    
    %
    % Special methods for data/ui listener management:
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.registerDataListeners">registerDataListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.unregisterDataListeners">unregisterDataListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.enableDataListeners">enableDataListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.disableDataListeners">disableDataListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.registerUIListeners">registerUIListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.unregisterUIListeners">unregisterUIListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.enableUIListeners">enableUIListeners</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.base.AbstractUI.disableUIListeners">disableUIListeners</a>    
    %
    % Events:
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.CellEdited">CellEdited</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.DoubleClicked">DoubleClicked</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.Renamed">Renamed</a>    
    %   <a href="matlab:help matlab.ui.internal.databrowser.TableDataBrowser.SelectionChanged">SelectionChanged</a>    
    %
    % See also matlab.ui.internal.databrowser.AbstractDataBrowser, matlab.ui.internal.databrowser.PreviewPanel
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties
        % Property "CheckValidVarName": true/false (default = true)
        %
        %   Set it to true if you want to check whether user input in the
        %   Name column is a valid MATLAB variable name.  If the input is
        %   valid, "RenameCallback" will be triggered.  Otherwise, the
        %   action depends on the value in "GenerateValidVarName".
        %
        %   Set it to false if you want to accept any user input.  In this
        %   case, "RenameCallback" is always triggered and you can process
        %   user input there.
        %
        %   Example:
        %       this.CheckValidVarName = false;
        CheckValidVarName(1,1) logical = true
        % Property "GenerateValidVarName": true/false (default = true)
        %
        %   Set it to true if you want to automatically generate a valid
        %   MATLAB variable name from an invalid user input and replace it.
        %   "RenameCallback" will be triggered afterwards.
        %
        %   Set it to false if you want to accept the invalid user input.
        %   In this case, use "RenameCallback" to process it.
        %
        %   Example:
        %       this.GenerateValidVarName = false;
        GenerateValidVarName(1,1) logical = true
        % Property "NameColumnIndex": positive integer (default = 1)
        %
        %   It indicates which column is the Name column in the table.
        %
        %   Example:
        %       this.NameColumnIndex = 2;
        NameColumnIndex(1,1) double = 1
    end
    
    properties (Dependent)
        % Property "SingleRowSelection": true/false (default = true)
        %
        %   It indicates whether only one row can be selected at a time.
        %
        %   Set it to false when you want to allow multiple row selections.
        %
        %   Current selection can be obtained via "this.Table.Selection".
        %
        %   Example:
        %       this.SingleRowSelection = false;
         SingleRowSelection(1,1) logical
    end    
    
    properties (SetAccess = private)
        % Property "Table": handle to the uitable (read-only)
        %
        %   Use this property to customize desired table attributes.
        %
        %   Example:
        %       this.Table.ColumnEditable = [false true];
        %
        %   However, do not modify the following table callbacks:
        %       this.Table.CellSelectionCallback
        %       this.Table.CellEditCallback
        %   They are used by TableDataBrowser to ensure proper behavior.
        Table
    end
    
    properties (Access = private)
        HiliteTimer         % Timer to hilite data browser component
        HiliteState         % Highlight on/off state used by timer function
    end
    
    methods
        
        function val = get.SingleRowSelection(this)
            val = strcmp(this.Table.Multiselect,'off');
        end
        
        function set.SingleRowSelection(this, val)
            if val
                this.Table.Multiselect = 'off';
            else
                this.Table.Multiselect = 'on';
            end
        end
        
    end
    
    %% no-op callback methods to be overloaded in the subclass
    methods (Access = protected)
        
        function CellEditCallback(this, row, col, olddata, newdata)   %#ok<*INUSD>
            % Method "CellEditCallback": 
            %
            %   Overload this method to implement response when a non-name
            %   cell is changed in the table.
            %
            %       CellEditCallback(this, row, col, oldData, newData)
            %
            %   "row" and "col" indicates the location of the cell.
            %   "oldData" and "newData" are the values before and after.
            %
            %   Cell-editing action occurs when user clicks a non-name cell
            %   on a row that is already selected.  The callback is
            %   triggered when user finishes editing. 
            %
            %   Default behavior is no-op.
        end
        
        function DoubleClickCallback(this, row)  
            % Method "DoubleClickCallback": 
            %
            %   Overload this method to implement response when a row is
            %   double-clicked in the table. 
            %
            %       DoubleClickCallback(this, row)
            %
            %   "row" are the index of the double-clicked row (a scalar).
            %
            %   Douhble-clicking a row also selects the row.
            %
            %   Default behavior is no-op.
        end
        
        function RenameCallback(this,row,oldName,newName) 
            % Method "RenameCallback": 
            %
            %   Overload this method to implement response when a name is
            %   changed in the table.
            %
            %       RenameCallback(this,row,oldName,newName)
            %
            %   "row" is the index of the row hosting the name (a scalar).
            %   "oldName" and "newName" are the values before and after.
            %
            %   Renaming action occurs when user clicks the name cell on a
            %   row that is already selected.  The callback is triggered
            %   when user finishes renaming.
            %
            %   Use "CheckValidVarName" and "GenerateValidVarName" to
            %   check and correct invalid user input before the callback
            %   is triggered.
            %
            %   Default behavior is no-op.
        end
        
        function SelectionCallback(this, rows)
            % Method "SelectionCallback": 
            %
            %   Overload this method to implement response when a row or
            %   multiple rows are selected by a single-click in the table.
            %
            %       SelectionCallback(this, rows)
            %
            %   "rows" are the index/indices of the selected row/rows.
            %   When "SingleRowSelection" is true, "rows" is a scalar integer or [].
            %   When "SingleRowSelection" is false, "rows" is a vector of integers or [].
            %                        %
            %   Default behavior is no-op.
        end
        
    end
    
    events (Hidden)
        QE_Hilited
    end

    events (NotifyAccess = protected, ListenAccess = public)
        % Event "CellEdited": 
        %
        %   Event fires when cell edting occurs.  
        %   
        %   Two design patterns to handle response to cell edting:
        %   (1) "centralized": overload the "CellEditCallback" method.
        %   (2) "distributed": add listeners to the "CellEdited" event.
        %   Choose one that suits your app.
        CellEdited
        % Event "DoubleClicked": 
        %
        %   Event fires when double-clicking row occurs.  
        %   
        %   Two design patterns to handle response to double-clicking:
        %   (1) "centralized": overload the "DoubleClickCallback" method.
        %   (2) "distributed": add listeners to the "DoubleClicked" event.
        %   Choose one that suits your app.
        DoubleClicked
        % Event "Renamed": 
        %
        %   Event fires when renaming occurs.  
        %   
        %   Two design patterns to handle response to renaming:
        %   (1) "centralized": overload the "RenameCallback" method.
        %   (2) "distributed": add listeners to the "Renamed" event.
        %   Choose one that suits your app.
        Renamed
        % Event "SelectionChanged": 
        %
        %   Event fires when row selection occurs.  
        %   
        %   Two design patterns to handle response to row selection:
        %   (1) "centralized": overload the "SelectionCallback" method.
        %   (2) "distributed": add listeners to the "SelectionChanged" event.
        %   Choose one that suits your app.
        SelectionChanged
    end
    
    %% public methods
    methods
        
        %% constructor
        function this = TableDataBrowser(name, title)
            % Constructor "TableDataBrowser": 
            %
            %   Create a table-style data browser used in AppContainer.
            %
            %   In the constructor of your subclass, you must have
            %   
            %       this = this@matlab.ui.internal.databrowser.TableDataBrowser(name, title);
            %
            %   where "name" is the name of the object for reference and
            %   "title" is displayed in the app.
            this = this@matlab.ui.internal.databrowser.AbstractDataBrowser(name, title);
            % create uitable
            buildTable(this);
            % add callbacks to uitable
            connectTable(this);
        end
        
        %% destructor
        function delete(this)
            % Destructor "TableDataBrowser"
            
            % remove high light timer
            if ~isempty(this.HiliteTimer) && isvalid(this.HiliteTimer)
                if strcmp(this.HiliteTimer.Running,'on')
                    stop(this.HiliteTimer);
                end
                delete(this.HiliteTimer);
                this.HiliteTimer = [];
            end
        end
        
        %% hilite rows for 0.5 seconds 
        function hilite(this, varName)
            % Method "hilite": 
            %
            %   Briefly highlight one or more rows in the data browser.
            %
            %       hilite(this, varNames)
            %
            %   where "varNames" can a single variable name or a cell array
            %   of variable names.  
            %
            %       hilite(this, varIndices)
            %
            %   where "varIndices" are the indices of rows in the table.  
            
            if isempty(this.Table.Data)
                %Quick return, nothing to do
                return
            else
                data = this.Table.Data;
            end
            % get rows
            rows = [];
            if isnumeric(varName)
                rows = varName; 
            elseif ischar(varName)
                % single variable
                rows = find(strcmp(data(:,this.NameColumnIndex),varName)); 
            else
                % cell
                for ct=1:length(varName)
                    idx = find(strcmp(data(:,this.NameColumnIndex),varName{ct}));
                    if isempty(idx)
                        continue
                    else
                        rows = [rows; idx]; %#ok<*AGROW>
                    end
                end
            end
            if isempty(rows)
                %Variable not defined in this data browser component
                return
            end
            % Change the cell renderer background color
            % since we need to pass selected rows to timer function, the
            % value must be dynamic and thus we have to recreate timer
            if ~isempty(this.HiliteTimer)
                if strcmp(this.HiliteTimer.Running,'on')
                    return
                else
                    delete(this.HiliteTimer)
                end
            end
            this.HiliteTimer = timer(...
                'Name',           'HiliteTimer', ...
                'Period',         1, ...
                'ExecutionMode',  'fixedRate', ...
                'TasksToExecute', 2, ...
                'TimerFcn',       @(hSrc,hData) cbHilite(this, rows), ...
                'BusyMode',       'drop');
            % initial high light state is off
            this.HiliteState = false;
            start(this.HiliteTimer);
        end
        
    end
    
    methods(Access = private)
        
        function buildTable(this)
            % use 1x1 uigridlayout for auto-resizing
            g = uigridlayout(this.Figure);
            g.ColumnWidth = {'1x'};
            g.RowHeight = {'1x'};
            g.Padding = [0 0 0 0];
            % table
            tbl = uitable(g);
            tbl.Tag = strcat('dbtable_',this.Name);
            % default settings
            tbl.SelectionType = 'row';  % row selection
            tbl.Multiselect = 'off';    % default to single row selection
            tbl.RowName = '';           % do not show row number
            tbl.ColumnName = {};        % do not show column name
            tbl.ColumnEditable = true;  % column is editable
            tbl.RowStriping = 'off';
            % save the handle
            this.Table = tbl;
        end
        
        function connectTable(this)
            % double selection (TBD)
            this.Table.CellDoubleClickedFcn = @(src,data) cbDoubleClicked(this,src,data);
            % single selection
            this.Table.CellSelectionCallback = @(src,data) cbSelectionChanged(this,src,data);
            % renaming and cell editing
            this.Table.CellEditCallback = @(src,data) cbTableChanged(this,src,data);
        end
        
        %% table double-clicked callback
        function cbDoubleClicked(this,~,eventdata)
            % get row selections
            row = unique(eventdata.Index(1));
            % fire callback
            DoubleClickCallback(this,row);
            % fire event
            sData = struct('Row',row);
            CustomEventData = matlab.ui.internal.databrowser.GenericEventData(sData);
            notify(this,'DoubleClicked',CustomEventData)
        end
        
        %% table selection callback
        function cbSelectionChanged(this,~,eventdata)
            % get row selections
            rows = unique(eventdata.Indices(:,1));
            % fire callback
            SelectionCallback(this,rows);
            % fire event
            sData = struct('Rows',rows);
            CustomEventData = matlab.ui.internal.databrowser.GenericEventData(sData);
            notify(this,'SelectionChanged',CustomEventData)
        end
        
        %% table cell edited callback
        function cbTableChanged(this,~,eventdata)
            row = eventdata.Indices(1);
            col = eventdata.Indices(2);
            % cell edited
            if col~=this.NameColumnIndex
                % fire callback 
                CellEditCallback(this,eventdata.Indices(1),eventdata.Indices(2),eventdata.PreviousData,eventdata.NewData);
                % fire event
                CustomEventData = matlab.ui.internal.databrowser.GenericEventData(eventdata);
                notify(this,'CellEdited',CustomEventData)
            % cell renamed
            else
                oldName = eventdata.PreviousData;
                newName = eventdata.NewData;
                % From UI, table.data{row} is already updated with new
                % name.  It will be reverted by below if necessary 
                [newName, successful] = validateName(this, oldName, newName, row);
                if successful
                    RenameCallback(this, row, oldName, newName);
                    % fire event
                    if isempty(row)
                        sData = [];
                    else
                        sData = struct('Row',row,'OldName',oldName,'NewName',newName);
                    end
                    CustomEventData = matlab.ui.internal.databrowser.GenericEventData(sData);
                    notify(this,'Renamed',CustomEventData)
                end
            end
        end
        
        %% hilite timer callback
        function cbHilite(this, rows)
            %Helper to change cell background color
            s1 = matlab.ui.style.internal.SemanticStyle('Fontcolor','--mw-color-primary');
            s2 = matlab.ui.style.internal.SemanticStyle('BackgroundColor','--mw-backgroundColor-searchHighlight-tertiary');
            if this.HiliteState
                % turn it off
                removeStyle(this.Table);
            else
                % turn it on (orange)
                addStyle(this.Table,s1,'row',rows);
                addStyle(this.Table,s2,'row',rows);
                this.notify('QE_Hilited');
            end
            this.HiliteState = ~this.HiliteState;
        end
        
        %% utility: 
        function [newname, successful] = validateName(this, oldname, newname, row)
            % Update Table.Data only if the value needs to be changed
            %   Scenario 1: revert back to oldname when newname is invalid
            %   Scenario 2: use auto-generated new valid and unique name 
            successful = true;
            if this.CheckValidVarName            
                if isvarname(newname)
                    name1 = newname;
                else
                    if this.GenerateValidVarName
                        name1 = matlab.lang.makeValidName(newname);
                    else
                        % revert if the new name is not a valid name and
                        % GenerateValidVarName is false
                        this.Table.Data{row,this.NameColumnIndex} = oldname;
                        successful = false;
                        msg = getString(message('MATLAB:ui:databrowser:RenameFailed',oldname,newname));
                        title = getString(message('MATLAB:ui:databrowser:RenameFailedTitle'));
                        uiconfirm(this.AppContainer,msg,title,'Options',{'OK'},'Icon','error');
                        newname = oldname;
                        return
                    end
                end
                % make sure it is unique
                exclusion = this.Table.Data(:,this.NameColumnIndex);
                exclusion(row) = [];
                name2 = matlab.lang.makeUniqueStrings(name1, exclusion);
                % enforce a unique name 
                if ~strcmp(name2,newname)
                    newname = name2;
                    this.Table.Data{row,this.NameColumnIndex} = name2;
                end
            end
        end        
        
    end
    
    %% hidden QE methods
    methods (Hidden)

        function qeRename(this, row, newName)
            % Method "qeRename": 
            %
            %   This is a hidden method for QE to mimic "rename" action
            %   occurring in the data browser UI.
            %
            %       qeRename(this, row, col, newname)
            %
            %   "row" and "col" indicates the location of the cell that
            %   renaming occurs.  "newname" is the new name.
            %
            % Do not use this method for development work.
            oldName = this.Table.Data(row,this.NameColumnIndex);
            % validate new name depends on settings
            [finalName, successful] = validateName(this, oldName{1}, newName, row);
            % From QE method, table.data{row} is not updated yet if newName
            % is valid.  Need to manually update table here.
            if strcmp(finalName, newName)
                this.Table.Data{row,this.NameColumnIndex} = newName;
            end
            % run callback
            if successful
                RenameCallback(this, row, oldName{1}, finalName);
                if isempty(row)
                    sData = [];
                else
                    sData = struct('Row',row,'OldName',oldName{1},'NewName',finalName);
                end
                CustomEventData = matlab.ui.internal.databrowser.GenericEventData(sData);
                notify(this,'Renamed',CustomEventData)
            end
        end
        
        function qeSelect(this, rows)
            % Method "qeSelect": 
            %
            %   This is a hidden method for QE to mimic "select" action
            %   occurring in the data browser UI.
            %
            %       qeSelect(this, rows)
            %
            %   "rows" indicates which row(s) is selected.  If
            %   "SingleRowSelection" is true, "rows" should be a scalar.
            %   Use "rows = []" to select none (i.e. de-select row).
            %
            % Do not use this method for development work.
            this.Table.Selection = rows;
            SelectionCallback(this, rows);
            % send event
            sData = struct('Rows',rows);
            CustomEventData = matlab.ui.internal.databrowser.GenericEventData(sData);
            notify(this,'SelectionChanged',CustomEventData)
        end
        
        function qeDoubleClick(this, row)
            % Method "qeDoubleClick": 
            %
            %   This is a hidden method for QE to mimic the "double-click"
            %   action occurring in the data browser UI.
            %
            %       qeDoubleClick(this, row)
            %
            %   "row" indicates which row is double-clicked.
            %
            % Do not use this method for development work.
            this.Table.Selection = row;
            DoubleClickCallback(this, row);
            % send event
            sData = struct('Row',row);
            CustomEventData = matlab.ui.internal.databrowser.GenericEventData(sData);
            notify(this,'DoubleClicked',CustomEventData)
        end
        
        function qeEdit(this, row, col, data)
            % Method "qeEdit": 
            %
            %   This is a hidden method for QE to mimic the "cell edit"
            %   action occurring in the data browser UI.
            %
            %       qeEdit(this, row, col, data)
            %
            %   "row" and "col" indicates which cell is being edited.
            %   "data" is the new data put into the cell.
            %
            % Do not use this method for development work.
            olddata = this.Table.Data{row,col};
            % mimic cell edited
            this.Table.Data{row,col} = data;
            % call callback
            CellEditCallback(this,row,col,olddata,data);
            % send event
            sData = struct('Indices', [row col],...
                    'DisplayIndices', [row col],...
                    'PreviousData', olddata,...
                    'EditData', data,...
                    'NewData', data,...
                    'Error', [],...
                    'Source', this.Table,...
                    'EventName', 'CellEdit');
            CustomEventData = matlab.ui.internal.databrowser.GenericEventData(sData);
            notify(this,'CellEdited',CustomEventData)
        end
        
        function qeRightClick(this, cellidx, itemtag)
            % Method "qeRightClick": 
            %
            %   This is a hidden method for QE to mimic the "right click
            %   and select a context menu item" occurring in the data
            %   browser UI.
            %
            %       qeRightClick(this, cellidx, itemtag)
            %
            %   "cellidx" indicates which cell is being right-clicked. 
            %       right-click a single cell, cellidx should be [row col]
            %       right-click white space, cellidx should be []
            %
            %   "itemtag" is the Tag of "uimenu" being clicked.
            %       "qeRightClick" will error out if this menu item is not visible.
            %
            %   To use this method in test, you must do the following in the product code:
            %       "uimenu" must have a unique tag.
            %       "uimenu" callback function must be a method of your TableDataBrowser subclass.
            %
            % Do not use this method for development work.
            data = matlab.ui.internal.databrowser.qeContextMenuEventData(this.Table, cellidx);
            this.Table.ContextMenu.notify('ContextMenuOpening',data);
            for ct=1:length(this.Table.ContextMenu.Children)
                if strcmpi(this.Table.ContextMenu.Children(ct).Tag, itemtag)
                    item = this.Table.ContextMenu.Children(ct);
                    if item.Visible
                        internal.Callback.execute(item.MenuSelectedFcn, item);
                    else
                        error('item does not exist')
                    end
                    break;
                end
            end
        end
        
    end
    
end


