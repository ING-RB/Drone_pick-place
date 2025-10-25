classdef JoinKeysControl < internal.matlab.inspector.editors.UserRichEditorUI
    % JoinKeysControl - Interactive UI to be used as a custom editor
    % in the property inspector of the Join Tables mode of the Data
    % Cleaner app.
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (Hidden)
        % Containers in the ui
        MainGrid            matlab.ui.container.GridLayout
        LeftKeysGrid        matlab.ui.container.GridLayout
        RightKeysGrid       matlab.ui.container.GridLayout
        IconGrid            matlab.ui.container.GridLayout
        % Controls in the ui
        LeftKeysDD          matlab.ui.control.DropDown
        RightKeysDD         matlab.ui.control.DropDown
        AddButton           matlab.ui.control.Image
        SubtractButton      matlab.ui.control.Image
    end

    properties (Constant,Access=private)
        % Constant values used in the layout
        DropDownWidth = 120;
        IconWidth = 16;
        TextRowHeight = 22;
        TitleRowHeight = 26;
        Pad = 4;
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        % ValueChangedFcn callback property will be generated
        ValueChanged
    end

    methods (Access=protected)
        function setup(ui)
            % Method required by ComponentContainer
            % Set up instance of JoinKeysControl

            % property inspector places the ComponentContainer in a grid,
            % remove extra spacing from that grid
            ui.Parent.Padding = 0;

            % Main grid will hold panels for outlines
            % Each non-empty panel holds a grid for controls or a label
            ui.MainGrid = uigridlayout(ui,"BackgroundColor",[1 1 1],...
                "ColumnWidth",{'fit','fit',2*ui.IconWidth+3*ui.Pad},...
                "RowHeight",{ui.TitleRowHeight 'fit'},"Padding",0,...
                "ColumnSpacing",0,"RowSpacing",0,"scrollable","on");
            p = uipanel(ui.MainGrid); % box for left keys label
            labelHeight = ui.TitleRowHeight - ui.Pad;
            g = uigridlayout(p,"ColumnWidth",{'fit'},"RowHeight",labelHeight,"Padding",ui.Pad);
            uilabel(g,'Text',getString(message('MATLAB:tableui:tableJoinerLeftKeys')),"FontWeight","bold");
            p = uipanel(ui.MainGrid); % box for right keys label
            g = uigridlayout(p,"ColumnWidth",{'fit'},"RowHeight",labelHeight,"Padding",ui.Pad);
            uilabel(g,'Text',getString(message('MATLAB:tableui:tableJoinerRightKeys')),"FontWeight","bold");
            uipanel(ui.MainGrid); % empty box above +/- icon column
            p = uipanel(ui.MainGrid); % box for left keys
            ui.LeftKeysGrid = uigridlayout(p,"ColumnWidth",{ui.DropDownWidth},...
                "RowHeight",repmat({ui.TextRowHeight},1,5),"Padding",ui.Pad,...
                "RowSpacing",ui.Pad);
            p = uipanel(ui.MainGrid); % box for right keys
            ui.RightKeysGrid = uigridlayout(p,"ColumnWidth",{ui.DropDownWidth},...
                "RowHeight",repmat({ui.TextRowHeight},1,5),"Padding",ui.Pad,...
                "RowSpacing",ui.Pad);
            p = uipanel(ui.MainGrid); % box +/- icons
            ui.IconGrid = uigridlayout(p,"ColumnWidth",{ui.IconWidth ui.IconWidth},...
                "RowHeight",repmat({ui.TextRowHeight},1,5),"Padding",ui.Pad,...
                "ColumnSpacing",ui.Pad,"RowSpacing",ui.Pad);

            for k = 1:5
                ui.LeftKeysDD(k) = uidropdown(ui.LeftKeysGrid,...
                    'ValueChangedFcn',@ui.handleValueChanged);
                ui.RightKeysDD(k) = uidropdown(ui.RightKeysGrid,...
                    'ValueChangedFcn',@ui.handleValueChanged);
                ui.SubtractButton(k) = uiimage(ui.IconGrid,'ScaleMethod','none',...
                    'ImageClickedFcn',@ui.subtractKey,'UserData',k);
                matlab.ui.control.internal.specifyIconID(ui.SubtractButton(k),'minusUI',16,16);
                ui.AddButton(k) = uiimage(ui.IconGrid,'ScaleMethod','none',...
                    'ImageClickedFcn',@ui.addKey);
                matlab.ui.control.internal.specifyIconID(ui.AddButton(k),'plusUI',16,16);
            end
            % Set (placeholder) default Value
            ui.Value = struct('NumKeyRows',1,'MaxNumKeyRows',5);
            setValueFromControls(ui);
        end

        function update(ui)
            % Method required by ComponentContainer
            % Update ui after setting properties

            % Update controls based on Value
            [ui.LeftKeysDD.Items] = deal(ui.Value.LeftKeysDDItems{:});
            [ui.LeftKeysDD.Value] = deal(ui.Value.LeftKeysDDValues{:});
            [ui.RightKeysDD.Items] = deal(ui.Value.RightKeysDDItems{:});
            [ui.RightKeysDD.Value] = deal(ui.Value.RightKeysDDValues{:});

            updateVisibility(ui);
        end

        function handleValueChanged(ui,~,~)
            % Update ui Value based on change in control values
            setValueFromControls(ui);
            % Notify external objects that this ui's Value has changed
            notifyValueChanged(ui,ui.Value);
            notify(ui,'ValueChanged');
            % Update the visibility of the ui
            updateVisibility(ui);
        end

        function subtractKey(ui,src,~)
            ui.Value.NumKeyRows = max(ui.Value.NumKeyRows - 1, 1);
            for k = src.UserData : ui.Value.NumKeyRows
                ui.LeftKeysDD(k).Value =  ui.LeftKeysDD(k+1).Value;
                ui.RightKeysDD(k).Items =  ui.RightKeysDD(k+1).Items;
                ui.RightKeysDD(k).Value =  ui.RightKeysDD(k+1).Value;
            end
            handleValueChanged(ui);
        end

        function addKey(ui,~,~)
            ui.Value.NumKeyRows = min(ui.Value.NumKeyRows + 1,ui.Value.MaxNumKeyRows);
            handleValueChanged(ui);
        end

        function setValueFromControls(ui)
            val = struct;
            val.LeftKeysDDValues = {ui.LeftKeysDD.Value};
            val.LeftKeysDDItems = {ui.LeftKeysDD.Items};
            val.RightKeysDDValues = {ui.RightKeysDD.Value};
            val.RightKeysDDItems = {ui.RightKeysDD.Items};
            val.NumKeyRows = ui.Value.NumKeyRows;
            val.MaxNumKeyRows = ui.Value.MaxNumKeyRows;
            ui.Value = val;
        end

        function updateVisibility(ui)
            % Set visibility of controls
            for k = 1:5
                showRow = k <= ui.Value.NumKeyRows;
                ui.LeftKeysDD(k).Visible = showRow;
                ui.RightKeysDD(k).Visible = showRow;
                ui.SubtractButton(k).Visible = showRow && ui.Value.NumKeyRows > 1;
                ui.AddButton(k).Visible = showRow && ui.Value.NumKeyRows < ui.Value.MaxNumKeyRows;
                ui.LeftKeysGrid.RowHeight{k} = ui.TextRowHeight*showRow;
                ui.RightKeysGrid.RowHeight{k} = ui.TextRowHeight*showRow;
                ui.IconGrid.RowHeight{k} = ui.TextRowHeight*showRow;
            end
            % hide subtract/add columns if none visible
            ui.IconGrid.ColumnWidth{1} = ui.IconWidth*any([ui.SubtractButton.Visible]);
            ui.IconGrid.ColumnWidth{2} = ui.IconWidth*any([ui.AddButton.Visible]);

            % set tooltips for right key dds
            isemptyDD = cellfun(@isempty,{ui.RightKeysDD.Items});
            [ui.RightKeysDD(isemptyDD).Tooltip] = deal(getString(message('MATLAB:tableui:tableJoinerTooltipKeyVariablesEmpty')));
            [ui.RightKeysDD(~isemptyDD).Tooltip] = deal('');
        end
    end

    methods
        function L = getPropertyLabel(ui)
            % Label to show in Property inspector when ui is collapsed:
            % Comma separated list of variables selected as key vars
            % L1,R1,L2,R2,etc

            % Some of the left keys may not have a valid right key
            ind = ~cellfun(@isempty,{ui.RightKeysDD.Items}) & [ui.RightKeysDD.Visible];
            if any(ind)
                L = strjoin(strcat({ui.LeftKeysDD(ind).Value},", ",...
                    {ui.RightKeysDD(ind).Value}),", ");
            else
                % No valid right keys for any of the chosen left keys
                L = " ";
            end
        end

        function s = getEditorSize(ui)
            width = 2*ui.DropDownWidth + 2*ui.IconWidth + 7*ui.Pad;
            N = ui.Value.NumKeyRows;
            height = ui.TitleRowHeight + N*ui.TextRowHeight + (N+3)*ui.Pad;
            s = [width height] + 10;
        end

        function richEditorClosed(ui)
            ui.ProxyClass.notifyPropsAndDataChange();
        end
    end
end