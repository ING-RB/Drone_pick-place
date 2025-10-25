function h = stepplot(ax,sysList,inputNames,outputNames,PlotOptions)

if isempty(ax)
    ax = gca;
end

if isempty(PlotOptions)
    PlotOptions = plotopts.TimeOptions.empty;
end

createNewPlot = true;

h = controllib.chart.internal.utils.getCurrentControlsChart(ax);
if ~isempty(h) && isvalid(h)
    % If ax belongs to a AbstractPlot, check if hold is on
    if strcmp(h.NextPlot,'add')
        % hold is on, add system to current plot and set createNewPlot flag
        % to false
        for k = 1:length(sysList)
            addSystem(h,sysList(k).System,SystemName=sysList(k).Name);
        end
        createNewPlot = false;
    else
        % hold is off, delete current plot and set flag to create new plot
        cla(ax);
    end
else
    % ax does not belong to a Controls plot
    ax.Visible = 'off';
end

if createNewPlot
    h = controllib.chart.StepPlot("SystemModels",{sysList.System},"SystemNames",{sysList.Name},...
        "Axes",ax,"InputNames",inputNames,"OutputNames",outputNames,"Options",PlotOptions);

    % Call drawnow to start drawing canvas and make plot visible
    drawnow nocallbacks limitrate

    % Create data tips after the plot is visible
    createDataTips(h);
end
