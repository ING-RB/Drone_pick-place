function labelpos(h)
%LABELPOS  Adjust position of background axes labels.

%   Authors: A. DiVergilio, P. Gahinet
%   Copyright 1986-2014 The MathWorks, Inc.

f = ancestor(h.BackgroundAxes,'figure');
% Do not manually position labels if figure is a live editor figure
if ~matlab.internal.editor.figure.FigureUtils.isEditorFigure(f) || isa(f.UserData,'viewgui.ltiviewer')
    if isvisible(h)
        % Visible row and columns
        [VisAxes,indrow,indcol] = findvisible(h);
        if isempty(VisAxes)
            return
        end

        % Parameters
        Geometry = h.Axes.Geometry;
        tshave = Geometry.TopMargin;  % Gap btw tops of background axes and data axes
        yshave = Geometry.LeftMargin; % Gap btw left edges of background axes and data axes
        cushion = 2;  % Extra cushion between labels and plots
        tcushion = 6; % Extra cushion for title

        % Pixel width/height of background axes
        backax = h.BackgroundAxes;
        [FigW,FigH] = figsize(h.Axes,'pixel');
        bw = backax.Position(3) * FigW;
        bh = backax.Position(4) * FigH;
        LabelUnit = get(backax.Title,'Units');

        % Warnings off in case label position goes negative on log plots
        WarnState = warning('off');

        % Switch label positioning computation based on ASML flag
        if controllibutils.CSTCustomSettings.getResppackLayoutUpdate
            % Get outer position for the grid of axes
            [x0,y0,y1] = getAxesGridPositionForOuterLabels(h,VisAxes,'pixels');
            % Set background axes units to pixels
            backaxCurrentUnits = backax.Units;
            backax.Units = 'pixels';
            % Compute x offset for ylabel position
            x_offset = x0 - backax.Position(1) - yshave;  % offset in pixels
            YLabelPos = [yshave+x_offset (bh-tshave)/2 0];
            % Compute y offset for xlabel position (use -13.33 as min to keep
            % same behavior, otherwise the xlabel goes off figure)
            y_offset = y0 - backax.Position(2) + cushion;  % offset in pixels
            XLabelPos = [(bw+yshave)/2 y_offset 0];
            % Compute title position
            TitleExt = getExtentInUnits(backax.Title,'Pixels');
            y_offset = min([y1 - backax.Position(2) + cushion, FigH - TitleExt(:,4) - tcushion - cushion]);
            TitlePos = [(bw+yshave)/2 y_offset 0];
            % Optimized position update (AbortSet=off on Units!)
            if strcmp(LabelUnit,'pixels')
                set(backax.Title,'Position',TitlePos);
                set(backax.XLabel,'Position',XLabelPos);
                set(backax.YLabel,'Position',YLabelPos);
            else
                set(backax.Title,'Units','pixels','Position',TitlePos,'Units',LabelUnit);
                set(backax.XLabel,'Units','pixels','Position',XLabelPos,'Units',LabelUnit);
                set(backax.YLabel,'Units','pixels','Position',YLabelPos,'Units',LabelUnit);
            end
            % Revert background axes units
            backax.Units = backaxCurrentUnits;
        else
            % Adjust YLabel position
            ylabin = get(VisAxes(:,1),{'YLabel'});
            ylabin = cat(1,ylabin{:});
            % Get max extent of inner labels
            ex = [];
            for ct = 1:numel(ylabin)
                ex = [ex;getExtentInUnits(ylabin(ct),'Pixels')] ;
            end
            x_offset = min(ex(:,1));  % offset in pixels
            YLabelPos = [yshave+x_offset (bh-tshave)/2 0];

            % Adjust XLabel position
            xlabin = get(VisAxes(end,:),{'XLabel'});
            xlabin = cat(1,xlabin{:});
            ex = [];
            for ct = 1:numel(xlabin)
                ex = [ex;getExtentInUnits(xlabin(ct),'Pixels')] ;
            end
            y_offset = min(ex(:,2)) + cushion;  % offset in pixels
            XLabelPos = [(bw+yshave)/2 y_offset 0];

            % Adjust Title position
            tlabin = get(VisAxes(1,:),{'Title'});
            tlabin = cat(1,tlabin{:});
            ex = [];
            for ct = 1:numel(tlabin)
                ex = [ex;getExtentInUnits(tlabin(ct),'Pixels')] ;
            end

            % Minimize clipping
            % Reduce clipping with larger font sizes
            TitleExt = getExtentInUnits(backax.Title,'Pixels');
            ComputeClipping = FigH - ...
                ((backax.Position(2)+ backax.Position(4))*FigH-tshave+max(ex(:,4))+cushion+TitleExt(:,4));
            if ComputeClipping < tcushion
                % Title extends past figure boundary minimize cusion
                addoffset = max(0,ComputeClipping);
            else
                % Use default spacing
                addoffset = tcushion + cushion;
            end
            y_offset = max(ex(:,4)) + addoffset;

            TitlePos = [(bw+yshave)/2 bh-tshave+y_offset 0];

            % Optimized position update (AbortSet=off on Units!)
            if strcmp(LabelUnit,'pixels')
                set(backax.Title,'Position',TitlePos);
                set(backax.XLabel,'Position',XLabelPos);
                set(backax.YLabel,'Position',YLabelPos);
            else
                set(backax.Title,'Units','pixels','Position',TitlePos,'Units',LabelUnit);
                set(backax.XLabel,'Units','pixels','Position',XLabelPos,'Units',LabelUnit);
                set(backax.YLabel,'Units','pixels','Position',YLabelPos,'Units',LabelUnit);
            end
        end
        warning(WarnState)
    end
end

end

% Local functions

