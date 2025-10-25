classdef SelectBlockDialog < controllib.ui.internal.dialog.AbstractDialog
    % Class for block selection dialog
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties (Access=private)
        ModelParameterMgr
        BlockTree
        ControlDesignData
        
        ExploreTree
        BlockTable
        
        HiliteButton
        OKButton
        CancelButton
    end
    
    methods
        function this = SelectBlockDialog(model)
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.Name = 'CSTuner_SelectBlock';
            this.Title = getString(message(...
                'Slcontrol:controldesign:SISOSelectBlk2Tune'));
            
            if ischar(model)
                this.ModelParameterMgr = linearize.ModelLinearizationParamMgr.getInstance(model);
            else
                % CSD
                if ismethod(model,'getName')
                    this.ModelParameterMgr = linearize.ModelLinearizationParamMgr.getInstance(model.getName);
                elseif ismethod(model,'getArchitectureName')
                % CST
                    this.ModelParameterMgr = linearize.ModelLinearizationParamMgr.getInstance(model.getArchitectureName);
                end
                this.ControlDesignData = model;
            end
            
            this.ModelParameterMgr.compile('compile');
            [~,this.BlockTree] = controldesign.findTunableBlocks(this.ModelParameterMgr,false);
            this.ModelParameterMgr.term;
        end
        
        function updateData(this,data)
            this.ControlDesignData = data;
        end
        
        function updateUI(this)
            if isempty(this.ExploreTree.SelectedNodes) && ~isempty(this.ExploreTree.Children)
                this.ExploreTree.SelectedNodes = this.ExploreTree.Children(1);
                this.BlockTable.Data = this.ExploreTree.SelectedNodes.NodeData.ListData;
            end
        end
        
        function show(this,varargin)
            if this.IsWidgetValid
                % Check if model compiles if widget is valid. This protects
                % against introduction of compilation error after BlockTree
                % is built.
                this.ModelParameterMgr.compile('compile');
                this.ModelParameterMgr.term;
            end
            show@controllib.ui.internal.dialog.AbstractDialog(this,varargin{:});
        end
    end
    
    methods (Access = protected)
        function buildUI(this)
            % GridLayout
            FigureGrid = uigridlayout(this.UIFigure, [2 2]);
            FigureGrid.RowHeight = {'1x','fit'};
            FigureGrid.ColumnWidth = {'0.5x','1x'};
            FigureGrid.RowSpacing = 5;
            FigureGrid.Scrollable = 'on';
            
            % Block Tree Panel
            this.ExploreTree = uitree(FigureGrid);
            this.ExploreTree.Layout.Row = 1;
            this.ExploreTree.Layout.Column = 1;
            this.ExploreTree.SelectionChangedFcn = @(src,event) exploreTreeNodeChange(this,src,event);
            createTreePanel(this);
            
            % Block View Panel
            HelpPanel = uipanel(FigureGrid);
            HelpPanel.Title = getString(message('Controllib:gui:SelectBlockInstruct'));
            HelpPanel.BorderType = 'none';
            HelpPanel.FontWeight = 'bold';
            HelpPanel.Layout.Row = 1;
            HelpPanel.Layout.Column = 2;
            HelpGrid = uigridlayout(HelpPanel, [1 1]);
            
            % Block View Table
            this.BlockTable = uitable(HelpGrid);
            this.BlockTable.Layout.Row = 1;
            this.BlockTable.Layout.Column = 1;
            this.BlockTable.ColumnWidth = {80,'1x'};
            this.BlockTable.ColumnName = {...
                getString(message('Controllib:gui:SelectBlockTune'));...
                getString(message('Controllib:gui:SelectBlockBlockName'))};
            this.BlockTable.RowName = [];
            this.BlockTable.ColumnEditable = [true false];
            this.BlockTable.RowStriping = 'off';
            this.BlockTable.SelectionType = 'row';
            this.BlockTable.Multiselect = 'off';
            this.BlockTable.DisplayDataChangedFcn = @(~,~) tableDataChange(this);
            
            % Button Grid
            ButtonGrid = uigridlayout(FigureGrid, [2 5]);
            ButtonGrid.Layout.Row = 2;
            ButtonGrid.Layout.Column = 2;
            ButtonGrid.RowHeight = {'fit','fit'};
            ButtonGrid.ColumnWidth = {'1x','1x','1x','fit','fit'};
            ButtonGrid.Padding = [0 0 0 0];
            
            this.HiliteButton = uibutton(ButtonGrid,'Text',...
                getString(message('Controllib:gui:SelectBlockHighlight')));
            this.HiliteButton.Layout.Row = 1;
            this.HiliteButton.Layout.Column = 4:5;
            this.HiliteButton.ButtonPushedFcn = @(~,~) callbackHiliteButton(this);
            
            this.OKButton = uibutton(ButtonGrid,'Text',...
                getString(message('Slcontrol:controldesign:SISOSelectRespOK')));
            this.OKButton.Layout.Row = 2;
            this.OKButton.Layout.Column = 4;
            this.OKButton.ButtonPushedFcn = @(~,~) callbackOKButton(this);
            
            this.CancelButton = uibutton(ButtonGrid,'Text',...
                getString(message('Slcontrol:controldesign:SISOSelectRespCancel')));
            this.CancelButton.Layout.Row = 2;
            this.CancelButton.Layout.Column = 5;
            this.CancelButton.ButtonPushedFcn = @(~,~) callbackCancelButton(this);
            
            this.UIFigure.Position(3:4) = [540 400];
        end
        
        function callbackHiliteButton(this)
            try
                TunableBlockPath = this.ExploreTree.SelectedNodes.NodeData.Blocks{...
                    this.BlockTable.Selection};
                linearize.advisor.utils.go2block(TunableBlockPath);
            catch
                uialert(this.UIFigure,...
                    getString(message('Slcontrol:controldesign:SISONoBlockSelected')),...
                    getString(message('Control:systunegui:toolName')));
            end
        end
        
        function callbackOKButton(this)
            % Update the table
            SelectedBlocks = getSelectedBlocks(this);
            
            w = warning('off','Slcontrol:sltuner:AddBlockMakesNonUnique');
            restoreWarningState = onCleanup(@()warning(w));
            % Close the frame
            try
                % take a copy of sltuner since it may go to bad state with
                % Simulink.Parameter blocks
                this.ControlDesignData.addTunableBlock(SelectedBlocks);
                close(this);
            catch ex
                if strcmp(ex.identifier,'Slcontrol:linutil:ZOHD2CPoleAtZero')
                    msg = getString(message('Slcontrol:linutil:ZOHD2CPoleAtZeroGUI',...
                        this.ControlDesignData.Architecture.Model));
                elseif contains(ex.identifier,'Slcontrol:sltuner')
                    msg = ex.message;
                else
                    msg = getString(message('Control:systunegui:GeneralErrorBlockWithSimulinkParameter'));
                end
                uialert(this.UIFigure,msg,getString(message('Control:systunegui:toolName')));
            end
            warning(w);
        end
        
        function callbackCancelButton(this)
            this.close();
        end
    end
    
    methods (Hidden)
        function Widgets = qeGetWidgets(this)
            Widgets = struct('ExploreTree', this.ExploreTree,...
                'BlockTable', this.BlockTable,...
                'HiliteButton', this.HiliteButton,...
                'OKButton', this.OKButton,...
                'CancelButton', this.CancelButton);
        end
        
        function createTreePanel(this)
            nestedSearchTree(this.BlockTree, this.ExploreTree);
            % Expand first level
            expand(this.ExploreTree);
            function val = nestedHasTunableBlockData(node)
                % find nodes that have tunable blocks somewhere in it's
                % hierarchy
                val = ~isempty(node.Blocks);
                if ~val
                    children = node.getChildren;
                    for c = children(:)'
                        val = nestedHasTunableBlockData(c);
                        if val
                            return;
                        end
                    end
                end
            end
            function nestedSearchTree(node, parent)
                children = node.getChildren;
                % early return if this parent system doesn't have any
                % tunable blocks or child systems. 
                if ~nestedHasTunableBlockData(node)
                    return;
                end
                %% Get nodes in Block Tree
                panelNode = uitreenode(parent,'NodeData',node);
                matlab.ui.control.internal.specifyIconID(panelNode, node.Icon, 16);
                panelNode.Text = node.Label;
                %% Loop over the children
                for ct = 1:length(children)
                    nestedSearchTree(children(ct),panelNode)
                end
            end
        end
        
        function exploreTreeNodeChange(this,~,event)
            this.BlockTable.Data = event.SelectedNodes.NodeData.ListData;
        end
        
        function tableDataChange(this)
            this.ExploreTree.SelectedNodes.NodeData.ListData = this.BlockTable.Data;
        end
        
        function selectedBlocks = getSelectedBlocks(this)
            selectedBlocks = cell(0,1);
            nestedSearchTree(this.BlockTree);
            
            %% Loop over the children to get the list of selected blocks
            function nestedSearchTree(node)
                %% Get the elements that are selected
                celldata = cell(node.ListData);
                indSelected = find([celldata{:,1}]);
                selectedBlocks = [selectedBlocks;node.Blocks(indSelected(:))];
                %% Loop over the children
                children = node.getChildren;
                for ct = 1:length(children)
                    nestedSearchTree(children(ct))
                end
            end
        end
    end
end