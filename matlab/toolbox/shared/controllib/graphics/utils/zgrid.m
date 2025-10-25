function zgrid(varargin)
%ZGRID  Generate z-plane grid lines for a root locus or pole-zero map.
%
%   ZGRID generates a grid over an existing discrete z-plane root
%   locus or pole-zero map. Lines of constant damping factor (zeta)
%   and natural frequency (Wn) are drawn in within the unit Z-plane
%   circle.
%
%   ZGRID(Z,Wn) takes numeric vectors Z and Wn and plots constant damping
%   and constant frequency lines for the damping ratios Z and the natural
%   frequencies Wn/T where T is the unspecified sample time.
%
%   ZGRID(Z,Wn,Ts) plots constant damping and frequency lines for the
%   damping ratios Z and the natural frequencies Wn relative to the
%   sample time Ts. ZGRID(Ts) uses the default Z and Wn selection.
%
%   ZGRID(...,'new') clears the current axes first and sets HOLD ON.
%
%   ZGRID(AX,...) plots the grid on the Axes or UIAxes with handle AX.
%
%   See also RLOCUS, PZMAP, SGRID.

%   Copyright 1986-2020 The MathWorks, Inc.

%---If 'NEW' is specified, clear axes and set HOLD ON
% Targeted axes
if nargin>0 && isscalar(varargin{1}) && (ishghandle(varargin{1},'axes') || controllib.chart.internal.utils.isChart(varargin{1}))
    ax = varargin{1};  varargin = varargin(2:end);
else
    % Use current axes
    ax = gca;
end

% NEW flag
isText = cellfun(@(x) ischar(x) || isstring(x),varargin);
NewFlag = any(isText);
if NewFlag
    varargin = varargin(~isText);
end

% ZETA, WN, Ts
switch numel(varargin)
    case 0
        CustomGrid = false;
        SpecTs = false;
    case 1
        SpecTs = true;
        Ts = varargin{1};
        CustomGrid = false;
    case 2
        SpecTs = false;
        zeta = varargin{1};  wn = varargin{2};
        CustomGrid = true;
    otherwise
        SpecTs = true;
        zeta = varargin{1};  wn = varargin{2};  Ts = varargin{3};
        CustomGrid = true;
end
if SpecTs && ~(isnumeric(Ts) && isscalar(Ts) && isreal(Ts) && (Ts>0 || Ts==-1))
    error(message('Control:analysis:ZGrid1'))
end
if CustomGrid && ~(isnumeric(zeta) && isreal(zeta) && isnumeric(wn) && isreal(wn))
    error(message('Control:analysis:ZGrid2'))
end
if CustomGrid
    CustomGrid = ~any(isnan(zeta)) && ~any(isnan(wn));
end

%---If 'NEW' is specified, clear axes and set HOLD ON
if NewFlag
    cla(ax);
    hold(ax,'on')
end

h = gcr(ax);
if isempty(h)
    %---Use ZPCHART to draw grid lines
    %---Remove existing grid lines/text
    delete(findobj(ax,'Tag','CSTgridLines'));

    GridOptions = gridopts('pzmap');
    if SpecTs
        GridOptions.SampleTime = Ts;
    end
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
    [GridHandles,TextHandles] = zpchart(ax,GridOptions);

    %---Make handles visible (so user can access grid)
    set([GridHandles(:);TextHandles(:)],'HandleVisibility','on');

    %---Box on
    set(ax,'Box','on')
else
    %---If axes is part of a Response Plot, just turn on the 'Grid' property
    if ~isa(h,'resppack.pzplot') && ~isa(h,'controllib.chart.PZPlot')...
            && ~isa(h,'controllib.chart.IOPZPlot') && ~isa(h,'controllib.chart.RLocusPlot')
        %---Only draw grid if the response object is a 'pzmap' or 'rlocus' plot
        error(message('Control:analysis:SZGrid','zgrid'))
    end
    if controllib.chart.internal.utils.isChart(h)
        h.AxesStyle.GridVisible = false;
        h.AxesStyle.GridType = "z-plane";
        if SpecTs
            h.AxesStyle.GridSampleTime = Ts;
        end
        if CustomGrid
            h.AxesStyle.GridDampingSpec = zeta;
            h.AxesStyle.GridFrequencySpec = wn;
        end
        h.AxesStyle.GridVisible = true;
    else
        Options = h.AxesGrid.GridOptions;
        if SpecTs
            Options.SampleTime = Ts;
        end
        if CustomGrid
            % User-defined values
            Options.Damping = zeta;
            Options.Frequency = wn;  % assumes Wn supplied in the plot units
        end
        h.AxesGrid.GridOptions = Options;
        % Toggle grid to refresh grid
        set(h.AxesGrid,'Grid','off','Grid','on')
    end
end
