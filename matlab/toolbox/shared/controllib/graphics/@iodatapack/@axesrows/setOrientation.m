function setOrientation(h,Orientation)
%SETORIENTATION sets the IO data plot orientation.
% Value must be one of: '2row', '2col', '1row', '1col'.
%
% For IO data plot, the default is '2row'.

%   Copyright 2014-2015 The MathWorks, Inc.
narginchk(2,2)

Orientation = lower(Orientation);
assert(ismember(Orientation,{'2row','2col','1row','1col'}),...
   'Incorrect value for Orientation specified.')

if ishandle(h.Axes)
   h.Axes.Orientation = Orientation;
   %h.Axes.layout;
   if strcmp(Orientation,'1col')
      h.RowLabelStyle.Location = 'left';
   else
      h.RowLabelStyle.Location = 'top';
   end
   setposition(h)
end
