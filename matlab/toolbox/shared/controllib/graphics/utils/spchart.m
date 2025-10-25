function [gridlines,labels] = spchart(ax,varargin)
%SPCHART  Generates the s-plane grid lines
%
%    [GRIDLINES,LABELS] = SPCHART(AX) plots s-plane grid lines
%    on the axes AX.  The range and spacing of the natural
%    frequencies and damping ratios is determined automatically
%    based on the axes limits of AX.  GRIDLINES and LABELS
%    contain the handles for the lines and labels of the plotted
%    grid.
%
%    [GRIDLINES,LABELS] = SPCHART(AX,ZETA,WN) plots an s-plane
%    grid on the axes AX for the set of damping ratios and natural
%    frequencies specified in ZETA and WN, respectively.
%
%    [GRIDLINES,LABELS] = SPCHART(AX,OPTIONS) specifies all the
%    grid parameters in the structure OPTIONS.  Valid fields
%    (parameters) include:
%       Damping: vector of damping rations
%       Frequency: vector of frequencies
%       FrequencyUnits = '[ Hz | {rad/s} ]';
%       GridLabelType  = '[ {damping} | overshoot ]';
%
%    Note that if frequency units of 'Hz' have been specified and
%    WN have been provided, then it is assumed that the WN values
%    are provided in units of 'Hz'.
%
%    See also PZMAP, SGRID, GRIDOPTS.

%   Revised: Adam DiVergilio, 11-99
%   Copyright 1986-2010 The MathWorks, Inc.

% Initialize return values
gridlines = [];
labels = [];

% Defaults
Options = gridopts('pzmap');

% Incorporate user-specified options
switch nargin
    case 2
        % SPCHART(AX,OPTIONS)
        s = varargin{1};
        for f=fieldnames(s)'
            Options.(f{1}) = s.(f{1});
        end
    case 3
        % SPCHART(AX,ZETA,WN)
        Options.Damping = varargin{2};
        Options.Frequency = varargin{3};
end
zeta = Options.Damping;
zeta = zeta(isfinite(zeta) | isnan(zeta));
wn = Options.Frequency;
wn = wn(isfinite(wn) | isnan(wn));
FrequencyUnits = Options.FrequencyUnits;
TimeUnits = Options.TimeUnits;
LimInclude  = Options.LimInclude;
Zlevel  = Options.Zlevel;

%---Axes info
XLIM  = ax.XLim*funitconv('rad/TimeUnit',FrequencyUnits,TimeUnits);
YLIM  = ax.YLim*funitconv('rad/TimeUnit',FrequencyUnits,TimeUnits);
dXLIM = diff(XLIM);
dYLIM = diff(YLIM);
ContainsXAxis = YLIM(1)<=0 & YLIM(2)>=0;
ContainsYAxis = XLIM(1)<=0 & XLIM(2)>=0;
ContainsOrigin = ContainsXAxis & ContainsYAxis;
FontSize = ax.FontSize;
FontWeight = ax.FontWeight;
FontAngle = ax.FontAngle;
GridWidth = ax.GridLineWidth;
GridStyle = ax.GridLineStyle;
xl = [XLIM;XLIM];
yl = [YLIM;YLIM]';

% Cosntruct zeta, wn vectors
if isempty(zeta) & isempty(wn)
    % Quick exit (nothing to show)
    return
