classdef GroupingVariableSectionGC < handle
    %
    
    % Copyright 2016-2016 The MathWorks, Inc.
    
    properties (Access = private)
        PlotMatrixUITC
        Widgets
        Panel
    end
    
    methods (Access = protected)
        function cbCellEdit(this, hTable, eventData)
            try
                if ~isempty(eventData.Indices)
                    switch eventData.Indices(2)
                        case 2
                            % Grouping variable label
                            setGroupingVariableLabel(this.PlotMatrixUITC, hTable.Data{eventData.Indices(1),1}, eventData.NewData);
                        case 4
                            % Grouping variable style
                            setGroupingVariableStyle(this.PlotMatrixUITC, hTable.Data{eventData.Indices(1),1}, eventData.NewData);
                            this.PlotMatrixUITC.SelectedGroupingVariable = hTable.Data{eventData.Indices(1),1};
                        case 5
                            % Show grouping variable
                            setShowGroupingVariable(this.PlotMatrixUITC, hTable.Data{eventData.Indices(1),1}, eventData.NewData);
                    end
                end
            catch ME
                hErr = errordlg(ME.message,getString(message('Controllib:plotmatrix:strGroupingVariable')),'modal');
                centerfig(hErr,this.Panel.Parent);
                uiwait(hErr);
                updateUI(this);
            end
        end
        
        function cbCellSelect(this, hTable, eventData)
            try
                if ~isempty(eventData.Indices)
                    if eventData.Indices(2)==6
                        % delete grouping variable
                        VariableBeingDeleted = hTable.Data{eventData.Indices(1),1};
                        deleteGroupingVariable(this.PlotMatrixUITC, VariableBeingDeleted);
                        updateUI(this);
                        if strcmpi(VariableBeingDeleted,getSelectedGroupingVariable(this.PlotMatrixUITC))
                            if isempty(getProperty(this.PlotMatrixUITC,'GroupingVariable'))
                                % No grouping variables left
                                this.PlotMatrixUITC.SelectedGroupingVariable = [];
                            elseif size(hTable.Data,1)>=eventData.Indices(1)
                                this.PlotMatrixUITC.SelectedGroupingVariable = hTable.Data{eventData.Indices(1),1};
                            else
                                this.PlotMatrixUITC.SelectedGroupingVariable = hTable.Data{eventData.Indices(1)-1,1};
                            end
                        end
                    else
                        % Grouping variable selection changed
                        if isempty(this.PlotMatrixUITC.SelectedGroupingVariable) || ~strcmpi(this.PlotMatrixUITC.SelectedGroupingVariable,hTable.Data{eventData.Indices(1),1})
                            this.PlotMatrixUITC.SelectedGroupingVariable = hTable.Data{eventData.Indices(1),1};
                        end
                    end
                end
            catch ME
                hErr = errordlg(ME.message,getString(message('Controllib:plotmatrix:strGroupingVariable')),'modal');
                centerfig(hErr,this.Panel.Parent);
                uiwait(hErr);
                updateUI(this);
            end
        end
        
        function cbComboEdit(this, hCombo, ~)
            try
                if hCombo.Value==1
                    items = getGroupingVariableList(this.PlotMatrixUITC);
                    [Selection,OK] = listdlg('ListString',items,'Name',getString(message('Controllib:plotmatrix:strGroupingVariable')));
                    if OK
                        for ct=1:numel(Selection)
                            createGroupingVariable(this.PlotMatrixUITC,items{Selection(ct)});
                        end
                    end
                    updateUI(this);
                else
                    GroupingVariable = hCombo.String{hCombo.Value};
                    createGroupingVariable(this.PlotMatrixUITC,GroupingVariable);
                    updateUI(this);
                end
                this.PlotMatrixUITC.SelectedGroupingVariable = this.Widgets.GroupingVariableTable.Data{end,1};
                hCombo.Value = 1;
            catch ME
                hErr = errordlg(ME.message,getString(message('Controllib:plotmatrix:strGroupingVariable')),'modal');
                centerfig(hErr,this.Panel.Parent);
                uiwait(hErr);
                updateUI(this);
                hCombo.Value = 1;
            end
        end
    end
    
    methods
        function this = GroupingVariableSectionGC(tc)
            this.PlotMatrixUITC = tc;
        end
                  
        function updateUI(this)
            % Call update when TC changes
            
            % Grouping variable uitable
            if isempty(getProperty(this.PlotMatrixUITC,'GroupingVariable'))
                this.Widgets.GroupingVariableTable.Parent = [];
            else
                this.Widgets.GroupingVariableTable.Parent = this.Panel;
                Data = getGroupingVariableData(this.PlotMatrixUITC);
                [nr,~] = size(Data);
                removecolumn = cell(nr,1);
                for ct=1:nr
                    removecolumn{ct} = icongen;
                end
                Data = [Data, removecolumn];
                this.Widgets.GroupingVariableTable.Data = Data;
            end
            % Available Grouping Variable combo-box
            items = getGroupingVariableList(this.PlotMatrixUITC);
            if isempty(items)
                this.Widgets.GroupingVariablePopUp.Enable = 'off';
            else
                this.Widgets.GroupingVariablePopUp.Enable = 'on';
            end
            items = [{getString(message('Controllib:plotmatrix:strCreateGroupingVariable'))} items]';
            set(this.Widgets.GroupingVariablePopUp, 'value',1);
            set(this.Widgets.GroupingVariablePopUp, 'String',items);
        end
           
        function positionWidgets(this)
            % Position for widgets
            wPad = 10;
            xGap = 10;
            hPad = 10;
            
            % Grouping variable label position
            x1 = wPad;
            y1 = hPad;
            w1 = this.Panel.Position(3)-2*wPad;
            h1 = this.Panel.Position(4)-2*hPad;
            this.Widgets.CreateGroupingVariableLabel.Position = [x1 y1 w1 h1];
            
            w1 = this.Widgets.CreateGroupingVariableLabel.Extent(3);
            this.Widgets.CreateGroupingVariableLabel.Position(3) = w1;
            
            h1 = this.Widgets.CreateGroupingVariableLabel.Extent(4);
            this.Widgets.CreateGroupingVariableLabel.Position(4) = h1;
            
            this.Widgets.GroupingVariablePopUp.Position = [x1+w1+xGap y1+2 175 h1];
                                    
            h1 = this.Widgets.GroupingVariablePopUp.Extent(4);
            this.Widgets.GroupingVariablePopUp.Position(4) = h1;
            
            % Grouping variable table position
            x1 = wPad;                                % x-position for widgets at left
            y1 = y1+h1+hPad+2;
            w1 = this.Panel.Position(3)-2*wPad;
            h1 = this.Panel.Position(4)- y1 - 2*hPad;
            this.Widgets.GroupingVariableTable.Position = [x1  y1 w1 h1];
            this.Widgets.GroupingVariableTable.ColumnWidth = {120 'auto' 'auto' 85 'auto' 'auto'};
        end
        
        function pnl = createPanel(this)
            % Build all the graphical components
            pnl = uipanel('Parent',[],'Title',getString(message('Controllib:plotmatrix:strGroupingVariable')),'FontSize',12,'Units','points');
            
            this.Panel = pnl;
            %% Create Grouping Variable Label-Combo
            this.Widgets.CreateGroupingVariableLabel = uicontrol(pnl, ...
                'Tag',                  'CreateGroupingVariableLabel', ...
                'Style',                'text', ...
                'HorizontalAlignment',  'left', ...
                'String',               sprintf('%s: ', getString(message('Controllib:plotmatrix:strCreateGroupingVariable'))),...
                'Units',                'points');
               
            this.Widgets.GroupingVariablePopUp = uicontrol(pnl, ...
                'String',               sprintf('%s ...', getString(message('Controllib:plotmatrix:strCreateGroupingVariable'))),...
                'Tag',                  'GroupingVariablePopUp', ...
                'Style',                'popupMenu', ...
                'HorizontalAlignment',  'left', ...
                'Units',                'points', ...
                'Callback',             @(hCombo, eventData)cbComboEdit(this, hCombo, eventData));
            %% Table
            StyleList = getAllStyles(this.PlotMatrixUITC);
            columnnames = {getString(message('Controllib:plotmatrix:strGroupingVariable')), ...
                getString(message('Controllib:plotmatrix:strLabel')),...
                getString(message('Controllib:plotmatrix:strType')),...
                getString(message('Controllib:plotmatrix:strStyle')),...
                getString(message('Controllib:plotmatrix:strActive')),...
                getString(message('Controllib:plotmatrix:strRemove'))};
            columnformat = {'char','char','char',StyleList,'logical','char'};
            columneditable = [false true false true true false];

            this.Widgets.GroupingVariableTable = uitable(pnl, ...
                'Units',                   'points',...
                'ColumnName',              columnnames, ...
                'ColumnFormat',            columnformat, ...
                'ColumnEditable',          columneditable, ...
                'RowName',                 {}, ...
                'RowStriping',             'off', ...
                'Visible',                 'on',...
                'CellEditCallback',         @(hTable, eventData) cbCellEdit(this, hTable, eventData),...
                'CellSelectionCallback',    @(hTable, eventData) cbCellSelect(this, hTable, eventData));
        end
    end
    
    %% Testing methods
    methods (Hidden = true)
        function wdgts = qeGetWidgets(this)
            wdgts = this.Widgets;
            wdgts.Panel = this.Panel;
        end
    end
end

function icon = icongen
pic = matlab.ui.internal.toolstrip.Icon.CLEAR_16;
icon = ['<HTML><IMG  align="middle" SRC="file:/',pic.Description,'"></HTML>'];
end
