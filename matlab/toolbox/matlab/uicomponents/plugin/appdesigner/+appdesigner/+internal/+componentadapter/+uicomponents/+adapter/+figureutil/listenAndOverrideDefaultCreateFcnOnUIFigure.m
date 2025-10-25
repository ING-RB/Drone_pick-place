function onCleanupObjects = listenAndOverrideDefaultCreateFcnOnUIFigure()
    % Override custom default CreateFcn with factory defaults to avoid
    % running it in App Designer

    % Copyright 2022 The MathWorks, Inc.

    figureCreatedListener = event.listener(?matlab.ui.Figure, 'InstanceCreated', ...
        @(o,e) appdesigner.internal.componentadapter.uicomponents.adapter.figureutil.overrideCustomAppBuildingDefaults(e.Instance, "CreateFcn"));
    
    figureCreatedRemover = onCleanup(@()delete(figureCreatedListener));
    onCleanupObjects = figureCreatedRemover;

    % Remove custom defaults on groot so that uifigure creation would not
    % apply custom defaults, for instance, defaultFigureCreateFcn
    grootDefaultRestorer = appdesigner.internal.componentadapter.uicomponents.adapter.figureutil.overrideCustomAppBuildingDefaults(groot, "CreateFcn");
    onCleanupObjects = [onCleanupObjects grootDefaultRestorer];
end