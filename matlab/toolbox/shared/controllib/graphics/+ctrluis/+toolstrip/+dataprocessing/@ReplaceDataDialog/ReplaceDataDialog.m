classdef ReplaceDataDialog < controllib.ui.internal.dialog.AbstractDialog
    %
    
    %   Copyright 2020-2024 The MathWorks, Inc.
    
    properties(Access = protected)
        Widgets          %Widgets in the dialog 
        ReplaceDataMode  %Mode this Replace dialog works with
        
        HelpData
    end
    
    methods
        function obj = ReplaceDataDialog(mode)
            %REPLACEDATADIALOG Constructor
            %
            
            obj.CloseMode = 'destroy'; %To clean up when mode is deleted
            obj.ReplaceDataMode = mode;
            obj.HelpData = struct(...
                'MapFile', 'sldo', ...
                'TopicID', 'replaceData');
        end
    end
  
    %Public methods
    methods
        function updateUI(this)
            %UPDATEUI Push data to the graphical display
            
            if ~this.IsWidgetValid 
                return
            end
            
            this.Widgets.edtValue.Value = mat2str(this.ReplaceDataMode.ReplaceValue,8);
        end
        function wdgts = getWidgets(this)
            %GETWIDGETS
            %
            wdgts = this.Widgets;
            wdgts.UIFigure = this.UIFigure;
        end
        function setHelpData(this,mapfile,topicid)
             %SETHELPDATA 
             %
             %    setHelpData(obj,mapfile,topicic)
             %
             %    Set the help mapfile and topic id for this filter tool.
             %
             
             this.HelpData.MapFile = mapfile;
             this.HelpData.TopicID = topicid;
        end
        function delete(this)
            
            if isvalid(this)
            end
        end
    end
    
    %Protected methods
    methods(Access = protected)
        function buildUI(this) 
            %BUILDUI Create the UI widgets.
            
            %Set figure properties and create grid layout
            this.UIFigure.Tag = 'dlgReplaceValue';
            this.UIFigure.Name = getString(message('Controllib:dataprocessing:lblReplaceData_ReplaceValueTitle'));
            this.UIFigure.Position(3:4) = [360 90]; %Set default size in pixels
            dlgLayout = uigridlayout(this.UIFigure,[3 2]);
            dlgLayout.ColumnWidth = {'fit','1x'};
            dlgLayout.RowHeight = {'fit','1x','fit'};
            dlgLayout.Scrollable = 'off';
            dlgLayout.Tag = 'dlgLayout';
            
            % Create value widgets
            lblValue = uilabel(dlgLayout, 'text',getString(message('Controllib:dataprocessing:lblReplaceData_ReplaceValue')));
            lblValue.Tag = 'lblValue';
            lblValue.Layout.Column = 1;
            lblValue.Layout.Row = 1;
            edtValue = uieditfield(dlgLayout);
            edtValue.Tag = 'edtValue';
            edtValue.Layout.Column = 2;
            edtValue.Layout.Row = 1;
            
            % Create button widgets
            pnl = uicontainer(dlgLayout);
            pnl.Layout.Column = [1 2];
            pnl.Layout.Row = 3;
            btnPanel = controllib.widget.internal.buttonpanel.ButtonPanel(pnl,["Help" "Cancel" "Apply"]);
            
            this.Widgets = struct(...
                "edtValue", edtValue, ...
                "ButtonPanel", btnPanel, ...
                "DlgLayout", dlgLayout);
        end
        
        function connectUI(this)
            %ConnectUI Add widget callbacks/listeners
            %
            btnPanel = this.Widgets.ButtonPanel;
            btnPanel.CancelButton.ButtonPushedFcn = @(hSrc,hData) close(this);
            btnPanel.ApplyButton.ButtonPushedFcn = @(hSrc,hData) cbApplyValue(this);
            btnPanel.HelpButton.ButtonPushedFcn = @(hSrc,hData) cbHelp(this);
        end
        
        function cleanupUI(this)
            %CLEANUPUI Closes UI 
            
            % Default close method deletes UIFigure, which in turns deletes
            % all its children.
            close(this)
        end    
    end
    
    methods(Access=private)
          function cbApplyValue(this)
            %CBREPLACEVALUEEDIT
            %
            
            edtValue = this.Widgets.edtValue;
            try
                val = eval(edtValue.Value);
                setReplaceValue(this.ReplaceDataMode,val)
            catch
                %Revert, invalid value
                updateUI(this)
                return
            end
          end
          function cbHelp(this)
              %CBHELP
              %
              
              helpview(this.HelpData.MapFile, this.HelpData.TopicID)
          end
    end
end