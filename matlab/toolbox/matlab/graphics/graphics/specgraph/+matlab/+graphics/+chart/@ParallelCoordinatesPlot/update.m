function update(pc)
%

%   Copyright 2018-2023 The MathWorks, Inc.

% Avoid throwing error from update
try
    % As a precaution ensure that we have a valid legend and axes
    if ~isvalid(pc.Axes) || ~isvalid(pc.Legend)
        return;
    end

    % If the data hasn't been set yet, or a data dependent property has changed
    % update the data, normalize it and add some jittering
    if pc.UpdateData
        pc.DataNormalization = pc.DataNormalization_I;
        pc.Jitter = pc.Jitter_I;
        pc.UpdateData = false;
    end

    % Validate data sizes
    validateDataSizes(pc);

    % Update the group dependent properties. Use ScatterHistogramChart's method
    % instead of duplicating it.
    [pc.LineAlpha_I,pc.LineWidth_I,pc.LineStyle_I,pc.MarkerStyle_I,pc.MarkerSize_I] =...
        matlab.graphics.chart.ScatterHistogramChart.cycleLineProperties(...
        pc.NumGroups,pc.LineAlpha_I,pc.LineWidth_I,pc.LineStyle_I,...
        pc.MarkerStyle_I,pc.MarkerSize_I);

    % Update colororder
    if pc.ColorMode == "auto" && pc.ColorOrderInternalMode == "auto" 
        co = get(pc, 'DefaultAxesColorOrder');
        coMode = get(pc, 'DefaultAxesColorOrderMode');
        if coMode == "auto"
            tc = ancestor(pc, 'matlab.graphics.mixin.ThemeContainer');
            if ~isempty(tc) && ~isempty(tc.Theme)
                co = matlab.graphics.internal.themes.getAttributeValue(tc.Theme,'DiscreteColorList');
            end
        end

        pc.ColorOrderInternal = co;
        pc.ColorOrderInternalMode = coMode;
        pc.Color_I = pc.ColorOrderInternal;
    end

    % Update Color (at this point Color is always numeric)
    if pc.NumGroups > size(pc.Color_I,1)
        pc.Color_I = repmat(pc.Color_I,pc.NumGroups,1);
    end
    pc.Color_I = pc.Color_I(1:pc.NumGroups,:);

    % Plotting routines
    if pc.UpdatePlot
        plotLines(pc);

        % Lines have just been plotted. No need to update them again.
        pc.UpdateLines = false;
        pc.UpdatePlot = false;

        % YRuler should not respond to mouse-hover
        if pc.NumColumns > 0
            yrulers = [pc.YRulers(2:end)];
            [yrulers.Limits]; %#ok<VUNUS> run update on ruler to access Axle and MajorTickChild
            set([yrulers.Axle], 'PickableParts','none','HitTest','off');
            set([yrulers.MajorTickChild], 'PickableParts','none','HitTest','off');
            set([yrulers.TickLabelChild], 'PickableParts','none');
        end

        updateAxisLims(pc);
        updateRulerTicks(pc);
    end

    % Update line properties if requested
    if pc.UpdateLines
        % For each group update the line handles
        for idy = 1:pc.NumGroups
            % Update all the lines for this group
            pltLines = pc.LineHandles{idy};
            pltLines.LineWidth = pc.LineWidth_I(idy);
            pltLines.LineStyle = pc.LineStyle_I(idy);
            pltLines.Color = [pc.Color_I(idy,:),pc.LineAlpha_I(idy)];
            pltLines.Marker = pc.MarkerStyle_I(idy);
            pltLines.MarkerSize = pc.MarkerSize_I(idy);
        end
    end

    % Update the chart layout
    doLayout(pc);

    % Mouse interaction setup only needs to happen once but needs to happen in update.
    if isempty(pc.Controller)
        setupMouseInteraction(pc)
    end

catch ME
    warningstatus = warning('OFF', 'BACKTRACE');
    warnCleanup = onCleanup(@()warning(warningstatus));
    warning(ME.identifier, '%s', ME.message);
    return
end
end

% Validate data sizes
function validateDataSizes(pc)
% This function is meant to be called from the doUpdate. The
% intention is to throw a warning when sizes of data do not
% match but allow users to continue to interact with the chart.
if ~isempty(pc.GroupData)
    throwErr = false;
    if pc.UsingTableForData
        % GroupVariable and CoordinateVariables
        if ~isempty(pc.GroupIndex) && iscolumn(pc.GroupIndex) && ~isequal(size(pc.GroupIndex,1),size(pc.SourceTable_I,1))
            throwErr = true;
        end
    else
        % GroupData and Data
        if ~isempty(pc.GroupIndex) && iscolumn(pc.GroupIndex) && ~isequal(size(pc.GroupIndex,1),size(pc.Data_I,1))
            throwErr = true;
        end
    end

    if throwErr
        error(message('MATLAB:graphics:parallelplot:InvalidGroupDataSize'));
    end
end
end
