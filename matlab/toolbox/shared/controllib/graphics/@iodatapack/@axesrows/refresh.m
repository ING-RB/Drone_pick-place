function refresh(h,varargin)
%REFRESH  Adjusts visibility of HG axes in axes grid.
%
%   Invoked when modifying properties controlling axes visibility,
%   REFRESH updates the visibility of HG axes as well as the  
%   position and visibility of tick and text labels.  
%
%   This method interfaces with the @plotarray class by first updating
%   the visibility properties of the @plotarray objects, and then 
%   invoking @plotarray/refresh.

%   Copyright 2013 The MathWorks, Inc.

SubGridSize = prod(h.Size([3 4]));

% Row visibility
% Row groups are never intermixed. If multi-column,
RowVis = reshape(strcmp(h.RowVisible,'on'), h.Size([3 1]));
if strcmp(h.AxesGrouping,'all')
   s = h.RowLen; 
   yVis = RowVis(:,1:s(1)); uVis = RowVis(:,s(1)+(1:s(2)));
   n = sum(s>0); 
   yRV = true(0,1); uRV = true(0,1);
   if ~isempty(yVis)
      yRV = [any(any(yVis)) ; false(s(1)-1,1)];
   end
   if ~isempty(uVis)
      uRV = [any(any(uVis)) ; false(s(2)-1,1)];
   end
   
   h.Axes.RowVisible = [yRV; uRV];
   if SubGridSize>1
      set(h.Axes.Axes(1,:),'RowVisible',any(RowVis,2))
      if n>1
         set(h.Axes.Axes(s(1)+1,:),'RowVisible',any(RowVis,2))
      end
   end
else
   h.Axes.RowVisible = any(RowVis,1)';
   if SubGridSize>1
      for ct = 1:h.Size(1)
         set(h.Axes.Axes(ct,:),'RowVisible',RowVis(:,ct))
      end
   end
end

% Column visibility
ColVis = reshape(strcmp(h.ColumnVisible,'on'),h.Size([4 2]));
h.Axes.ColumnVisible = any(ColVis,1)';
if SubGridSize>1
   for ct=1:h.Size(2)
      set(h.Axes.Axes(:,ct),'ColumnVisible',ColVis(:,ct))
   end
end

% Global visibility
h.Axes.Visible = strcmp(h.Visible,'on');

% Update visibility of low-level HG axes
refresh(h.Axes);

% Set label and tick visibility
setlabels(h)

% Update background axes for Live Editor figure
if matlab.internal.editor.figure.FigureUtils.isEditorFigure(ancestor(h.Parent,'figure'))
    visibleAxes = findvisible(h);
    if ~isempty(visibleAxes)
        [x0,y0,y1,x1] = getAxesGridPositionForOuterLabels(h,visibleAxes,'normalized');
        % Set Background Axes normalized position with some padding
        h.BackgroundAxes.Position = [x0,y0+0.025,x1-x0+0.05,y1-y0-0.025];
    end
end