end
if isempty(wn) || any(isnan(wn))
    % Auto-generated grid
    %---Place wn lines with constant radial spacing within axes limits
    %---Axes limits in radial form
    rl = abs(xl(:) + 1i*yl(:));
    RadMax = max(rl);
    %---If limits contain origin, minimum arc is 0
    if ContainsOrigin
        RadMin = 0;
        %---Use dominant axes to select arc spacing
        RadDel = max(abs(XLIM(1)),max(abs(YLIM)))/9;
        %---If limits contain x-axis, minimum arc is along y=0
    elseif ContainsXAxis
        RadMin = abs(XLIM(2));
        %---Use dominant axes to select arc spacing
        RadDel = max(dXLIM,max(abs(YLIM)))/9;
        %---If limits contain y-axis, minimum arc is along x=0
    elseif ContainsYAxis
        RadMin = min(abs(YLIM));
        %---Use dominant axes to select arc spacing
        RadDel = max(abs(XLIM(1)),dYLIM)/9;
        %---Otherwise, use axes limits to define minimum arc
    else
        RadMin = min(rl);
        %---Use dominant axes to select arc spacing
        RadDel = max(dXLIM,dYLIM)/9;
    end
    %---Snap to nearest reasonable arc radii
    W2 = floor(log10(RadDel));
    W1 = RadDel/10^(W2);
    if W1>=1.0 && W1<2.0
        W1 = 2;
    elseif W1>=2.0 && W1<2.5
        W1 = 2.5;
    elseif W1>=2.5 && W1<5.0
        W1 = 5;
    elseif W1>=5.0 && W1<10.0
        W1 = 10;
    end
    RadDel = W1*10^W2;
    RadMin = RadDel*floor(RadMin/RadDel);
    RadMax = RadDel*ceil(RadMax/RadDel);
    wn = RadMin:RadDel:RadMax;

    % Limit number of gridlines to 100
    if numel(wn) > 100
        wn = linspace(RadMin,RadMax,100);
    end
else
    % User-specified grid
    % Sort natural frequencies
    wn = sort(reshape(wn,[1 length(wn)]));
    wn = wn(wn>0);
    % If no frequency is supplied, set wn to a circle outside of the axes limits
    if isempty(wn)
        wn = max(abs(XLIM)) + max(abs(YLIM));
    end
end
if isempty(zeta) || any(isnan(zeta))
    % Auto-generated grid
    %---Place zeta lines with constant angular (visual) spacing
    %
    %---Axes limits in angular form, radians (abs)
    Ang = abs(angle(xl(:)/dXLIM + 1i*yl(:)/dYLIM));
    %---Determine visual limits for zeta lines
    if ContainsXAxis
        AngMax = pi;
    else
        AngMax = max(Ang);
    end
    if ContainsYAxis
        AngMin = pi/2;
    else
        AngMin = min(Ang);
    end
    %---Visual angles for zeta lines
    AngDel = (AngMax-AngMin)/9;
    AngVis = AngMin:AngDel:AngMax;
    % Limit number of zeta lines to 100
    if numel(AngVis) > 100
        AngVis = linspace(AngMin,AngMax,100);
    end
    %---Zeta values
    zeta = 1./sqrt(1+(dYLIM/dXLIM*tan(pi-AngVis)).^2);
    %---Fix numeric round-off error at pi/2 (zeta=0)
    zeta(:,zeta<10*eps) = 0;

    %---Snap to nice zeta values (within set angular tolerance)
    %
    %---Index values (end points are special cases)
    r = 2:length(zeta)-1;
    %---Angle tolerance
    AngTol = 0.1;
    %---Local visual angle range (includes tolerance)
    AVmin = AngVis(r) - AngDel*AngTol;
    AVmax = AngVis(r) + AngDel*AngTol;
    %---Allowable local zeta delta (includes tolerance)
    Zmin = 1./sqrt(1+(dYLIM/dXLIM*tan(pi-AVmin)).^2);
    Zmax = 1./sqrt(1+(dYLIM/dXLIM*tan(pi-AVmax)).^2);
    Zdel = max(eps,Zmax-Zmin);
    %---Snap allowable local zeta delta to a nice number
    Ze = floor(log10(Zdel));
    Zm = (Zdel./10.^Ze);
    Zm(:,(Zm>1)&(Zm<2))  = 1;
    Zm(:,(Zm>2)&(Zm<5))  = 2;
    Zm(:,(Zm>5)&(Zm<10)) = 5;
    Zdel = Zm.*10.^Ze;
    %---Snap end points to new zeta deltas, but limit them to (0,1)
    Z1 = max(0,Zdel(1)*floor(zeta(1)/Zdel(1)));
    Z2 = min(1,Zdel(end)*ceil(zeta(end)/Zdel(end)));
    %---New zeta vector (snapped to new zeta deltas)
    zeta = [Z1 Zdel.*ceil(Zmin./Zdel) Z2];
