classdef DivFigureBrowserRefreshHandler < handle
    % This class manages cases where the environment in which DivFigure
    % figure architecture is used can be "refreshed". An example is MO+MPA

    % Copyright 2022 The MathWorks, Inc.
    methods(Static)
        function startListener()
            mlock;
            persistent uniqueInstance;

            if(~isempty(uniqueInstance))
                return;
            end

            uniqueInstance = message.subscribe('/gbtweb/divfigure/figureRefresh', @(varargin) (createViewsAfterBrowserRefresh()));

            function createViewsAfterBrowserRefresh()
                import matlab.internal.editor.figure.*;
                figArr = findall(groot, 'Type', 'figure');
                for i = 1:numel(figArr)
                    fig = figArr(i);
                    isLiveEditorFigure = FigureUtils.isEditorEmbeddedFigure(fig) ||...
                        FigureUtils.isEditorSnapshotFigure(fig);
                    if (~isLiveEditorFigure)
                        dfPacket = matlab.ui.internal.FigureServices.getDivFigurePacket(figArr(i));
                        message.publish('/gbtweb/divfigure/figureCreated', dfPacket);
                    end
                end
            end
        end
    end
end   