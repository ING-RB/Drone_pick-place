function adjustview(this,Data,Event,varargin)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(VIEW,DATA,'prelim') clips unbounded branches of the locus
%  using the XFocus and YFocus info in DATA before invoking the limit
%  picker.
%
%  ADJUSTVIEW(VIEW,DATA,'postlimit') restores the full branch extent once  
%  the axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Author(s): P. Gahinet
%  Copyright 1986-2010 The MathWorks, Inc.
%  Date: 2010/11/08 02:31:02 $

ax = getaxes(this.AxesGrid);
hPlot = gcr(ax(1));

if isequal(Data.Ts,0)
    Factor = tunitconv(hPlot.TimeUnits,Data.TimeUnits);
else
    Factor = 1;
end

switch Event
case 'prelim'
   % Clip portion of branches extending beyond XFocus and YFocus
   for ct=1:length(this.Locus)
      b = this.Locus(ct);
      % RE: Set min extent to focus box to avoid "shrinking focus" effect
      %     when the locus is sparsely sampled near the box edge (see
      %     sys = zpk(z,p,5.3734e+09) in TRLOC)
      set(double(b),'Xdata',Data.XFocus*Factor,'YData',Data.YFocus*Factor)
   end
   
case 'postlim'
   % Restore branches to their full extent
   draw(this,Data)
end