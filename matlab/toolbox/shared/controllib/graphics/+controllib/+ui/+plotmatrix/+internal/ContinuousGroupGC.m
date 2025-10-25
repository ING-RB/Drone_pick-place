classdef ContinuousGroupGC < controllib.ui.plotmatrix.internal.CategoricalGroupGC
    %
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    methods (Access = public)
        function pnl = createPanel(this)
            % Build all the graphical components
            
            % panel
            pnl = uipanel('Parent',[],'FontSize',12,'Units','points');
            this.Panel = pnl;
            
            % UILabel
            this.Widgets.NotificationLabel = uicontrol(pnl,'Style','text',...
                'String', getString(message('Controllib:plotmatrix:strSelectGroupVariable')));
            
            % add group label
            this.Widgets.AddGroupLabel = uicontrol(pnl, ...
                'Tag',                  'AddGroupLabel', ...
                'Style',                'text', ...
                'HorizontalAlignment',  'left', ...
                'String',               sprintf('%s: ', getString(message('Controllib:plotmatrix:strNewBinValue'))),...
                'Units',                'points');
            
            % add group text
            this.Widgets.AddGroupText = uicontrol(pnl, ...
                'Tag',                  'AddGroupText', ...
                'Style',                'edit', ...
                'HorizontalAlignment',  'left', ...
                'Units',                'points');
            
            % add group button
            this.Widgets.AddGroupsButton = uicontrol(pnl,...
                'Tag',                  'AddGroup', ...
                'Style',                'pushbutton',...
                'String',               sprintf('%s', getString(message('Controllib:plotmatrix:strAddGroup'))),...
                'HorizontalAlignment',  'left', ...
                'Units',                'points', ...
                'Callback',             @(hCombo, eventData)cbComboEdit(this,hCombo,eventData));
            
            % Table
            this.Widgets.ContinuousGroupTable = uitable(pnl, ...
                'Units',                   'points',...
                'RowName',                 {}, ...
                'RowStriping',             'off', ...
                'Visible',                 'on',...
                'CellEditCallback',         @(hTable, eventData) cbCellEdit(this, hTable, eventData),...
                'CellSelectionCallback',    @(hTable, eventData) cbCellSelect(this, hTable, eventData));
            this.Widgets.ContinuousGroupTable.ColumnWidth = {'auto' 'auto' 'auto' 'auto' 'auto'};
        end
        
        function positionWidgets(this)
            wPad = 10;
            xGap = 10;
            hPad = 10;
            
            % group button label
            x1 = wPad;
            y1 = hPad;
            w1 = this.Panel.Position(3)-2*wPad;
            h1 = this.Panel.Position(4)-2*hPad;
            this.Widgets.AddGroupLabel.Position = [x1 y1 w1 h1];
            w1 = this.Widgets.AddGroupLabel.Extent(3);
            this.Widgets.AddGroupLabel.Position(3) = w1;
            h1 = this.Widgets.AddGroupLabel.Extent(4);
            this.Widgets.AddGroupLabel.Position(4) = h1;
            
            % add group text
            this.Widgets.AddGroupText.Position = [x1+w1 y1+2 175 h1];
            this.Widgets.AddGroupText.Position(3) = 40;
            
            % add group button
            this.Widgets.AddGroupsButton.Position = [x1+w1+this.Widgets.AddGroupText.Position(3)+xGap y1+2 w1 h1];
            w1 = this.Widgets.AddGroupsButton.Extent(3);
            this.Widgets.AddGroupsButton.Position(3) = w1;
            
            % table
            x1 = wPad;
            y1 = y1+h1+hPad+2;
            w1 = this.Panel.Position(3)-2*wPad;
            h1 = this.Panel.Position(4)- y1 - 2*hPad;
            this.Widgets.ContinuousGroupTable.Position = [x1 y1 w1 h1];
            
            % Notification msg
            this.Widgets.NotificationLabel.Position = [x1 y1 w1 h1];
        end
        
        function updateUI(this)
            % Call update when TC changes
            
            % Grouping variable uitable
            GV = getSelectedGroupingVariable(this.PlotMatrixUITC);
            if isempty(GV)
                this.Panel.Title = getString(message('Controllib:plotmatrix:strGroups'));
                this.Widgets.NotificationLabel.Parent = this.Panel;
                this.Widgets.CategoricalGroupTable.Parent = [];
                this.Widgets.MergeGroupsButton.Parent = [];
            else
                this.Widgets.NotificationLabel.Parent = [];
                this.Widgets.CategoricalGroupTable.Parent = this.Panel;
                this.Widgets.MergeGroupsButton.Parent = this.Panel;
                [style,Data] = getGroupData(this.PlotMatrixUITC,GV);
                % Table
                columneditable3 = true;
                switch style{:}
                    case 'Color'
                        columnnames3 =  getString(message('Controllib:plotmatrix:strColor'));
                        columneditable3 = false;
                        % Color picker
                        for ct=1:numel(Data(:,3))
                            Data{ct,3} = colorgen(rgb2hex(Data{ct,3}),'');
                        end
                        styleList = [];
                    case 'MarkerSize'
                        columnnames3 =  getString(message('Controllib:plotmatrix:strMarkerSize'));
                        styleList = [];
                    case 'LineStyle'
                        columnnames3 =  getString(message('Controllib:plotmatrix:strLineStyle'));
                        styleList = {'-' '--' '-.' ':'};
                    case 'MarkerType'
                        columnnames3 =  getString(message('Controllib:plotmatrix:strMarkerType'));
                        styleList = {'.' '+' 'o' '*' 'x' 's' 'd' '^' 'v' '>' '<' 'p' 'h'};
                end
                columnnames = {getString(message('Controllib:plotmatrix:strGroupLabel')), ...
                    getString(message('Controllib:plotmatrix:strBin')),...
                    columnnames3,...
                    getString(message('Controllib:plotmatrix:strShow')),...
                    getString(message('Controllib:plotmatrix:strRemove'))};
                columnformat = {'char','char',styleList,'logical','char'};
                columneditable = [true true columneditable3 true false];
                this.Widgets.ContinuousGroupTable.ColumnName = columnnames;
                this.Widgets.ContinuousGroupTable.ColumnFormat = columnformat;
                this.Widgets.ContinuousGroupTable.ColumnEditable = columneditable;
                this.Widgets.ContinuousGroupTable.ColumnWidth = {'auto' 'auto' 'auto' 'auto' 'auto'};
                
                [nr,~] = size(Data);
                removecolumn = cell(nr,1);
                for ct=1:nr
                    removecolumn{ct} = icongen;
                end
                Data = [Data, removecolumn];
                % Problem with Color and MakerSize
                this.Widgets.ContinuousGroupTable.Data = Data;
