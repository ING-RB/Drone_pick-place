function [PhaseOut,gain] = ngrid(varargin)
%NGRID  Generates grid lines for a Nichols plot.
%   NGRID plots the Nichols chart grid over an existing Nichols plot
%   generated with NICHOLS.  The Nichols chart relates the complex
%   numbers H and H/(1+H), and consists of lines where H/(1+H) has
%   constant magnitude and phase (as H varies in the complex plane).
%
%   NGRID('new') clears the current axes first and sets HOLD ON.
%
%   NGRID(AX,...) plots the grid on the Axes or UIAxes with handle AX.
%
%   NGRID generates a grid over the region -40 db to 40 db in
%   magnitude and -360 degrees to 0 degrees in phase when no plot
%   is contained in the current axis.
%
%   NGRID can only be used for SISO systems.
%
%   See also NICHOLS.

%   J.N. Little 2-23-88
%   Revised: CMT 7-12-90, ACWG 6-21-92, Wes W 8-17-92, AFP 6-1-94, PG/KDG 10-23-96, ADV 10-7-99
%   Copyright 1986-2019 The MathWorks, Inc. 

%---Quick exit for syntax [mag,phase]=ngrid or [mag,phase]=ngrid('new')
if nargout
   %---Ngrid defaults (in deg/dB)
   Pmin = -360;
   Pmax = 0;
   Gmin = -40;
   [PhaseOut,gain] = nicchart(Pmin,Pmax,Gmin);
   return
end

% Targeted axes
ni = nargin;
if ni>0 && isscalar(varargin{1}) && (ishghandle(varargin{1},'axes') || controllib.chart.internal.utils.isChart(varargin{1}))
   ax = varargin{1};  ni = ni-1;
else
   % Use current axes
   ax = gca;
end

% If 'NEW' is specified, clear axes and set HOLD ON
NewFlag = (ni>0);
if NewFlag
    cla(ax);
    hold(ax,'on')
end

h = gcr(ax);
if isempty(h)
    %---Otherwise, draw grid lines on standard plot
    %---Remove existing grid lines/text
    delete(findall(ax,'Tag','CSTgridLines'));

    GridOptions = gridopts('nichols');
    if NewFlag
        % Make grid lines visible to limit picker for new grids
        GridOptions.LimInclude = 'on';
    end

    % Build grid
    [GridHandles,TextHandles] = nicchart(ax,GridOptions);

    %---Make handles visible (so user can access grid)
    set([GridHandles(:);TextHandles(:)],'HandleVisibility','on');

    %---Box on
    ax.Box = 'on';
else
    %---If axes is part of a Response Plot, just turn on the 'Grid' property
    if isa(h,'controllib.chart.NicholsPlot')
        h.AxesStyle.GridVisible = true;
    elseif isa(h,'resppack.nicholsplot')
        set(h.AxesGrid,'Grid','on')
    else
        error(message('Control:analysis:ngrid1'))
    end
end
