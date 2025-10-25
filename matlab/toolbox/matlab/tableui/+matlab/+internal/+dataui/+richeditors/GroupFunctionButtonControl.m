classdef GroupFunctionButtonControl < matlab.internal.dataui.richeditors.ButtonControl
    % GroupFunctionButtonControl - Interactive UI to be used as a custom
    % editor in the property inspector of the Compute By Group mode of the
    % Data Cleaner app.
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally
    %   undocumented. Its behavior may change, or it may be removed in a
    %   future release.

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties(Access = protected)
        % message IDs in tableui.xml
        ButtonLabels = {'groupinggroupsummaryLabel' ...
            'groupinggrouptransformLabel' 'groupinggroupfilterLabel'};
        ButtonTooltips = {'groupinggroupsummaryTooltip' ...
            'groupinggrouptransformTooltip' 'groupinggroupfilterTooltip'};
        % IDs of icons in icon ID catalog
        ButtonIcons = {'groupSummaryPlot' ...
            'groupTransformPlot' 'groupFilterPlot'};
        % Value corresponds to State.FcnType
        DefaultValue = 1;
    end
end