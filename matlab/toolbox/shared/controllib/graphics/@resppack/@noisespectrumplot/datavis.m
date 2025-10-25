function dv = datavis(this)
%DATAVIS  Data visibility.
%
%  Responses are arrays of curves. Each curve represents a piece
%  of response data and is plotted in a particular HG axes.
%
%  DV = DATAVIS(RESPPLOT) returns an array of the same size as the
%  axes grid (see GETAXES) indicating which curves are currently
%  displayed.  The result is affected by the plot visibility,
%  and the input and output visibility.

%  Author(s): P. Gahinet
%  Copyright 1986-2005 The MathWorks, Inc.

% REVISIT: call parent method to initialize
gs = this.AxesGrid.Size;
dv = false(gs([1 2]));
if strcmp(this.Visible,'on')
   % Row and column visibility (subgrid assumed 1x1 in generic case)
   dv(strcmp(this.OutputVisible,'on'),...
      strcmp(this.InputVisible,'on')) = true;
end
