function doLayout(pc)
%

%   Copyright 2018-2023 The MathWorks, Inc.

% Set Legend visibility
updateLegendVisibility(pc);
updateLegend(pc)

% Update labels, tick-labels, and axis limits
updateXTicks(pc);

% Update font name and size on y-rulers
updateFont(pc);

% Update Coordinate and Data Labels
updateLabels(pc);
end

function updateXTicks(pc)
% Add X-Tick Labels
if strcmp(pc.CoordinateTickLabelsMode,'auto')
    pc.Axes.TickLabelInterpreter= 'none';
    if pc.UsingTableForData && ~isempty(pc.VariableName)
        pc.CoordinateTickLabels_I = strrep(pc.VariableName,newline,' ');
    elseif ~pc.UsingTableForData
        ind = pc.CoordinateData_I;
        if islogical(ind)
            ind = find(ind);
        end
        pc.CoordinateTickLabels_I = ind;
    end
end
pc.Axes.XAxis.TickLabels = pc.CoordinateTickLabels_I;
end

function updateLabels(pc)
% Update the labels when the mode is manual
if strcmp(pc.CoordinateLabelMode,'manual')
    pc.Axes.XAxis.Label.String_I = pc.CoordinateLabel_I;
    pc.Axes.XAxis.Label.StringMode = 'manual';
end

if strcmp(pc.DataLabelMode,'manual')
    pc.Axes.YAxis(1).Label.String_I = pc.DataLabel_I;
    pc.Axes.YAxis(1).Label.StringMode = 'manual';
end
% Update datatip configuration when labels are updated.
pc.initializeDataTipConfiguration();
end

function updateFont(pc)
% Updating axes does not update additional Y-Rulers automatically
% Needs to be done here explicitly
rulers = pc.Axes.YAxis(2:end);
for idx = 1:numel(rulers)
    rulers(idx).FontName = pc.Axes.FontName_I;
    rulers(idx).FontSize = pc.Axes.FontSize_I;
end
end
