function refresh(h)
%REFRESH  Recursively updates plot array visibility and layout.
%
%  This method should be invoked when the Visible, RowVisible, 
%  or ColumnVisible properties of @plotarray object are modified.

%  Copyright 1986-2008 The MathWorks, Inc.
  
% Compute new visibility for plots in plotarray H
% RE: Each "plot" is either an HG axes or another plot array
RowVis = h.Visible & h.RowVisible;
ColVis = (h.Visible & h.ColumnVisible)';

% Adjust overall plot array visibility (bypasses LAYOUT if nothing visible) 
if ~any(RowVis) || ~any(ColVis)
   h.Visible = 0;
end

% Reposition plots in plot array H 
% RE: Non recursive
if h.Visible
   layout(h)
end
