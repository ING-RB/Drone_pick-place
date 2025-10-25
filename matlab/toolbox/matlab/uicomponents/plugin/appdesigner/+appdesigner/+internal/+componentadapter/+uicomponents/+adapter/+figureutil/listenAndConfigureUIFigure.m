function onCleanupObjects = listenAndConfigureUIFigure()
    % Apply default value settings to a newly instantiated figure upon
    % loading from a serialized file or when copying a UIFigure.
    % This ensures children under this figure have the correct default
    % property values.
    % For example:
    %    default FontSize for uipanel: 12px
    % see g1573715 and g1680194.

    % Copyright 2017-2022 The MathWorks, Inc.

    % apply the figures default system to all the components

    figureCreatedListener = event.listener(?matlab.ui.Figure, 'InstanceCreated', ...
        @(o,e) appdesigner.internal.componentadapter.uicomponents.adapter.figureutil.setAppDesignerDefaultsOnFigure(e.Instance));
    
    figureCreatedRemover = onCleanup(@()delete(figureCreatedListener));
    onCleanupObjects = figureCreatedRemover;

    % Remove defaults on groot object so that figure create would not apply
    % defaults, like CreateFcn in App Designer
    grootDefaultRestorer = appdesigner.internal.componentadapter.uicomponents.adapter.figureutil.overrideCustomAppBuildingDefaults();
    onCleanupObjects = [onCleanupObjects grootDefaultRestorer];

    % Set UAC to be in design-time to avoid default behavior, like
    % CreateFcn to be triggered
    % We cannot use a similar way as the above figure listener to set
    % defaults because UAC's internal components are instantiated
    % within its contstructor.
    matlab.ui.componentcontainer.ComponentContainer.componentObjectBeingLoadedInAppDesigner(true);
    cleanupObjForUAC = onCleanup(@() matlab.ui.componentcontainer.ComponentContainer.componentObjectBeingLoadedInAppDesigner(false));

    onCleanupObjects = [onCleanupObjects cleanupObjForUAC];
end