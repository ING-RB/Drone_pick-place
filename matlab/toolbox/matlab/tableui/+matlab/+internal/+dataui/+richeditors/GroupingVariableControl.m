classdef GroupingVariableControl < internal.matlab.inspector.editors.UserRichEditorUI
    % GroupingVariableControl - Interactive UI to be used as a custom
    % editor in the property inspector of the Compute By Group mode of the
    % Data Cleaner app.
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (Hidden)
        % Containers in the ui
        MainGrid            matlab.ui.container.GridLayout
        CheckboxGrid        matlab.ui.container.GridLayout
        BinningSchemeGrid   matlab.ui.container.GridLayout
        OptionsGrid         matlab.ui.container.GridLayout
        % Controls in the ui
        GroupByLabel        matlab.ui.control.Label
        BinningMethodLabel  matlab.ui.control.Label
        OptionsLabel        matlab.ui.control.Label
        Checkboxes          matlab.ui.control.CheckBox
        BinningDDs          matlab.ui.control.DropDown
        NumBinsSpinners     matlab.ui.control.Spinner
        TimeBinDDs          matlab.ui.control.DropDown
        BinWidthSpinners    matlab.ui.control.Spinner
        BinWidthUnitsDDs    matlab.ui.control.DropDown
    end

    properties(Constant,Access=private)
        % Constant values used in the layout
        BackGroundColor = [.98 .98 .98];
        Pad = 4;
        RowHeight = 24;
        RowSpacing = 1;
        TitleRowHeight = 26;
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        % ValueChangedFcn callback property will be generated
        % Used for testing
        ValueChanged
    end

    methods (Access=protected)
        function setup(ui)
            % Method required by ComponentContainer
            % Set up instance of GroupingVariableControl

            % property inspector places the ComponentContainer in a grid,
            % remove extra spacing from that grid
            ui.Parent.Padding = 0;

            % Generate layout:
            % A main grid with panels so user sees outline of subgrids
            % containing labels and controls
            ui.MainGrid = uigridlayout(ui,"BackgroundColor",[1 1 1],...
                "ColumnWidth",{'fit','fit','fit'},...
                "RowHeight",{ui.TitleRowHeight 'fit'},...
                "ColumnSpacing",0,"RowSpacing",0,"scrollable","on","Padding",0);
            p = uipanel(ui.MainGrid); % box for grouping variable label
            labelHeight = ui.TitleRowHeight - ui.Pad;
            g = uigridlayout(p,"ColumnWidth",{'fit'},"RowHeight",labelHeight,"Padding",ui.Pad);
            ui.GroupByLabel = uilabel(g,"Text",getString(message('MATLAB:tableui:groupingGroupingVariable')),"FontWeight","bold");
            p = uipanel(ui.MainGrid); % box for binning scheme label
            g = uigridlayout(p,"ColumnWidth",{'fit'},"RowHeight",labelHeight,"Padding",ui.Pad);
            ui.BinningMethodLabel = uilabel(g,"Text",getString(message('MATLAB:tableui:groupingBinningMethod')),"FontWeight","bold");
            p = uipanel(ui.MainGrid); % box for options label
            g = uigridlayout(p,"ColumnWidth",{'fit'},"RowHeight",labelHeight,"Padding",ui.Pad);
            ui.OptionsLabel = uilabel(g,"Text",getString(message('MATLAB:tableui:groupingOptions')),"FontWeight","bold");
            p = uipanel(ui.MainGrid); % box for checkboxes
            ui.CheckboxGrid = uigridlayout(p,"ColumnWidth",{'fit'},...
                "RowHeight",ui.RowHeight,"Padding",ui.Pad,"RowSpacing",ui.RowSpacing);
            p = uipanel(ui.MainGrid); % box for binning scheme
            ui.BinningSchemeGrid = uigridlayout(p,"ColumnWidth",{'fit'},...
                "RowHeight",ui.RowHeight,"Padding",ui.Pad,"RowSpacing",ui.RowSpacing);
            p = uipanel(ui.MainGrid); % box for options
            ui.OptionsGrid = uigridlayout(p,"ColumnWidth",{'fit' 'fit'},...
                "RowHeight",ui.RowHeight,"Padding",ui.Pad,"RowSpacing",ui.RowSpacing,"ColumnSpacing",0);

            % Initialize controls
            addRowOfControls(ui,1);

            % Set (placeholder) default Value
            val = struct;
            val.TableVarNames = {ui.Checkboxes.Text};
            val.GroupTableVarDDValue = {ui.Checkboxes.Text};
            val.BinningDropdownItems = {ui.BinningDDs.Items};
            val.BinningDropdownItemsData = {ui.BinningDDs.ItemsData};
            val.BinningDropdownValue = {ui.BinningDDs.Value};
            val.NumBinsSpinnerValue = ui.NumBinsSpinners.Value;
            val.TimeBinDDItems = {ui.TimeBinDDs.Items};
            val.TimeBinDDItemsData = {ui.TimeBinDDs.ItemsData};
            val.TimeBinDDValue = {ui.TimeBinDDs.Value};
            val.BinWidthSpinnerValue = ui.BinWidthSpinners.Value;
            val.BinWidthUnitsDDItems = {ui.BinWidthUnitsDDs.Items};
            val.BinWidthUnitsDDItemsData = {ui.BinWidthUnitsDDs.ItemsData};
            val.BinWidthUnitsDDValue = {ui.BinWidthUnitsDDs.Value};
            ui.Value = val;
        end

        function addRowOfControls(ui,k)
            % Add a row of controls to the ui
            % column 1, checkboxes
            ui.Checkboxes(k) = uicheckbox(ui.CheckboxGrid,"Value",false,...
                "ValueChangedFcn",@ui.handleValueChanged);
            ui.Checkboxes(k).Layout.Row = k;
            % column 2, binning scheme: prepopulate with only the default
            % item since the dropdown appears just before the state from
            % the live task can populate it
            ui.BinningDDs(k) = uidropdown(ui.BinningSchemeGrid,...
                "ValueChangedFcn",@ui.handleValueChanged,...
                'Items',{getString(message('MATLAB:tableui:groupingnone'))});
            ui.BinningDDs(k).Layout.Row = k;
            % column 3.1, options(1)
            ui.NumBinsSpinners(k) = uispinner(ui.OptionsGrid,...
                'RoundFractionalValues',true,'Limits',[1 inf],...
                'UpperLimitInclusive',false,"ValueChangedFcn",@ui.handleValueChanged);
            ui.NumBinsSpinners(k).Layout.Row = k;
            ui.NumBinsSpinners(k).Layout.Column = 1;
            ui.TimeBinDDs(k) = uidropdown(ui.OptionsGrid,"ValueChangedFcn",@ui.handleValueChanged);
            ui.TimeBinDDs(k).Layout.Row = k;
            ui.TimeBinDDs(k).Layout.Column = 1;
            ui.BinWidthSpinners(k) = uispinner(ui.OptionsGrid,...
                'Limits',[0 inf],'LowerLimitInclusive',false,...
                'UpperLimitInclusive',false,"ValueChangedFcn",@ui.handleValueChanged);
            ui.BinWidthSpinners(k).Layout.Row = k;
            ui.BinWidthSpinners(k).Layout.Column = 1;
            % column 3.2, options(2)
            ui.BinWidthUnitsDDs(k) = uidropdown(ui.OptionsGrid,"ValueChangedFcn",@ui.handleValueChanged);
            ui.BinWidthUnitsDDs(k).Layout.Row = k;
            ui.BinWidthUnitsDDs(k).Layout.Column = 2;
        end

        function deleteRowOfControls(ui,k)
            % Delete a row of controls from the ui
            % delete controls
            delete(ui.Checkboxes(k));
            delete(ui.BinningDDs(k));
            delete(ui.NumBinsSpinners(k));
            delete(ui.TimeBinDDs(k));
            delete(ui.BinWidthSpinners(k));
            delete(ui.BinWidthUnitsDDs(k));
            % delete handles
            ui.Checkboxes(k) = [];
            ui.BinningDDs(k) = [];
            ui.NumBinsSpinners(k) = [];
            ui.TimeBinDDs(k) = [];
            ui.BinWidthSpinners(k) = [];
            ui.BinWidthUnitsDDs(k)= [];
        end

        function update(ui)
            % Method required by ComponentContainer
            % Update ui after setting properties

            if ~isequal(ui.Value.TableVarNames,{ui.Checkboxes.Text})
                % Add/remove rows as needed
                N = numel(ui.Value.TableVarNames);
                for k = numel(ui.Checkboxes): -1 : N+1
                    deleteRowOfControls(ui,k);
                end
                for k = numel(ui.Checkboxes)+1 : N
                    addRowOfControls(ui,k);
                end
                % Update height of subgrids
                rowHeight = ui.RowHeight*ones(1,N);
                ui.CheckboxGrid.RowHeight = rowHeight;
                ui.BinningSchemeGrid.RowHeight = rowHeight;
                ui.OptionsGrid.RowHeight = rowHeight;
                % Update labels
                [ui.Checkboxes.Text] = deal(ui.Value.TableVarNames{:});
            end

            % Update controls based on Value
            for k = 1:numel(ui.Checkboxes)
                [tf,loc] = ismember(ui.Checkboxes(k).Text,ui.Value.GroupTableVarDDValue);
                if tf
                    % select var as grouping var
                    ui.Checkboxes(k).Value = true; %#ok<*MCSUP>
                    % update items/values of controls in that row
                    ui.BinningDDs(k).Items = ui.Value.BinningDropdownItems{loc};
                    ui.BinningDDs(k).ItemsData = ui.Value.BinningDropdownItemsData{loc};
                    ui.BinningDDs(k).Value = ui.Value.BinningDropdownValue{loc};
                    ui.NumBinsSpinners(k).Value = ui.Value.NumBinsSpinnerValue(loc);
                    ui.TimeBinDDs(k).Items = ui.Value.TimeBinDDItems{loc};
                    ui.TimeBinDDs(k).ItemsData = ui.Value.TimeBinDDItemsData{loc};
                    ui.TimeBinDDs(k).Value = ui.Value.TimeBinDDValue{loc};
                    ui.BinWidthSpinners(k).Value = ui.Value.BinWidthSpinnerValue(loc);
                    ui.BinWidthUnitsDDs(k).Items = ui.Value.BinWidthUnitsDDItems{loc};
                    ui.BinWidthUnitsDDs(k).ItemsData = ui.Value.BinWidthUnitsDDItemsData{loc};
                    ui.BinWidthUnitsDDs(k).Value = ui.Value.BinWidthUnitsDDValue{loc};
                else
                    % Unselect var as grouping var
                    ui.Checkboxes(k).Value = false;
                end
            end
            updateVisibility(ui);
        end

        function handleValueChanged(ui,~,~)
            % Update ui Value based on change in control values
            val = struct();
            val.TableVarNames = {ui.Checkboxes.Text};
            inds = [ui.Checkboxes.Value];
            val.GroupTableVarDDValue = {ui.Checkboxes(inds).Text};
            val.BinningDropdownItems = {ui.BinningDDs(inds).Items};
            val.BinningDropdownItemsData = {ui.BinningDDs(inds).ItemsData};
            val.BinningDropdownValue = {ui.BinningDDs(inds).Value};
            val.NumBinsSpinnerValue = [ui.NumBinsSpinners(inds).Value];
            val.TimeBinDDItems = {ui.TimeBinDDs(inds).Items};
            val.TimeBinDDItemsData = {ui.TimeBinDDs(inds).ItemsData};
            val.TimeBinDDValue = {ui.TimeBinDDs(inds).Value};
            val.BinWidthSpinnerValue = [ui.BinWidthSpinners(inds).Value];
            val.BinWidthUnitsDDItems = {ui.BinWidthUnitsDDs(inds).Items};
            val.BinWidthUnitsDDItemsData = {ui.BinWidthUnitsDDs(inds).ItemsData};
            val.BinWidthUnitsDDValue = {ui.BinWidthUnitsDDs(inds).Value};
            ui.Value = val;
            % Notify external objects that this ui's Value has changed
            notifyValueChanged(ui,ui.Value);
            notify(ui,'ValueChanged');
            % Update the visibility of the ui
            updateVisibility(ui);
        end

        function updateVisibility(ui)
            % Set visibility of controls
            for k = 1:numel(ui.Checkboxes)
                if ui.Checkboxes(k).Value
                    ui.BinningDDs(k).Visible = true;
                    scheme = ui.BinningDDs(k).Value;
                    ui.NumBinsSpinners(k).Visible = isequal(scheme,'numBins');
                    ui.TimeBinDDs(k).Visible = isequal(scheme,'timeBins');
                    ui.BinWidthSpinners(k).Visible = isequal(scheme,'binWidth');
                    ui.BinWidthUnitsDDs(k).Visible = isequal(scheme,'binWidth');
                else
                    ui.BinningDDs(k).Visible = false;
                    ui.NumBinsSpinners(k).Visible = false;
                    ui.TimeBinDDs(k).Visible = false;
                    ui.BinWidthSpinners(k).Visible = false;
                    ui.BinWidthUnitsDDs(k).Visible = false;
                end
            end
            % Unparent invisible widgets
            matlab.internal.dataui.setParentForWidgets(ui.BinningDDs,ui.BinningSchemeGrid);
            matlab.internal.dataui.setParentForWidgets([ui.NumBinsSpinners ...
                ui.TimeBinDDs ui.BinWidthSpinners ui.BinWidthUnitsDDs],ui.OptionsGrid);
        end
    end

    methods
        function S = getEditorSize(ui)
            % Get the width and height to set the size of the parent figure

            % Use ui.Value instead of the uicontrols because this may get
            % called before the ui gets a chance to update. We only need a
            % good estimate here. If the control is too large, the ui is
            % scrollable, so it is ok if we are a little bit off.

            % Checkboxes column is based on table var names
            col1 = max(strlength(string(ui.Value.TableVarNames)))*10;
            % English width using "fit" when all dropdown options are present
            col2 = 160;
            % Each options column of controls is about 100, when visible
            hasCol3a = ~all(strcmp(ui.Value.BinningDropdownValue,'none'));
            hasCol3b = any(strcmp(ui.Value.BinningDropdownValue,'binwidth'));
            col3 = max(strlength(ui.OptionsLabel.Text)*8,(hasCol3a + hasCol3b)*100);
            width = col1 + col2 + col3 + 8*ui.Pad;

            % Height is easier to calculate since we set it explicitly
            % But since tables can have so many variables, cap the pixel
            % height at 1000 and let user scroll
            N = numel(ui.Value.TableVarNames);
            height = min(ui.TitleRowHeight + N*ui.RowHeight + (N+3)*ui.Pad,1000);

            S = [width height];
        end

        function L = getPropertyLabel(ui)
            % Label to show in Property inspector when ui is collapsed
            % Comma separated list of variables selected as grouping vars
            L = strjoin(ui.Value.GroupTableVarDDValue,', ');
        end

        function richEditorClosed(ui)
            ui.ProxyClass.notifyPropsAndDataChange();
        end
    end
end