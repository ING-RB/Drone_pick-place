classdef PropertyEditorDialog < controllib.ui.internal.dialog.AbstractDialog
    % Property Editor Dialog for Controls and Ident plots
    %
    % dlg = controllib.widget.internal.cstprefs.PropertyEditorDialog(["Units","Style"]);
    % show(dlg);

    %   Copyright 2020-2022 The MathWorks, Inc.
    properties
        Target
        TargetListeners
    end

    properties (Access=private)
        GridLayout      matlab.ui.container.GridLayout
        TabGroup        matlab.ui.container.TabGroup
        Tabs            matlab.ui.container.Tab
        TabLabels       string
        ButtonPanel     controllib.widget.internal.buttonpanel.ButtonPanel
        CloseButton     matlab.ui.control.Button
    end

    events
        PropertyEditorBeingClosed
    end

    methods
        function this = PropertyEditorDialog(tabLabels)
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.Name = 'PropertyEditorDialog';
            this.Title = getString(message('Controllib:gui:strPropertyEditor'));
            this.TabLabels = string(tabLabels);
        end

        function updateUI(this) %#ok<MANU>

        end

        function show(this)
            ax = getaxes(this.Target);
            if ~isactiveuimode(ancestor(ax(1),'figure'),'Standard.EditPlot')
                set(ax,'Selected','on')
            end
            show@controllib.ui.internal.dialog.AbstractDialog(this);
        end

        function buildTab(this,tabLabel,tabContent)
            tabContent.Parent = findTab(this,tabLabel);
        end

        function layout = findTabLayout(this,tabLabel)
            tab = this.Tabs(this.TabLabels == tabLabel);
            layout = [];
            if ~isempty(tab)
                layout = tab.Children;
            end
        end

        function setTarget(this,NewTarget)
            % (Re)targets the Property Editor
            if ~isequal(this.Target,NewTarget)
                % Unselect old target's axes
                if ~isempty(this.Target) && ...
                        ((ishandle(this.Target) && ~this.Target.isBeingDestroyed) || ... %UDD
                        (isobject(this.Target) && isvalid(this.Target))) %MCOS
                    CurrentAxes = getaxes(this.Target);
                    if ~isactiveuimode(ancestor(CurrentAxes(1),'figure'),'Standard.EditPlot')
                        set(getaxes(this.Target),'Selected','off')
                    end
                end
                % Update property
                this.Target = NewTarget;
                % Listener management
                if isempty(NewTarget)
                    % Delete target-dependent listeners
                    this.TargetListeners = [];
                    %                     set(cat(1,this.Tabs.Contents),'TargetListeners',[])
                else
                    % Listen for Target destruction
                    if ishandle(this.Target) %UDD
                        L = handle.listener(NewTarget,'ObjectBeingDestroyed',...
                            @closeAndDeleteDialog);
                        L.CallbackTarget = this;
                    else %MCOS
                        L = event.listener(NewTarget,'ObjectBeingDestroyed',...
                            @(~,hData)close(this));
                    end
                    this.TargetListeners = L;

                    % Populate tabs and sync data with new target\
                    if this.IsWidgetValid
                        deleteWidgets(this);
                        buildUI(this);
                    end
                    ax = getaxes(NewTarget);
                    f = ancestor(ax(1),'figure');
                    currentPointer = f.Pointer;
                    f.Pointer = 'watch';
                    show(this);
                    NewTarget.edit(this)
                    f.Pointer = currentPointer;

                    % Show which plot is selected
                    NewAxes = getaxes(NewTarget);
                    if ~isactiveuimode(ancestor(NewAxes(1),'figure'),'Standard.EditPlot')
                        set(NewAxes,'Selected','on')
                    end
                end
            end
        end

        function close(this)
            if ~isempty(this.Target) && (ishandle(this.Target) || isvalid(this.Target))
                ax = getaxes(this.Target);
                if ~isactiveuimode(ancestor(ax(1),'figure'),'Standard.EditPlot')
                    set(ax,'Selected','off')
                end

                % Reset limits
                try
                    widgets = getPropertyEditorWidgets(this.Target);
                    if isfield(widgets,'XLimitsContainer')
                        if all(strcmp(this.Target.AxesGrid.XLimMode,'auto'))
                            widgets.XLimitsContainer.AutoScale = true;
                        else
                            widgets.XLimitsContainer.Limits = getxlim(this.Target.AxesGrid);
                        end
                    end
                    if isfield(widgets,'YLimitsContainer')
                        if all(strcmp(this.Target.AxesGrid.YLimMode,'auto'))
                            widgets.YLimitsContainer.AutoScale = true;
                        else
                            widgets.YLimitsContainer.Limits = getylim(this.Target.AxesGrid);
                        end
                    end
                catch ex
                    
                end
            end
            close@controllib.ui.internal.dialog.AbstractDialog(this);
        end
    end

    methods (Access = protected)
        function buildUI(this)
            % Parent Layout
            this.GridLayout = uigridlayout(this.UIFigure,[2 1]);
            this.GridLayout.RowHeight = {'1x','fit'};
            this.GridLayout.ColumnWidth = {'1x'};
            this.GridLayout.Padding = 0;
            this.GridLayout.Scrollable = "on";
            % Tabs
            this.TabGroup = uitabgroup(this.GridLayout);
            for k = 1:length(this.TabLabels)
                this.Tabs(k) = uitab(this.TabGroup);
                this.Tabs(k).Title = this.TabLabels(k);
                g = uigridlayout(this.Tabs(k),[1 1]);
                g.Scrollable = "on";
            end
            % Button Panel
            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                this.GridLayout,"Help",'Commit',1);
            this.ButtonPanel.HelpButton.ButtonPushedFcn = ...
                @(es,ed) cbHelpButton(this);
            buttonPanelWidget = getWidget(this.ButtonPanel);
            buttonPanelWidget.Layout.Row = 2;
            buttonPanelWidget.Padding = [10 10 10 0];
            this.CloseButton = uibutton(buttonPanelWidget,'Text',...
                getString(message('Controllib:gui:strClose')));
            this.CloseButton.Layout.Column = 3;
            this.CloseButton.ButtonPushedFcn = @(es,ed) close(this);
            buttonPanelWidget.ColumnWidth{3} = this.ButtonPanel.ButtonWidth;
            % Set dialog size
            this.UIFigure.Position(3:4) = [470 360];
        end

        function connectUI(this)
            L = addlistener(this,'CloseEvent',@(es,ed) close(this));
            registerUIListeners(this,L,'DialogClose');
        end
    end

    methods (Access = private)
        function cbHelpButton(~)
            % RE: This dialog serves both CST and SRO and Ident
            % Precedence: CST DOC, IDENT DOC, SDO DOC
            if isempty(ver('control')) || ~license('test','Control_Toolbox')
                if isempty(ver('ident')) || ~ license('test','Identification_Toolbox')
                    utSloptimGUIHelp('axes_properties');
                else
                    identguihelp('response_properties');
                end
            else
                ctrlguihelp('response_properties');
            end
        end

        function deleteWidgets(this)
            delete(this.GridLayout);
        end
    end

    methods (Hidden)
        function w = qeGetWidgets(this)
            w.TabGroup = this.TabGroup;
            w.Tabs = this.Tabs;
            w.CloseButton = this.CloseButton;
            w.HelpButton = this.ButtonPanel.HelpButton;
        end

        function closeAndDeleteDialog(es,~)
            delete(es);
        end
    end
end