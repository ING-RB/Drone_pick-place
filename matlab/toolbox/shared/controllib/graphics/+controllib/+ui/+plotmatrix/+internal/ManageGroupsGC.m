classdef ManageGroupsGC < handle
%

%   Copyright 2016-2020 The MathWorks, Inc.
    
    properties (Access = private)
        PlotMatrixUITC
        
        GroupingVariableGC
        ContinuousGroupGC
        CategoricalGroupGC
        
        GroupingVariablePanel
        ContinousGroupPanel
        CategoricalGroupPanel
        
        GVChangedListener
        Widgets
        Panel
        Figure
    end
    
    methods
        function this = ManageGroupsGC(tc)
            this.PlotMatrixUITC = tc;
            this.GVChangedListener = addlistener(tc,'GroupingVariableSelectionChanged',@(es,ed)updateGroups(this));
            addlistener(tc,'ObjectBeingDestroyed', @(es,ed)delete(this));
            addlistener(tc,'ComponentChanged', @(es,ed)updateUI(this));
        end
        
        function TC = getPeer(this)
            TC = this.PlotMatrixUITC;
        end
        
        function createPanel(this)
            this.Figure = figure(...
                'Name',              getString(message('Controllib:plotmatrix:strManageGroupsTitle')), ...
                'MenuBar',          'none', ...
                'HandleVisibility', 'off', ...
                'Integerhandle',    'off', ...
                'NumberTitle',      'off', ...
                'HitTest',          'off', ...
                'WindowStyle',      'normal', ...
                'Units',            'points',...
                'Visible',           'off', ...
                'Position',         [800 400 421 300],...
                'ResizeFcn',        @(es,ed) positionWidgets(this));
            
            %Add buttons
            this.Widgets.OkButton = uicontrol(...
                'Parent', this.Figure, ...
                'Style', 'pushbutton', ...
                'Units', 'points', ...
                'String', getString(message('sldo:dialogs:lblOK')), ...
                'Tag',    'btnStop',...
                'Callback', @(es,ed)cbOk(this));
            this.Widgets.CancelButton = uicontrol(...
                'Parent', this.Figure, ...
                'Style', 'pushbutton', ...
                'Units', 'points', ...
                'String', getString(message('sldo:dialogs:lblCancel')), ...
                'Tag',    'btnCancel',...
                'Callback', @(es,ed)cbCancel(this));
            this.Widgets.ApplyButton = uicontrol(...
                'Parent', this.Figure, ...
                'Style', 'pushbutton', ...
                'Units', 'points', ...
                'String', getString(message('sldo:dialogs:lblApply')), ...
                'Tag',    'btnHelp',...
                'Callback', @(es,ed) pushData(this.PlotMatrixUITC));
                        
            % UILabel
            this.Widgets.NotificationLabel = uicontrol('Style','text',...
                'String', 'Please select a grouping variable to manage its groups',...
                'HorizontalAlignment', 'center',...
                'FontSize',12, ...
                'Parent', []);

            this.GroupingVariableGC = controllib.ui.plotmatrix.internal.GroupingVariableSectionGC(this.PlotMatrixUITC);
            this.GroupingVariablePanel = createPanel(this.GroupingVariableGC);
            this.GroupingVariablePanel.Parent = this.Figure;
            
            this.CategoricalGroupGC = controllib.ui.plotmatrix.internal.CategoricalGroupGC(this.PlotMatrixUITC);
            this.CategoricalGroupPanel = createPanel(this.CategoricalGroupGC);
            
            this.ContinuousGroupGC = controllib.ui.plotmatrix.internal.ContinuousGroupGC(this.PlotMatrixUITC);
            this.ContinousGroupPanel = createPanel(this.ContinuousGroupGC);
        end
        
        function show(this)
            if isempty(this.Figure) || ~isvalid(this.Figure)
                % Create panel
                createPanel(this);
                centerfig(this.Figure,this.PlotMatrixUITC.getParent);
                % connectUI
            end
            % UpdateUI
            updateUI(this);
            
            this.Figure.Visible = 'on';
        end
                        
        function updateUI(this)
            % Call update when TC changes
            updateUI(this.GroupingVariableGC);
            updateGroups(this);
        end
        
        function delete(this)
            delete(this.GroupingVariableGC);
            if ~isempty(this.ContinuousGroupGC)
                delete(this.ContinuousGroupGC);
                delete(this.ContinousGroupPanel);
            end
            
            if ~isempty(this.CategoricalGroupGC)
                delete(this.CategoricalGroupPanel);
                delete(this.CategoricalGroupGC);
            end
            delete(this.GVChangedListener);
            if isfield(this.Widgets, 'NotificationLabel')
                delete(this.Widgets.NotificationLabel);
            end
            delete(this.Panel);
            delete(this.Figure);
            delete(this.PlotMatrixUITC);
        end
        
        function positionWidgets(this)
            wPad = 10;
            hPad = 10;
            % Entire figure position
            Position = this.Figure.Position;
            
            % Label occupies the left over height
            this.Widgets.OkButton.Position = [wPad, hPad, this.Widgets.OkButton.Position(3), this.Widgets.OkButton.Position(4)];
            this.Widgets.ApplyButton.Position = [wPad+this.Widgets.OkButton.Position(1)+this.Widgets.OkButton.Position(3), hPad, this.Widgets.ApplyButton.Position(3), this.Widgets.ApplyButton.Position(4)];
            this.Widgets.CancelButton.Position = [wPad+this.Widgets.ApplyButton.Position(1)+this.Widgets.ApplyButton.Position(3), hPad, this.Widgets.CancelButton.Position(3), this.Widgets.CancelButton.Position(4)];
            
            TotalButtonWidth = this.Widgets.OkButton.Position(3)+this.Widgets.ApplyButton.Position(3)+this.Widgets.CancelButton.Position(3)+wPad*4;
            RemainingWidth = Position(3)-TotalButtonWidth;
            
            this.Widgets.OkButton.Position(1) = this.Widgets.OkButton.Position(1) + RemainingWidth;
            this.Widgets.ApplyButton.Position(1) = this.Widgets.ApplyButton.Position(1) + RemainingWidth;
            this.Widgets.CancelButton.Position(1) = this.Widgets.CancelButton.Position(1) + RemainingWidth;
            
            % Height of button
            BtnHeight = this.Widgets.OkButton.Extent(4);
                      
            % Height available after button panel
            Position(4) = Position(4)-BtnHeight-2*hPad;
            yGroups = BtnHeight+2*hPad;
            hGroups = (Position(4)-2*hPad)/2;
            % Groups section occupies the rest of the available height and
            % the entire width
            GV = getSelectedGroupingVariable(this.PlotMatrixUITC);
            if isempty(GV)
                this.Widgets.NotificationLabel.Position = [wPad, yGroups, Position(3)-2*wPad, hGroups];
            else
                if isCategorical(this.PlotMatrixUITC,GV)
                    this.CategoricalGroupPanel.Position = [wPad, yGroups, Position(3)-2*wPad, hGroups];
                    positionWidgets(this.CategoricalGroupGC);
                else
                    this.ContinousGroupPanel.Position = [wPad, yGroups, Position(3)-2*wPad, hGroups];
                    positionWidgets(this.ContinuousGroupGC);
                end
            end
            
            % Grouping variable section occupies half of the available
            % height and the entire width
            this.GroupingVariablePanel.Position = [wPad, hPad+yGroups+hGroups, Position(3)-2*wPad, (Position(4)-2*hPad)/2];
            positionWidgets(this.GroupingVariableGC);
        end
        
        function updateGroups(this)
            GV = getSelectedGroupingVariable(this.PlotMatrixUITC);
            if isempty(GV)
                this.Widgets.NotificationLabel.Parent = this.Figure;
                this.CategoricalGroupPanel.Parent = [];
                this.ContinousGroupPanel.Parent = [];
            elseif isCategorical(this.PlotMatrixUITC,GV)
                this.ContinousGroupPanel.Parent = [];
                updateUI(this.CategoricalGroupGC);
                this.CategoricalGroupPanel.Parent = this.Figure;
                this.Widgets.NotificationLabel.Parent = [];
            else
                this.CategoricalGroupPanel.Parent = [];
                this.ContinousGroupPanel.Parent = this.Figure;
                updateUI(this.ContinuousGroupGC);
                this.Widgets.NotificationLabel.Parent = [];
            end
            positionWidgets(this);
        end
        
        function cbOk(this)
            %CBOK Manage OK button events
            pushData(this.PlotMatrixUITC);
            delete(this);
        end
        function cbCancel(this)
            %Close the dialog
            delete(this);
        end
    end
    
    %% Testing methods
    methods (Hidden = true)
        function wdgts = qeGetWidgets(this)
            wdgts = this.Widgets;
        end
        
        function GV = qeGetGroupingVariableSection(this)
            GV = this.GroupingVariableGC;
        end
        
        function Grp = qeGetContinuousGroupGC(this)
            Grp = this.ContinuousGroupGC;
        end
        
        function Grp = qeGetCategoricalGroupGC(this)
            Grp = this.CategoricalGroupGC;
        end
    end
end
