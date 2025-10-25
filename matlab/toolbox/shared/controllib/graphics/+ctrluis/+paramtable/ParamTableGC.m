classdef ParamTableGC < ctrluis.AbstractDialog
    %PARAMTABLEGC -- Graphical component for parameter table editor
    %   Manages view of parameter table
    %
    
    % Copyright 2014-2023 The MathWorks, Inc.

    properties
        Table
        Model
    end
    
    properties(Access = protected)
        UITable
        NoParamsLabel
        PopupMenu
        PlotMenuItem
        DeleteMenuItem
        InsertMenuItem
        MenuListeners
        fcnPlot           %Function handle to call when plot menu is selected
    end
    
    methods
        function this = ParamTableGC(tc)
            %Construct ParamTableGC object
            this.TCPeer = tc;

            fig = getFigure(this.TCPeer.ParentTab);
            layout = uigridlayout(fig, [1 1]);
            uit = uitable(layout, ...
                'ColumnSortable', true, ...
                'ColumnWidth', '1x', ...
                'SelectionChangedFcn', @(src,~) cbTableSelectionChanged(this,src));
            
            % For Sensitivity Analysis, put table in row selection mode
            if strcmp('SampleSet', getDataType(tc))
                uit.SelectionType = 'row';
            else
                uit.SelectionType = 'cell';
            end

            this.UITable = uit;

            %Message if there are no parameters
            switch getDataType(this.TCPeer)
                    case 'SampleSet'
                        %Sensitivity Analyzer
                        txt = getString(message('Controllib:gui:ParamEmptySetMessage_Sensitivity'));
                    otherwise
                        %Other apps
                        txt = getString(message('Controllib:gui:ParamEmptySetMessage'));
            end
            this.NoParamsLabel = uilabel(layout, ...
                'Text',                txt, ...
                'HorizontalAlignment', 'center');
            this.NoParamsLabel.Layout.Row    = 1;
            this.NoParamsLabel.Layout.Column = 1;
            

            % Configure table for row selection mode
            gc = this.getPeer;
            
            % %             % Reflect GUI changes to the tool component
            % %             addCallbackListener(this,getTableChangedCallback(gc),{@LocalTableChangedCallback,this});
            % %             addCallbackListener(this,getMouseClickedCallback(gc),{@LocalMouseClickedCallback,this});
                              
            % Listen to tool component changes
            installTCListeners(this);
                        
            vUpdate(this);
            
        end
        function vUpdate(this)
            params = getParameterData(this.TCPeer);

            switch getDataType(this.TCPeer)
                case 'SampleSet'
                    paramData = this.TCPeer.ParameterData.Values;
                    this.UITable.ColumnEditable = true;
                otherwise
                    if isempty(this.TCPeer.ParameterData)
                        % ParameterData is empty initially, so values and
                        % names need to be constructed expicitly
                        values = [];
                        names = {};
                    else
                        values = [this.TCPeer.ParameterData.Value];
                        names  = {this.TCPeer.ParameterData.Name};
                    end
                    paramData = array2table(values, 'VariableNames', names);
            end

            if isempty(paramData)
                this.UITable.Data = [];
            else
                this.UITable.Data = paramData;
            end

            %Display placeholder-type message if there are no parameters
            this.UITable.Visible        = ~isempty(params);
            this.NoParamsLabel.Visible  =  isempty(params);
        end
        
        function installTCListeners(this)
            M(1) = addlistener(this.TCPeer, 'ComponentChanged', @(es,ed) vUpdate(this));            
            this.APIListeners = M;
        end
        function close(this)
            % CLOSE Close
            %
            if isvalid(this)
                if ~isempty(this.PopupMenu)
                    dispose(this.PopupMenu)
                    for ct=1:numel(this.MenuListeners)
                        delete(this.MenuListeners(ct))
                    end
                    this.PopupMenu    = [];
                    this.MenuListeners = [];
                end
                tc = getTC(this);
                closeFigure(tc.ParentTab);
            end
            delete(this);
        end
        function setPlotCallback(this,fcn)
            %SETPLOTCALLBACK
            %
            
            this.fcnPlot = fcn;
        end

        function setTableEditable(this,editable)
            % setTableEditable(this,editable)
            %   Sets ColumnEditable property of UITable to editable (scalar, logical)
            arguments
                this
                editable (1,1) logical
            end
            if ~isempty(this.UITable) && isvalid(this.UITable)
                this.UITable.ColumnEditable = editable;
                this.UITable.CellEditCallback = @(es,ed) LocalTableChangedCallback(es,ed,this);
            end
        end
    end
    
    methods(Access = protected)
        function cbTableSelectionChanged(this,uit)
            %CBTABLESELECTIONCHANGED React to table selection changes
            if strcmp('SampleSet', getDataType(this.TCPeer))
                rows = uit.Selection;
            else
                rows = unique(uit.Selection(:,1), 'sorted');
            end
            rows = rows(:);   % ensure vertical orientation
            setSelectedRow(this.TCPeer, rows-1);   % % method expects Java indexing
        end

        function cbPlot(this)
            %CBPLOT Manage plot menu actions
            %
            
            this.fcnPlot();
        end
        function cbDeleteRow(this)
            %CBSDELETEROW Manage delete row menu actions
            %
            
            deleteRow(this.TCPeer);
        end
        function cbInsertRow(this)
            %CBINSERTROW Manage insert row menu actions
            %
            
            insertRow(this.TCPeer,true); %Insert above selected row
        end
    end

    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.UITable = this.UITable;
            widgets.NoParamsLabel = this.NoParamsLabel;
            widgets.PopupMenu = this.PopupMenu;
            widgets.PlotMenuItem = this.PlotMenuItem;
            widgets.DeleteMenuItem = this.DeleteMenuItem;
            widgets.InsertMenuItem = this.InsertMenuItem;
        end
        function qeChangeTableCell(this,row,col,val)
            params = getParameterData(this.TCPeer);
            if row > 0 && col >0
                newValue = val;
                if ~isempty(newValue)
                    params(col).Value(row) = newValue;   %Table data is Double
                    applyParameterData(this.TCPeer,params);
                end
                vUpdate(this);   %update/revert display
            end
        end
    end
end

% CALLBACKS
function LocalTableChangedCallback(~,ed,this)
% Get event information
row = ed.Indices(1);
col = ed.Indices(2);
params = getParameterData(this.TCPeer);
Data = this.UITable.Data;
if row > 0 && col >0
    newValue = Data{row,col};
    %Don't use new value if it's empty
    if ~isempty(newValue)
        params(col).Value(row) = newValue;   %Table data is Double
        applyParameterData(this.TCPeer,params);
    end
    vUpdate(this);   %update/revert display
end
end