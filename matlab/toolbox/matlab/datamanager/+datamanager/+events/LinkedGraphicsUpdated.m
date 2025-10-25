classdef (ConstructOnLoad) LinkedGraphicsUpdated < event.EventData
    % LinkedGraphicsUpdated event data is dispatched by LinkPlotManager
    % whenever varNames are added/removed via data linking

    properties
        VarNames; % Cellstr of VariableNames linked to X/Y/Z DataSources.
        FigureSource; % Handle to LinkPlotMgr's Figure which contains the underlying Figure Handle.
        EventSource string % Source of the event fiiring, used to distinguish linking events from figure removal
    end
end