else
    % User-specified grid
    % Add zeta=1 and zeta=0 (real & imaginary axis)
    zeta = sort(reshape(zeta,[1 length(zeta)]));
    zeta = [0 , zeta(zeta>0 & zeta<1) , 1];
end


%---Determine X and Y values defining end points of zeta lines
%
%---Final draw angles
AngDraw = acos(zeta);
%---Final visual angles
AngVis = pi-atan(dXLIM/dYLIM*tan(AngDraw));

%---X and Y values defining end points of zeta lines
wnMax = max(wn);
x = -wnMax*zeta;
y = wnMax*sqrt(1-zeta.^2);

%---Create 2nd zeta vector for use in drawing wn arcs
%
%---Determine visual angle limits
AngMin = min(AngVis);
AngMax = max(AngVis);
%---Break angle range into equal visual spacing
AngVis2 = AngMin:(AngMax-AngMin)/40:AngMax;
%---Zeta values for use in drawing wn arcs
zeta2 = 1./sqrt(1+(dYLIM/dXLIM*tan(pi-AngVis2)).^2);
%---Fix numeric round-off error at pi/2 (zeta=0)
zeta2(:,zeta2<10*eps) = 0;

%---Plot zeta lines
re = [zeros(size(x)); x; NaN*ones(size(x))];
re = re(:)*funitconv(FrequencyUnits,'rad/TimeUnit',TimeUnits);  % Use FrequencyUnits of 'rad/TimeUnit' for plotting
im = [zeros(size(y)); y; NaN*ones(size(y))];
im = im(:)*funitconv(FrequencyUnits,'rad/TimeUnit',TimeUnits);  % Use FrequencyUnits of 'rad/TimeUnit' for plotting

zetalines = matlab.graphics.chart.primitive.Line(Parent=ax,...
    LineStyle=GridStyle,LineWidth=GridWidth,Tag='CSTgridLines',PickableParts='none',...
    HitTest='off',XLimInclude=LimInclude,YLimInclude=LimInclude,...
    XData=[re; re],YData=[im; -im],ZData=Zlevel*ones(2*length(re),1),...
    UserData=struct('Options',Options,'Type',"s-plane"),HelpTopicKey='isodampinggrid');

%---Plot wn lines
[w,z] = meshgrid(wn,zeta2);
[mcols, nrows] = size(z);
NaNRow = NaN*ones(1,nrows);
re = [-w.*z; NaNRow];
re = re(:)*funitconv(FrequencyUnits,'rad/TimeUnit',TimeUnits);  % Use FrequencyUnits of 'rad/TimeUnit' for plotting
im = [w.*sqrt(ones(mcols,nrows) -z.*z); NaNRow];
im = im(:)*funitconv(FrequencyUnits,'rad/TimeUnit',TimeUnits);  % Use FrequencyUnits of 'rad/TimeUnit' for plotting
wnlines = matlab.graphics.chart.primitive.Line(Parent=ax,...
    LineStyle=GridStyle,LineWidth=GridWidth,Tag='CSTgridLines',PickableParts='none',...
    HitTest='off',XLimInclude=LimInclude,YLimInclude=LimInclude,...
    XData=[re; re],YData=[im; -im],ZData=Zlevel*ones(2*length(re),1),...
    UserData=struct('Options',Options,'Type',"s-plane"),HelpTopicKey='isofrequencygrid');

%---Return handles of new gridlines
gridlines = [wnlines(:); zetalines(:)];
controllib.plot.internal.utils.setColorProperty(gridlines,...
    "Color","--mw-graphics-borderColor-axes-tertiary");

%---Limits may have changed due to axis autoscaling,
%--- so requery limits prior to placing text
XLIM  = ax.XLim*funitconv('rad/TimeUnit',FrequencyUnits,TimeUnits);
YLIM  = ax.YLim*funitconv('rad/TimeUnit',FrequencyUnits,TimeUnits);
dXLIM = diff(XLIM);
dYLIM = diff(YLIM);
ContainsXAxis = YLIM(1)<=0 & YLIM(2)>=0;

