classdef CategoricalGroupGC < handle
%

%   Copyright 2016-2020 The MathWorks, Inc.
    
    properties (Access = protected)
        PlotMatrixUITC
        Widgets
        Panel
        SelectedGroupIndex
    end
    
    methods (Access = public)
        function pnl = createPanel(this)
            % Build all the graphical components
            
            % panel
            pnl = uipanel('Parent',[],'FontSize',12,'Units','points');
            this.Panel = pnl;
            
            this.Widgets.CategoricalGroupTable = uitable(pnl, ...
                'Units',                   'points',...
                'RowName',                 {}, ...
                'RowStriping',             'off', ...
                'Visible',                 'on',...
                'CellEditCallback',         @(hTable, eventData) cbCellEdit(this, hTable, eventData),...
                'CellSelectionCallback',    @(hTable, eventData) cbCellSelect(this, hTable, eventData));

            
            % merge Groups button
            this.Widgets.MergeGroupsButton = uicontrol(pnl,...
                'Tag',                  'MergeGroup', ...
                'Style',                'pushbutton',...
                'String',               sprintf('%s', getString(message('Controllib:plotmatrix:strMergeGroups'))),...
                'HorizontalAlignment',  'left', ...
                'Units',                'points',...
                'Enable',               'off',...
                'Callback',             @(hCombo,eventData) cbComboEdit(this,hCombo,eventData));
        end
        
        function positionWidgets(this)
            wPad = 10;
            hPad = 10;
            % merge Groups button
            x1 = wPad;
            y1 = hPad;
            w1 = this.Panel.Position(3)-2*wPad;
            h1 = this.Panel.Position(4)-2*hPad;
            this.Widgets.MergeGroupsButton.Position =  [x1 y1 w1 h1];
            w1 = this.Widgets.MergeGroupsButton.Extent(3);
            this.Widgets.MergeGroupsButton.Position(3) = w1;           
            h1 = this.Widgets.MergeGroupsButton.Extent(4);
            this.Widgets.MergeGroupsButton.Position(4) = h1;
            
            % Table
            x1 = wPad;                              
            y1 = y1+h1+hPad+2;
            w1 = this.Panel.Position(3)-2*wPad;
            h1 = this.Panel.Position(4)- y1 - 2*hPad;
            this.Widgets.CategoricalGroupTable.Position = [x1 y1 w1 h1];
            
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
                    getString(message('Controllib:plotmatrix:strShow'))};
                columnformat = {'char','char',styleList,'logical'};
                columneditable = [true false columneditable3 true];
                this.Widgets.CategoricalGroupTable.ColumnName = columnnames;
                this.Widgets.CategoricalGroupTable.ColumnFormat = columnformat;
                this.Widgets.CategoricalGroupTable.ColumnEditable = columneditable;
                
                this.Widgets.CategoricalGroupTable.ColumnWidth = { 'auto' 'auto' 'auto' 'auto'};
                
                % Problem with Color and MakerSize
                this.Widgets.CategoricalGroupTable.Data = Data;
                
                extent = this.Widgets.CategoricalGroupTable.Extent(4);
                h = this.Widgets.CategoricalGroupTable.Position(4);
                y = this.Widgets.CategoricalGroupTable.Position(2);
                this.Widgets.CategoricalGroupTable.Position(2) = h-extent+y;
                this.Widgets.CategoricalGroupTable.Position(4) = extent;
                
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
        
        function cbCellSelect(this,hTable,eventData)
            GV = getSelectedGroupingVariable(this.PlotMatrixUITC);
            try
                grpidx = unique(eventData.Indices(:,1));
                if numel(grpidx) > 1
                    this.Widgets.MergeGroupsButton.Enable = 'on';
                    this.SelectedGroupIndex = grpidx;
                else
                    this.Widgets.MergeGroupsButton.Enable = 'off';
                    this.SelectedGroupIndex = [];
                    if ~isempty(eventData.Indices) && eventData.Indices(2)==3
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
        
        function cbComboEdit(this,~,~)
            GV = getSelectedGroupingVariable(this.PlotMatrixUITC);
            if ~isempty(this.SelectedGroupIndex)
                mergeCategoricalGroup(this.PlotMatrixUITC,GV,this.SelectedGroupIndex);
                update(this.PlotMatrixUITC);
            end
        end

    end
    
    methods
        function this = CategoricalGroupGC(tc)
            this.PlotMatrixUITC = tc;
        end
        
        function show(this)
            createPanel(this);
            positionWidgets(this);
            updateUI(this);
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
