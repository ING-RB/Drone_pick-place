classdef AxesRulerHitArea < matlab.graphics.primitive.world.Group
    %
    
    %   Copyright 2017-2024 The MathWorks, Inc.
    
    properties (Transient, NonCopyable, Hidden, Access = ?ChartUnitTestFriend)
        HitArea matlab.graphics.primitive.world.TriangleStrip
    end
    
    methods
        function hObj = AxesRulerHitArea(varargin)
            % Create the hit area.
            hitArea = matlab.graphics.primitive.world.TriangleStrip;
            hitArea.Description = 'Axes Ruler Hit Area';
            hitArea.Internal = true;
            hitArea.PickableParts = 'all'; % Capture all clicks
            hitArea.HitTest = 'off'; % Forward clicks to parent
            hitArea.Clipping = 'off';
            hObj.HitArea = hitArea;
            hObj.addNode(hitArea);
            
            % Add dependency on the colormap
            hObj.addDependencyConsumed({'ref_frame','view', ...
                'dataspace', 'hgtransform_under_dataspace', ...
                'xyzdatalimits', 'resolution'});
            
            % Process Name/Value pairs
            matlab.graphics.chart.internal.ctorHelper(hObj, varargin);
        end
        
        function doUpdate(hObj, updateState)
            % Find the axes and layout of the axes.
            hAx = ancestor(hObj,'matlab.graphics.axis.AbstractAxes','node');
            info = hAx.GetLayoutInformation;
            
            % Grab the plot box and decorated plot box off the axes.
            pb = info.PlotBox;
            dpb = info.DecoratedPlotBox;
            
            % Remove the extents of the title from the decorated plot box.
            % Use Title_IS to avoid creating a title if one doesn't already
            % exist. The first "2" refers to "y dimension". The title is
            % always drawn on-top of the axes, and there is no
            % "FirstCrossoverValue" to query, so the second "2" is a
            % hard-coded FirstCrossoverValue and [0 1] are hard-coded
            % limits to force the title extent to be removed from the top
            % of the decorated plot box.
            dpb = removeLabelFromDecoratedPlotBox(updateState, pb, dpb, ...
                hAx.Title_IS, 2, 2, [0 1], "normal");
            
            % Remove the extents of the x-label from the decorated plot
            % box. Use Label_IS to avoid creating a label if one doesn't
            % already exist.
            dpb = removeLabelFromDecoratedPlotBox(updateState, pb, dpb, ...
                hAx.XAxis(1).Label_IS, 2, hAx.XAxis(1).FirstCrossoverValue, ...
                updateState.DataSpace.YLim, updateState.DataSpace.YDir);
            
            % Remove the extents of the y-label from the decorated plot
            % box. Use Label_IS to avoid creating a label if one doesn't
            % already exist.
            dpb = removeLabelFromDecoratedPlotBox(updateState, pb, dpb, ...
                hAx.YAxis(1).Label_IS, 1, hAx.YAxis(1).FirstCrossoverValue, ...
                updateState.DataSpace.XLim, updateState.DataSpace.XDir);
            
            % Determine the vertices of a bounding box that includes the
            % region between the plot box and the decorated plot box.
            %
            %    6-----------10
            %    |           |
            % 2--5-----------9--12
            % |  |           |  |
            % |  |           |  |
            % |  |           |  |
            % 1--4-----------8--11
            %    |           |
            %    3-----------7
            xs = [dpb(1) pb(1) pb(1)+pb(3) dpb(1)+dpb(3)];
            ys = [dpb(2) pb(2) pb(2)+pb(4) dpb(2)+dpb(4)];
            cornersPixels = [...
                xs([1 1 2 2 2 2 3 3 3 3 4 4]);
                ys([2 3 1 2 3 4 1 2 3 4 2 3])];
            
            % Convert the corners from pixels to world coordinate space.
            aboveMatrix = updateState.TransformAboveDataSpace;
            belowMatrix = updateState.TransformUnderDataSpace;
            cornersWorld = matlab.graphics.internal.transformViewerToWorld(...
                updateState.Camera, aboveMatrix, updateState.DataSpace, ...
                belowMatrix, cornersPixels);
            
            % Set the vertex data, vertex indices, and strip data.
            hitArea = hObj.HitArea;
            hitArea.VertexData = single(cornersWorld);
            hitArea.VertexIndices = uint32([1 2 4 5 5 6 9 10 3 4 7 8 8 9 11 12]);
            hitArea.StripData = uint32(1:4:17);
            hgfilter('RGBAColorToGeometryPrimitive', hitArea, 'none');
        end
        
        function hObj = saveobj(hObj) %#ok<MANU>
            % Do not allow users to save this object.
            error(message('MATLAB:Chart:SavingDisabled', ...
                'matlab.graphics.chart.internal.heatmap.AxesRulerHitArea'));
        end
    end
end

function dpb = removeLabelFromDecoratedPlotBox(updateState, pb, dpb, txt, dim, firstCrossoverValue, lims, dir)
% This calculation assumes that the view is the default 2D view with the
% x-axis horizontal and the y-axis vertical. It does account for Direction
% (normal vs. reverse) and Location (left/right/top/bottom/origin). It
% assumes the labels are in their default rotation and alignment.

% Abort early if there is no label.
if isempty(txt) || isempty(txt.String_I)
    return
end

% Determine whether the ruler is along the edge of the axes or somewhere in
% the center of the axes.
if firstCrossoverValue <= lims(1)
    adjustLeft = dir == "normal";
elseif firstCrossoverValue >= lims(2)
    adjustLeft = dir == "reverse";
else
    % Ruler is within the limits, so don't adjust the decorated plot box.
    return
end

% Determine the extent of the label.
try
    extent = updateState.getStringBounds(...
        txt.String_I, txt.Text.Font, txt.Interpreter);
catch
    extent = updateState.getStringBounds(...
        txt.String_I, txt.Text.Font, 'none');
end

% Convert from points to pixels.
extent = extent(2).*updateState.PixelsPerPoint;

% Adjust the width/height
pbLeftEdge = pb(dim);
dpbLeftEdge = dpb(dim);
pbRightEdge = pb(dim) + pb(dim+2);
dpbRightEdge = dpb(dim) + dpb(dim+2);

if adjustLeft
    % Adjust the left/bottom
    newLeftEdge = min(pbLeftEdge, dpbLeftEdge + extent);
    dpb(dim) = newLeftEdge;
    dpb(dim+2) = dpbRightEdge - newLeftEdge;
else
    % Adjust the right/top
    newRightEdge = max(pbRightEdge, dpbRightEdge - extent);
    dpb(dim+2) = newRightEdge - dpbLeftEdge;
end

end
