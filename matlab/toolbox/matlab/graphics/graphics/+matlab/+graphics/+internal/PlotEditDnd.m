classdef PlotEditDnd
    %   class to handle plotting logic when drag and drop occurs in figures

    %   Copyright 2006-2020 The MathWorks, Inc.

    methods (Static)

        function updatePlotEdit(hFig, plotEditValue)
            channel = "/embeddedfigure/ServerToClient"+ matlab.ui.internal.FigureServices.getUniqueChannelId(hFig);

            plotEditUpdateFcn = @() message.publish(channel , struct('eventType', 'PlotEdit', 'value', plotEditValue));
            % Use dispatchWhenViewIsReady to make sure that the
            % embedded figure subscriptions are ready before publishing the
            % message
            matlab.ui.internal.dialog.DialogHelper.dispatchWhenViewIsReady(hFig, plotEditUpdateFcn);
        end

        %       to handle the case when the drop occurs on a figure which is not
        %       gcf
        function fig = getFigureFromChannel(figChannel)
            r = groot;
            for i = 1:length(r.Children)
                channel = matlab.ui.internal.FigureServices.getUniqueChannelId(r.Children(i));
                if strcmp(channel,figChannel)
                    fig = r.Children(i);
                    break;
                end
            end
        end

        % Logic for getting variables which can be plotted
        % Only vectors, numerocs and timeseries can be plotted
        % Returns a boolean for testing purposes.
        function isPlottable = getPlottableVars(varnames, figPosX, figPosY, figChannel)
            variables = split(varnames,",");
            plottableVars = {};
            for i = 1:length(variables)
%               using caller workspace instead of base to enable
%               plotting when debugging
                var = evalin('caller', variables{i});
                if(isnumeric(var) || islogical(var) || isa(var, 'timeseries') || isa(var, 'datetime'))
                    plottableVars{end+1} = var; %#ok<AGROW> 
                end
            end
            if(isempty (plottableVars))
                isPlottable = false;
                return 
            end
            isPlottable = true;
            fig = matlab.graphics.internal.PlotEditDnd.getFigureFromChannel(figChannel);
            matlab.graphics.internal.PlotEditDnd.selectPlotForDnd(plottableVars, figPosX, figPosY, fig);
        end

        %Logic for plotting when drag and drop in plotedit
        function selectPlotForDnd(plottableVars, figPosX, figPosY, fig)
            [jax, is3d, isPolar, isHandleInvisible] = plottoolfunc("prepareAxesForDnD",fig,[figPosX,figPosY]);
            if isHandleInvisible
                return
            end
            set (fig, 'CurrentAxes', jax);
            for i = 1:length(plottableVars)
                var = plottableVars{i};
                try
                    if ~is3d
                        if isPolar
                            polarplot(jax, var);
                        else
                            plot(var);
                        end
                    else
                        if isvector(var)
                            plot3(var, var, var);
                        else
                            surf(jax, var);
                        end
                    end
                catch
                end
            end
        end
    end
end

