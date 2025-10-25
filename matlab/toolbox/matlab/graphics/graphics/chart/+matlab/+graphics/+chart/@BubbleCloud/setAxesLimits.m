function setAxesLimits(obj)
%

%   Copyright 2020 The MathWorks, Inc.

% Set limits on BubbleCloud's axes following a new layout of bubbles.

if ~isempty(obj.XYR)
    % Get the data range:
    xmin=min(obj.XYR(1,:)-obj.XYR(3,:));
    xmax=max(obj.XYR(1,:)+obj.XYR(3,:));
    ymin=min(obj.XYR(2,:)-obj.XYR(3,:));
    ymax=max(obj.XYR(2,:)+obj.XYR(3,:));
    xrange=xmax-xmin;
    yrange=ymax-ymin;

    % Pad both x and y by 5%
    xmin=xmin-.025*xrange;
    xmax=xmax+.025*xrange;
    ymin=ymin-.025*yrange;
    ymax=ymax+.025*yrange;

    % recalculate range
    xrange=xmax-xmin;
    yrange=ymax-ymin;

    % Pad limits so that the data aspect ratio matches the plotbox 
    % aspect ratio
    dataaspect=xrange/yrange;
    axesaspect=obj.Axes.InnerPosition_I(3)/obj.Axes.InnerPosition_I(4);
    
    if isnan(axesaspect)
        return
    end
    
    if dataaspect>axesaspect
        % The data are wider than the axes, pad y
        amounttopad=yrange * dataaspect/axesaspect- yrange;
        ymin=ymin-amounttopad/2;
        ymax=ymax+amounttopad/2;
    else
        % The axes is wider than the data, pad x
        amounttopad=xrange * axesaspect/dataaspect - xrange;
        xmin=xmin-amounttopad/2;
        xmax=xmax+amounttopad/2;
    end

    obj.Axes.XLim=[xmin xmax];
    obj.Axes.YLim=[ymin ymax];
    
    % Define new 'home' position for restoreview toolbar button
    resetplotview(obj.Axes,'SaveCurrentView');
end
end

% LocalWords:  plotbox
