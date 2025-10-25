function h = bodeplot(ax,sysList,inputNames,outputNames,PlotOptions)

if isempty(ax)
    ax = gca;
    ax.Visible = 'off';
end

if isempty(PlotOptions)
    PlotOptions = plotopts.BodeOptions.empty;
end

h = controllib.chart.BodePlot("SystemModels",{sysList.System},"SystemNames",{sysList.Name},...
    "Axes",ax,"InputNames",inputNames,"OutputNames",outputNames,"Options",PlotOptions);

% Call drawnow to start drawing canvas and make plot visible 
drawnow nocallbacks limitrate

% Create data tips after the plot is visible
createDataTips(h);
end