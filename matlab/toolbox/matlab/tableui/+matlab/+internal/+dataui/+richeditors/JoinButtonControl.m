classdef JoinButtonControl < matlab.internal.dataui.richeditors.ButtonControl
    % JoinButtonControl - Interactive UI to be used as a custom editor in
    % the property inspector of the Join Tables mode of the Data Cleaner
    % app.
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally
    %   undocumented. Its behavior may change, or it may be removed in a
    %   future release.

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties(Access = protected)
        % message IDs in tableui.xml
        ButtonLabels = {'tableJoinerFullouterjoin' 'tableJoinerLeftouterjoin' ...
            'tableJoinerRightouterjoin' 'tableJoinerInnerjoin' 'tableJoinerJoin' 'tableJoinerHorzcat'};
        ButtonTooltips = {'tableJoinerTooltipOuterjoin' 'tableJoinerTooltipLeftOuterjoin' ...
            'tableJoinerTooltipRightOuterjoin' 'tableJoinerTooltipInnerjoin' ...
            'tableJoinerTooltipJoin' 'tableJoinerTooltipHorzcat'};
        % IDs of icons in icon ID catalog
        ButtonIcons = {'outerJoinPlot','leftOuterJoinPlot','rightOuterJoinPlot', ...
            'innerJoinPlot','joinPlot','horzCatPlot'};

        % Value corresponds to State.JoinButtonAppValue
        % Value(1) = selected button
        % Value(2) = is button 6 horzcat
        % Value(3) = is button 6 visible
        DefaultValue = [1 1 1];
    end

    methods (Access = protected)
        function update(ui)
            % Update ui after setting Value property externally
            % Overwrite inherited method so we can also set button 6
            % properties

            ui.ButtonGroup.SelectedObject = ui.ButtonGroup.Buttons(ui.Value(1));
            if ui.Value(2)
                str = 'Horzcat';
                matlab.ui.control.internal.specifyIconID(ui.ButtonGroup.Buttons(6),'horzCatPlot',50,40);
            else
                str = 'Vertcat';
                matlab.ui.control.internal.specifyIconID(ui.ButtonGroup.Buttons(6),'vertCatPlot',50,40);
            end
            ui.ButtonGroup.Buttons(6).Text = strrep(getString(message(['MATLAB:tableui:tableJoiner' str])),newline,' ');
            ui.ButtonGroup.Buttons(6).Tooltip = getString(message(['MATLAB:tableui:tableJoinerTooltip' str]));
            ui.ButtonGroup.Buttons(6).Visible = ui.Value(3);
        end
    end

    methods (Access=public)
        function s = getEditorSize(ui)
            N = 5 + ui.Value(3);
            s = [ui.IconWidth N*ui.IconHeight] + 2;
        end
    end
end