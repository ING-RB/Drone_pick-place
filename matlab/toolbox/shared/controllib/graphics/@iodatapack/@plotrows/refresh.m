function refresh(h)
%REFRESH  Update plot array visibility and layout.
%
%  This method should be invoked when the Visible, RowVisible,
%  or ColumnVisible properties of @plotarray object are modified.

%  Copyright 2013-2015 The MathWorks, Inc.

% Compute new visibility for plots in plot array H
% RE: Each "plot" is either an HG axes or another plot array
Size = size(h.Axes);
RowVis = h.Visible & h.RowVisible;
ColVis = (h.Visible & h.ColumnVisible)';
NewVis = RowVis(:,ones(1,Size(2))) & ColVis(ones(1,Size(1)),:);

% Adjust overall plot array visibility (bypasses LAYOUT if nothing visible)
if ~any(NewVis)
   h.Visible = 0;
end

% Reposition plots in plot array H
% RE: Non recursive
if h.Visible
   layout(h)
end

% Update plot visibility and recursively apply REFRESH to subgrids
if ishghandle(h.Axes(1),'axes')
   % Apply new visibility to HG axes and set zoom property
   % based on visibility of axis
   hax = h.Axes(NewVis);
   set(hax,'Visible','on','ContentsVisible','on')
   bh = hgbehaviorfactory('Zoom');
   set(bh, 'Enable', true);
   hgaddbehavior(hax,bh);
   
   hax = h.Axes(~NewVis);
   % Turn off legends
   for ct = 1:length(hax(:))
      legend(double(hax(ct)),'off')
   end
   set(hax,'Visible','off','ContentsVisible','off');
   bh = hgbehaviorfactory('Zoom');
   set(bh, 'Enable', false);
   hgaddbehavior(hax,bh);
else
   % Update visibility of each subgrid
   set(h.Axes(NewVis),'Visible',1)
   set(h.Axes(~NewVis),'Visible',0)
   % Recursive call to REFRESH
   % RE: Apply to ALL subarrays to properly update visibility of HG axes
   N = numel(h.Axes);
   for ct = 1:N
      refresh(h.Axes(ct))
   end
end
