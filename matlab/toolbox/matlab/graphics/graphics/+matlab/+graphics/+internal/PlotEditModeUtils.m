classdef PlotEditModeUtils

% Copyright 2021 The MathWorks, Inc.

    methods (Static)
        function toggleOffNoCallbacks(btn)
            % Programmatically untoggle a uitogglebutton without triggering
            % its callback. This is critical in webfigures where callbacks
            % are triggered asynchronously so it can be impossible for code
            % which untoggles programmatically to reliably predict callback
            % effects

            if strcmp(get(btn,'State'),'on')
                if ~isempty(btn.OffCallback)
                    cachedOffCallback = btn.OffCallback;
                    % Replace the OffCallback by a temporary callback which 
                    % has no functional affect other than restoring the
                    % cached callback
                    btn.OffCallback = @(e,d) matlab.graphics.internal.drawnow.callback(@() set(btn,'OffCallback',cachedOffCallback));
                end
                set(btn,'State','off');
            end
        end

        function scribeProxyValue = getScribeProxyValue(hObj)
            hObj = handle(hObj);
            if isprop(hObj,'ScribeProxyValue')
                scribeProxyValue = hObj.ScribeProxyValue;
            else
                scribeProxyValue = string.empty;
            end
        end

        function setScribeProxyValue(hObj, scribeProxyValue)

            hObj = handle(hObj);
            if ~isprop(hObj,'ScribeProxyValue')
                p = addprop(hObj,'ScribeProxyValue');
                p.Transient = false;
                p.Hidden = true;
            end
            hObj.ScribeProxyValue = string(scribeProxyValue);
        end

        function status = isExcludedFromPlotEditInteractivity(obj)
            status = arrayfun(@(obj) ~isprop(obj,'Selected') || ...
                plotedit({'isUIComponentInUIFigure',obj}) || ...
                (isprop(obj, 'Tag')  && strcmpi(obj.Tag, 'ML_TS_Selector')), obj);
        end

        function willBeDocked = willFigureBeDockedIntoContainer(fig)
            % Returns true if the logic in FigureController will
            % automatically dock the figure

            % see updateLaunchFigureDockedSetting() in toolbox\matlab\uitools\uicomponents\components\+matlab\+ui\+internal\+controller\FigureController.m
            % Note that the logic in updateLaunchFigureDockedSetting()
            % applies when fig.FigureViewReady == "off" because it is
            % applies in the constructor before the handleClientEvent() has
            % been called to trun it on
            % Note also that fig.FigureViewReady == "off" is needed to
            % prevent willFigureBeDockedIntoContainer() returning true for
            % figure that have been interactively undocked.
            willBeDocked = ...               
                fig.FigureViewReady == "off"...
                && strcmp(fig.DefaultTools,'toolstrip')...
                && strcmp(fig.PositionMode, 'auto')...
                && strcmp(fig.OuterPositionMode, 'auto')...
                && (strcmp(fig.WindowStyle,'normal') && strcmp(fig.WindowStyleMode,'auto'));
        end

    end
end