classdef (ConstructOnLoad) AbstractContainer < controllib.ui.internal.dialog.AbstractContainer
    % controllib.ui.internal.dialog.AbstractContainer 

    % Copyright 2020-2022 The MathWorks, Inc.
    properties
        ContainerTitle = ''
        ShowContainerTitle = true
    end

    properties (Dependent,AbortSet,SetObservable)
        Visible
    end
    
    properties (Access = protected)
        ContainerWidget
        TitleLabel
        CustomWidget
    end
    
    methods
        function this = AbstractContainer()

        end

        function setCustomWidget(this,customWidget)
            arguments
                this
                customWidget
            end
            % Replace custom widget
            delete(this.CustomWidget);
            this.CustomWidget = customWidget;

            % Add to container if valid
            if this.IsWidgetValid
                customWidget.Parent = this.Container;
                customWidget.Layout.Row = 3;
                customWidget.Layout.Column = [1 2];
            end
        end

        function customWidget = getCustomWidget(this)
            customWidget = this.CustomWidget;
        end

        % Visible
        function Visible = get.Visible(this)
            if isempty(this.ContainerWidget) || ~isvalid(this.ContainerWidget)
                Visible = false;
            else
                Visible = this.ContainerWidget.Visible;
            end
        end

        function set.Visible(this,Visible)
            arguments
                this (1,1) controllib.widget.internal.cstprefs.AbstractContainer
                Visible (1,1) matlab.lang.OnOffSwitchState
            end
            if ~isempty(this.ContainerWidget) && isvalid(this.ContainerWidget)
                this.ContainerWidget.Visible = Visible;
            end
        end
    end
    
    methods(Access = protected, Sealed)
        function container = createContainer(this)
            this.ContainerWidget = uigridlayout('Parent',[],'RowHeight',{'fit','fit','fit'},'ColumnWidth',{0,'1x'},...
                'Scrollable',"on");
            this.ContainerWidget.Padding = 0;
            % Title
            if this.ShowContainerTitle
                this.ContainerWidget.ColumnWidth{1} = 10;
                this.TitleLabel = uilabel(this.ContainerWidget,'Text',this.ContainerTitle);
                this.TitleLabel.Layout.Row = 1;
                this.TitleLabel.Layout.Column = [1 2];
                this.TitleLabel.FontWeight = 'bold';
            end
            % Subclass widget
            widget = createWidget(this);
            widget.Parent = this.ContainerWidget;
            widget.Layout.Row = 2;
            widget.Layout.Column = 2;
            % Custom widget
            if ~isempty(this.CustomWidget) && isvalid(this.CustomWidget)
                this.CustomWidget.Parent = this.ContainerWidget;
                this.CustomWidget.Layout.Row = 3;
                this.CustomWidget.Layout.Column = [1 2];
            end
            container = this.ContainerWidget;
        end
    end
    
    methods(Access = protected,Abstract)
        widget = createWidget(this)
    end
end
