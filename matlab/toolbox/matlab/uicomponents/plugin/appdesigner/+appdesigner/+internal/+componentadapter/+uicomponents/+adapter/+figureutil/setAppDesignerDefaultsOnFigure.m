function setAppDesignerDefaultsOnFigure(figOrComponentContainer)
    % We noticed that there're differences for defaults between figure
    % and uifigure, for instance, defaultUIPanelBorderColor is [1 1 1] under figure,
    % but it's [0.49002 0.49002 0.49002] under uifigure.
    % Given that we do not know how many properties may have this kind of 
    % difference among these defaults, we're going to just apply CreateFcn
    % default, and fix UIPanelBorderColor issue in 
    % matlab.ui.internal.FigureServices.getDefaultObjectPropertiesForAppBuilding

    % Copyright 2022 The MathWorks, Inc.

    appdesigner.internal.componentadapter.uicomponents.adapter.figureutil.overrideCustomAppBuildingDefaults(figOrComponentContainer);

    if isa(figOrComponentContainer, "matlab.ui.Figure")
        figOrComponentContainer.HasAppBuildingDefaults = true; 
    end

    % Apply custom app building defaults
    matlab.ui.internal.FigureServices.setAppBuildingDefaults(figOrComponentContainer);
end