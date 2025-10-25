function Axes = getaxes(this, varargin)
%GETAXES  Get array of HG axes to which response data is mapped.
%
%  Data waves are arrays of curves, each curve being plotted in 
%  a particular HG axes. The mapping between curves 
%  and axes is one-to-one for a full view, and many-to-one 
%  when axes are grouped. Note that a curve may be multidimensional
%  represented by a group of lines.
%
%  AX = GETAXES(H) returns a 4D array of HG axes handles where
%  the first two dimensions are the I/O sizes, and the last two
%  dimensions are the subplot sizes (e.g., 2-by-1 for Bode plots).
%  This array specifies in which axes each response curve is 
%  currently drawn.
%
%  AX = GETAXES(H,'2d') formats the same information into a 2D 
%  matrix conforming with the axes grid layout.
% 
%  See also ALLAXES.

%  Copyright 2013 The MathWorks, Inc.

% REM: GridSize <= size(Axes)  (e.g, in frequency plots)
Axes = getaxes(this.AxesGrid);
GridSize = this.AxesGrid.Size;

% Take axes grouping into account
if strcmp(this.IOGrouping,'all')
  s = this.IOSize;
  if any(s==0)
     Axes = repmat(Axes(1,1,:,:),GridSize([1 2]));
  else
     Axes1 = Axes(1,1,:,:);
     Axes2 = Axes(s(1)+1,1,:,:);
     Axes = [repmat(Axes1,[s(1),1]); repmat(Axes2,[s(2),1])];
  end
end

% Reformat to 2D if requested
if any(strcmp(varargin,'2d'))
   Axes = reshape(permute(Axes,[3 1 4 2]),...
      [prod(GridSize([1 3])),prod(GridSize([2 4]))]);
end
