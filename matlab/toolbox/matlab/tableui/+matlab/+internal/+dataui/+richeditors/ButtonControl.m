classdef ButtonControl < internal.matlab.inspector.editors.UserRichEditorUI
    % Abstract class to create a button group custom control in the
    % property inspector in the Data Cleaner app.
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (Abstract, Access=protected)
        % Message IDs in tableui.xml
        ButtonLabels    cell
        ButtonTooltips  cell
        % IDs of icons in icon ID catalog
        ButtonIcons     cell
        % Initial Value of the control
        DefaultValue
    end

    properties (Hidden)
        % Button group accessible at command line for dev and testing
        ButtonGroup    matlab.ui.container.ButtonGroup
    end

    properties (Constant, Access=protected)
        % Constant values used in the layout
        IconWidth = 200;
        IconHeight = 60;
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        % ValueChangedFcn callback property will be generated
        % Useful for dev and testing
        ValueChanged
    end

    methods (Access=protected)
        function setup(ui)
            % Method required by ComponentContainer
            % Set up instance of ButtonControl

            % property inspector places the ComponentContainer in a grid,
            % remove extra spacing from that grid
            ui.Parent.Padding = 0;

            % Set initial position of component
            % Only used for development and testing
            numButtons = numel(ui.ButtonLabels);
            % Generate layout:
            % A main grid with panels so user sees outline of subgrids
            % containing labels and controls
            mainGrid = uigridlayout(ui,"BackgroundColor",[1 1 1],...
                "ColumnWidth",{ui.IconWidth+2},"RowHeight",{numButtons*ui.IconHeight+2},"Padding",0);
            ui.ButtonGroup = uibuttongroup(mainGrid,'BorderType','none','BackgroundColor',[1 1 1],...
                'Tag','FcnTypeButtonGroup','SelectionChangedFcn',@ui.handleValueChanged);

            for k = 1:numButtons
                b = uitogglebutton(ui.ButtonGroup,...
                    'Position',[1 (numButtons-k)*ui.IconHeight+1 ui.IconWidth-1 ui.IconHeight-1],...
                    'HorizontalAlignment','left','IconAlignment','left','UserData',k,...
                    'Text',strrep(getString(message(['MATLAB:tableui:' ui.ButtonLabels{k}])),newline,' '),...
                    'Tooltip',getString(message(['MATLAB:tableui:' ui.ButtonTooltips{k}])));
                matlab.ui.control.internal.specifyIconID(b,ui.ButtonIcons{k},50,40);                
            end
            ui.Value = ui.DefaultValue;
        end

        function update(ui)
            % Method required by ComponentContainer
            % Update ui after setting Value property externally
            ui.ButtonGroup.SelectedObject = ui.ButtonGroup.Buttons(ui.Value);
        end

        function handleValueChanged(ui,~,~)
            % Update Value property based on change in control values
            ui.Value(1) = ui.ButtonGroup.SelectedObject.UserData;
            % Notify external objects that this ui's Value has changed
            notify(ui,'ValueChanged'); % Notify other listeners (e.g. test)
            notifyValueChanged(ui,ui.Value); % Notify prop inspector
        end
    end

    methods (Access=public)
        function L = getPropertyLabel(ui)
            % Label to show in Property inspector when ui is collapsed
            L = ui.ButtonGroup.SelectedObject.Text;
        end

        function s = getEditorSize(ui)
            s = [ui.IconWidth numel(ui.ButtonLabels)*ui.IconHeight] + 2;
        end
    end
end
