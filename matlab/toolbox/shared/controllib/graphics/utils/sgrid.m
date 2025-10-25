function sgrid(varargin)
%SGRID  Generate s-plane grid lines for a root locus or pole-zero map.
%   SGRID generates a grid over an existing continuous s-plane root
%   locus or pole-zero map.  Lines of constant damping ratio (zeta)
%   and natural frequency (Wn) are drawn.
%
%   SGRID('new') clears the current axes first and sets HOLD ON.
%
%   SGRID(Z,Wn) plots constant damping and frequency lines for the 
%   damping ratios in the vector Z and the natural frequencies in the
%   vector Wn.
%
%   SGRID(Z,Wn,'new') clears the current axes first and sets HOLD ON.
%
%   SGRID(AX,...) plots the grid on the Axes or UIAxes with handle AX.
%
%   See also RLOCUS, PZMAP, and ZGRID.

%   Clay M. Thompson
%   Revised: ACWG 6-21-92, AFP 10-15-94
%   Revised: Adam DiVergilio, 12-99, , P. Gahinet 1-2001
%   Copyright 1986-2019 The MathWorks, Inc. 

% Targeted axes
ni = nargin;
if ni>0 && isscalar(varargin{1}) && (ishghandle(varargin{1},'axes') || controllib.chart.internal.utils.isChart(varargin{1}))
   ax = varargin{1};  varargin = varargin(2:ni);  ni = ni-1;
else
   % Use current axes
   ax = gca;
end

% ZETA and WN
if ni>1 && isnumeric(varargin{1}) && isnumeric(varargin{2})
   zeta = varargin{1};  wn = varargin{2};   ni = ni-2;
   CustomGrid = ~any(isnan(zeta)) && ~any(isnan(wn));
else
   CustomGrid = false;
end
   
%---If 'NEW' is specified, clear axes and set HOLD ON
NewFlag = (ni>0);
if NewFlag
    cla(ax);
    hold(ax,'on')
end

h = gcr(ax);
if isempty(h)
   %---Otherwise, use SPCHART to draw grid lines
   %---Remove existing grid lines/text
   delete(findobj(ax,'Tag','CSTgridLines'));
   
   GridOptions = gridopts('pzmap');
   if CustomGrid
      % User-supplied grid values
      GridOptions.Damping = zeta;
      GridOptions.Frequency = wn;
   end
   if NewFlag
      % Make grid lines visible to limit picker for new grids
      GridOptions.LimInclude = 'on';
   end
   
   % Build grid
   [GridHandles,TextHandles] = spchart(ax,GridOptions);
   
   %---Make handles visible (so user can access grid)
   set([GridHandles(:);TextHandles(:)],'HandleVisibility','on');
   
   %---Box on
   ax.Box = 'on';   
else
   %---If axes is part of a Response Plot, just turn on the 'Grid' property
   if ~isa(h,'resppack.pzplot') && ~isa(h,'controllib.chart.PZPlot')...
           && ~isa(h,'controllib.chart.IOPZPlot') && ~isa(h,'controllib.chart.RLocusPlot')
      %---Only draw grid if the response object is a 'pzmap' or 'rlocus' plot
      error(message('Control:analysis:SZGrid','sgrid'))
   end
   if controllib.chart.internal.utils.isChart(h)
       h.AxesStyle.GridVisible = false;
       h.AxesStyle.GridType = "s-plane";
       if CustomGrid
           h.AxesStyle.GridDampingSpec = zeta;
           h.AxesStyle.GridFrequencySpec = wn;
       end
       h.AxesStyle.GridVisible = true;
   elseif CustomGrid
      % User-defined values
      Options = h.AxesGrid.GridOptions;
      Options.Damping = zeta;
      Options.Frequency = wn;  % assumes Wn supplied in the plot units
      h.AxesGrid.GridOptions = Options;
      set(h.AxesGrid,'Grid','off','Grid','on')
   else
      set(h.AxesGrid,'Grid','on')
   end   
end