%---Add labels for each zeta value
%
%---Angles at which label orientation changes
if XLIM(1)<0
    AngLim11 = atan(abs(YLIM(1)/XLIM(1)));
    AngLim12 = atan(abs(YLIM(2)/XLIM(1)));
else
    AngLim11 = pi/2;
    AngLim12 = pi/2;
end
%---If only positive y values exist, use positive draw angles only
if YLIM(1)>=0
    AngDraw = AngDraw(:);
    AngLim = AngLim12*ones(size(AngDraw));
    zeta = zeta(:);
    %---If only negative y values exist, angles should be negative
elseif YLIM(2)<=0
    AngDraw = -AngDraw(:);
    AngLim = -AngLim11*ones(size(AngDraw));
    zeta = zeta(:);
    %---Add negative draw angles for case when positive and negative y values exist
else
    AngDraw = AngDraw(:);
    AngLim = AngLim12*ones(size(AngDraw));
    zeta = zeta(:);
    %---Index of non-zero angles
    idxNZ = find(AngDraw>0);
    %---Add negative angle info
    AngDraw = [AngDraw; -AngDraw(idxNZ)];
    AngLim = [AngLim; -AngLim11*ones(size(AngLim(idxNZ)))];
    zeta = [zeta; zeta(idxNZ)];
    %---If heavily biased above/below x-axis, try to prevent crowding along y-limits
    pf = abs(YLIM(2)/YLIM(1));
    pflim = 3;
    if pf>=pflim
        idx = find((AngDraw>=0) | (abs(AngDraw)<abs(AngLim)));
    elseif pf<=1/pflim
        idx = find((AngDraw<=0) | (abs(AngDraw)<abs(AngLim)));
    else
        idx = 1:length(AngDraw);
    end
    AngDraw = AngDraw(idx);
    AngLim = AngLim(idx);
    zeta = zeta(idx);
end

%---Space fraction from axes edge
edge = 0.015;

%---Ends of zeta lines
xend = -wnMax*cos(AngDraw);
yend = wnMax*sin(AngDraw);

%---Add labels for each zeta value
zetaLabels = gobjects(length(AngDraw),1);
for n=1:length(AngDraw)
    %---Limit label position to end of zeta line (allow for border of 2*edge)
    if (xend(n)>(XLIM(1)+dXLIM*edge*2)) && ...
            (yend(n)>(YLIM(1)+dYLIM*edge*2)) && ...
            (yend(n)<(YLIM(2)-dYLIM*edge*2))
        HA = 'right';
        if AngDraw(n)>0
            VA = 'bottom';
        elseif AngDraw(n)<0
            VA = 'top';
        else
            VA = 'middle';
        end
        xp = xend(n);
        yp = yend(n);
        %---Zeta line intersects YLIM (along top/bottom)
    elseif abs(AngDraw(n))>abs(AngLim(n))
        HA = 'center';
        %---Zeta line intersects top of axes (positive imag part)
        if AngDraw(n)>0
            yp = YLIM(2) - dYLIM*edge;
            VA = 'top';
            %---Zeta line intersects bottom of axes (negative imag part)
        else
            yp = YLIM(1) + dYLIM*edge;
            VA = 'bottom';
        end
        xp = -yp/tan(AngDraw(n));
        %---Zeta line intersects XLIM (along left side)
    else
        HA = 'left';
        VA = 'middle';
        xp = XLIM(1) + dXLIM*edge;
        yp = -xp*tan(AngDraw(n));
    end
    %---Only draw if the text anchor lies within axes limits (also, drop zeta = 0,1)
    if ((xp<XLIM(1))||(xp>XLIM(2))||(yp<YLIM(1))||(yp>YLIM(2))||(zeta(n)==0)||(zeta(n)==1))
        xp = NaN;
        yp = NaN;
    end
    tpos = [xp yp]*funitconv(FrequencyUnits,'rad/TimeUnit',TimeUnits);  % Use FrequencyUnits of 'rad/TimeUnit' for plotting
    if strcmpi(Options.GridLabelType,'overshoot')
        dispzeta = exp(-zeta(n)*pi/sqrt(1-zeta(n)*zeta(n)));
        dispzeta = round(1e5*dispzeta)/1e3; % round off small values
    else
        dispzeta = zeta(n);
    end
    zetaLabels(n) = text(tpos(1),tpos(2),Zlevel,sprintf('%0.3g',dispzeta),...
        Parent=ax,FontSize=FontSize,FontWeight=FontWeight,FontAngle=FontAngle,...
        Clipping='on',HorizontalAlignment=HA,VerticalAlignment=VA,...
        Tag='CSTgridLines',HitTest='off',PickableParts='none',...
        XLimInclude='off',YLimInclude='off',...
        UserData=struct('Options',Options,'Type',"s-plane"),HelpTopicKey='isodampinggrid');