%                 extent = this.Widgets.ContinuousGroupTable.Extent(4);
%                 h = this.Widgets.ContinuousGroupTable.Position(4);
%                 y = this.Widgets.ContinuousGroupTable.Position(2);
%                 this.Widgets.ContinuousGroupTable.Position(2) = h-extent+y;
%                 this.Widgets.ContinuousGroupTable.Position(4) = extent;
                
                % update title of panel
                [grpTitle,numGrp] = getGroupTitle(this.PlotMatrixUITC,GV);
                if numGrp==1
                    strGrp = getString(message('Controllib:plotmatrix:strGroup'));
                else
                    strGrp = getString(message('Controllib:plotmatrix:strGroups'));
                end
                this.Panel.Title = [grpTitle{:},' (',num2str(numGrp),' ',strGrp,')'];
            end
        end
    end
    
    methods (Access = protected)
        function cbCellEdit(this,~,eventData)
            GV = getSelectedGroupingVariable(this.PlotMatrixUITC);
            try
                if ~isempty(eventData.Indices)
                    switch eventData.Indices(2)
                        case 1
                            % Group label
                            setGroupLabel(this.PlotMatrixUITC,GV,eventData.Indices(1),eventData.NewData);
                        case 2
                            % Group Bins
                            if isnan(eventData.NewData)
                                error(message('Controllib:plotmatrix:NumericBinText'));
                            end
                            editBin(this.PlotMatrixUITC, GV, eventData.Indices(1), eventData.NewData)
                            % We call updateUI here, as changing a bin may
                            % change the order of the bins too
                            updateUI(this);
                        case 3
                            % Group style
                            setGroupStyle(this.PlotMatrixUITC,GV,eventData.Indices(1),eventData.NewData);
                        case 4
                            % Show groups
                            setShowGroups(this.PlotMatrixUITC,GV,eventData.Indices(1),eventData.NewData);
                    end
                end
            catch ME
                hErr = errordlg(ME.message,getString(message('Controllib:plotmatrix:strGroupingVariable')),'modal');
                centerfig(hErr,this.Panel.Parent);
                uiwait(hErr);
                updateUI(this);
            end
        end
        
        function cbComboEdit(this, ~, ~)
            GV = getSelectedGroupingVariable(this.PlotMatrixUITC);
            try
                if ~isempty(this.Widgets.AddGroupText.String)
                    binValue = str2double(this.Widgets.AddGroupText.String);
                    if isnan(binValue)
                        error(message('Controllib:plotmatrix:NumericBinText'));
                    end
                    addContinuousGroup(this.PlotMatrixUITC,GV,binValue);
                    updateUI(this);
                    
                end
            catch ME
                hErr = errordlg(ME.message,getString(message('Controllib:plotmatrix:strGroupingVariable')),'modal');
                centerfig(hErr,this.Panel.Parent);
                uiwait(hErr);
                updateUI(this);
            end
        end
        
        function cbCellSelect(this,hTable,eventData)
            GV = getSelectedGroupingVariable(this.PlotMatrixUITC);
            try
                if ~isempty(eventData.Indices) 
                    if eventData.Indices(2)==5
                        removeContinuousGroup(this.PlotMatrixUITC,GV,eventData.Indices(1));
                        updateUI(this);
                    elseif eventData.Indices(2)==3
                        [gstyle,gdata] = getGroupData(this.PlotMatrixUITC,getSelectedGroupingVariable(this.PlotMatrixUITC));
                        if strcmp(gstyle','Color')
                            data = uisetcolor(gdata{eventData.Indices(1),3},getString(message('Controllib:plotmatrix:strColor')));
                            if ~isequal(data,0)
                                setGroupStyle(this.PlotMatrixUITC, GV, eventData.Indices(1), data);
                                hTable.Data{eventData.Indices(1),3} = colorgen(rgb2hex(data),'');
                            end
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
    end
    
    methods
        function this = ContinuousGroupGC(tc)
            this@controllib.ui.plotmatrix.internal.CategoricalGroupGC(tc)
        end
        
        function show(this)
            createPanel(this);
            positionWidgets(this);
            updateUI(this);
        end
    end
end

function icon = icongen
pic = matlab.ui.internal.toolstrip.Icon.CLEAR_16;
icon = ['<HTML><IMG  align="middle" SRC="file:/',pic.Description,'"></HTML>'];
end

function hex = rgb2hex(rgb)
if max(rgb(:))<=1
    rgb = round(rgb*255);
else
    rgb = round(rgb);
end

%% Convert (Thanks to Stephen Cobeldick for this clever, efficient solution):
hex(:,2:7) = reshape(sprintf('%02X',rgb.'),6,[]).';
hex(:,1) = '#';
end

function color = colorgen(color,text)
color = ['<html><table border=0 width=400 bgcolor=',color,'><TR><TD>',text,'</TD></TR> </table></html>'];
end

% LocalWords:  Cobeldick