end

%---Add labels for each wn value
%
%---Drop wn=0
wn = wn(:,wn>0);
%---Define x/y radial extents
dx = min(0,XLIM(2))-XLIM(1);
if sign(YLIM(1))==sign(YLIM(2))
    dy = dYLIM;
else
    dy = max(abs(YLIM));
end
%---Y extent is dominant: place labels with constant x
if dy>=dx
    %---Place labels along XLIM(2), but limit to max of x=0
    xp = min(0,XLIM(2)-dXLIM*edge)*ones(size(wn));
    yp = sqrt(wn.^2 - xp.^2);
    %---Make these label positions symmetric about y=0
    xp = [xp xp];
    yp = [yp -yp];
    wn = [wn wn];
    %---X extent is dominant: place labels with constant y
else
    %---Place labels along y=0 line if possible
    if ContainsXAxis
        yp = zeros(size(wn));
        %---Otherwise, place labels along ylim closest to y=0
    else
        yp = sign(YLIM(1))*(min(abs(YLIM))+dYLIM*edge)*ones(size(wn));
    end
    xp = -sqrt(wn.^2 - yp.^2);
end

%---Index of labels whose anchor point lies within axes limits (and is real)
idx = find(~((xp<XLIM(1))|(xp>XLIM(2))|(yp<YLIM(1))|(yp>YLIM(2))|(imag(xp)~=0)|(imag(yp)~=0)));
wnLabels = gobjects(length(idx),1);
for n=1:length(idx)
    %---Vertical alignment depends on quadrant receiving labels
    if (yp(idx(n))>0) || ((yp(idx(n))==0) && (abs(YLIM(2))>=abs(YLIM(1))))
        VA = 'bottom';
    else
        VA = 'top';
    end
    %---Draw wn label
    tpos = [xp(idx(n)) yp(idx(n))]*funitconv(FrequencyUnits,'rad/TimeUnit',TimeUnits);  % Use FrequencyUnits of 'rad/TimeUnit' for plotting
    wnLabels(n) = text(tpos(1),tpos(2),Zlevel,sprintf('%.3g',wn(idx(n))),...
        Parent=ax,FontSize=FontSize,FontWeight=FontWeight,FontAngle=FontAngle,...
        Clipping='on',HorizontalAlignment='right',VerticalAlignment=VA,...
        Tag='CSTgridLines',HitTest='off',PickableParts='none',...
        XLimInclude='off',YLimInclude='off',...
        UserData=struct('Options',Options,'Type',"s-plane"),HelpTopicKey='isofrequencygrid');
end

%---Return handles of new labels
labels = [zetaLabels(:);wnLabels(:)];
controllib.plot.internal.utils.setColorProperty(labels,...
    "Color","--mw-graphics-borderColor-axes-tertiary");

% Send to back
gridObjs = [gridlines;labels];
otherObjs = ax.Children(:);
for ii = numel(otherObjs):-1:1
    if any(otherObjs(ii)==gridObjs)
        otherObjs(ii) = [];
    end
end
ax.Children = [otherObjs;gridObjs];
set(gridObjs,HandleVisibility='off');
end