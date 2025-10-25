function [gridlines,labels] = zpchart(ax,Options)
%ZPCHART  Generates the z-plane grid lines
%
%    [GRIDLINES,LABELS] = ZPCHART(AX) plots z-plane grid lines
%    on the axes AX.  The range and spacing of the natural
%    frequencies and damping ratios is determined automatically
%    based on the axes limits of AX.  GRIDLINES and LABELS
%    contain the handles for the lines and labels of the plotted
%    grid.
%
%    [GRIDLINES,LABELS] = ZPCHART(AX,OPTIONS) specifies all the
%    grid parameters in the structure OPTIONS.  Valid fields
%    (parameters) include:
%       Damping: vector of damping rations
%       Frequency: vector of frequencies
%       FrequencyUnits = '[ Hz | {rad/s} ]';
%       GridLabelType  = '[ {damping} | overshoot ]';
%       SampleTime     = '[ real scalar | {-1} ]';
%
%    Note that if frequency units of 'Hz' have been specified and
%    WN have been provided, then it is assumed that the WN values
%    are provided in units of 'Hz'.
%
%    See also PZMAP, ZGRID.

%   Copyright 1986-2020 The MathWorks, Inc.
if nargin<2
    Options = gridopts('pzmap');
end
zeta = Options.Damping;
zeta = zeta(isfinite(zeta) | isnan(zeta));
wn = Options.Frequency;
wn = wn(isfinite(wn) | isnan(wn));
Ts = Options.SampleTime;
FrequencyUnits = Options.FrequencyUnits;
TimeUnits = Options.TimeUnits;
LimInclude  = Options.LimInclude;
Zlevel  = Options.Zlevel;
nf = pi/abs(Ts);  % Nyquist frequency in rad/TimeUnit
cf = funitconv('rad/TimeUnit',FrequencyUnits,TimeUnits);

%---Axes info
FontSize = ax.FontSize;
FontWeight = ax.FontWeight;
FontAngle = ax.FontAngle;
GridWidth = ax.GridLineWidth;
GridStyle = ax.GridLineStyle;

%---Plot unit circle (always include, corresponds to zeta=0)
unitCircle = matlab.graphics.primitive.Rectangle(Parent=ax,...
    Curvature=[1 1],Position=[-1 -1 2 2],Tag='CSTgridLines',...
    LineStyle=GridStyle,LineWidth=GridWidth,...
    HitTest='off',PickableParts='none',...
    UserData=struct('Options',Options,'Type',"z-plane"),HelpTopicKey='isodampinggrid');
controllib.plot.internal.utils.setColorProperty(unitCircle,...
    "EdgeColor","--mw-graphics-borderColor-axes-tertiary");
labels = gobjects(0);
if isempty(zeta) || isempty(wn)
    % Return handle of unit circle only
    gridlines = unitCircle;

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
    return
end

% Construct zeta, wn vectors
if isempty(zeta) || any(isnan(zeta))
    % Auto-generated grid
    zeta = 0.1:0.1:0.9;
else
    % User-specified grid
    % Add zeta=1 and zeta=0 (real & imaginary axis)
    zeta = sort(reshape(zeta,[1 numel(zeta)]));
    zeta = [0 zeta(zeta>0 & zeta<1) 1];
end
if isempty(wn) || any(isnan(wn))
    % Auto-generated grid
    % Wn is selected as a fraction of the Nyquist frequency
    rho = 0.1:0.1:1;     % fractions of NF
    wn = rho * nf * cf;  % value in FrequencyUnits
    if Ts>0
        wns = string(num2str(wn(:),'%.3g'));
    elseif cf==1
        % Display as fraction of pi/Ts
        wns = rho(:) + "\pi/T";  % \pi for latex
    else
        % Display of multiple of 1/Ts
        wns = string(num2str(wn(:),'%.3g')) + "/T";
    end
else
    % User-specified grid
    % Sort natural frequencies
    wn = wn(wn>0 & wn<=pi/abs(Ts));
    wn = sort(reshape(wn,[1 numel(wn)]));  % expressed in FrequencyUnits
    wns = string(num2str(wn(:),'%.3g'));
    if Ts==-1
        wns = wns + "/T";
    end
end
wns = strrep(wns,'+00','');
wns = strrep(wns,'+0','');

% Lines are z = exp(a+jb) with a<=0 and
%     wn lines     a^2 + b^2 = (wn*Ts)^2
%   zeta lines    -a/sqrt(a^2+b^2) = zeta
% Convert wn values to
wn = wn / cf;

%---Plot zeta lines (damping)
m = -tan(asin(zeta)) + 1i;
r = linspace(0,pi,100);   % keep phase in [0,pi]
aux = exp(r'*m);
zzeta = [aux ; flipud(conj(aux)) ; NaN(1,numel(zeta))];
zzeta = zzeta(:);
zetalines = matlab.graphics.chart.primitive.Line(Parent=ax,...
    LineStyle=GridStyle,LineWidth=GridWidth,Tag='CSTgridLines',PickableParts='none',...
    HitTest='off',XLimInclude=LimInclude,YLimInclude=LimInclude,...
    XData=real(zzeta),YData=imag(zzeta),ZData=Zlevel*ones(size(zzeta)),...
    UserData=struct('Options',Options,'Type',"z-plane"),HelpTopicKey='isodampinggrid');
controllib.plot.internal.utils.setColorProperty(zetalines,...
    "Color","--mw-graphics-borderColor-axes-tertiary");

%---Plot wn lines (natural frequency)
r = wn*abs(Ts);
theta = linspace(pi/2,3*pi/2,100);
zwn = [exp(exp(1i*theta')*r) ; NaN(1,numel(wn))];
wnlines = matlab.graphics.chart.primitive.Line(Parent=ax,...
    LineStyle=GridStyle,LineWidth=GridWidth,Tag='CSTgridLines',PickableParts='none',...
    HitTest='off',XLimInclude=LimInclude,YLimInclude=LimInclude,...
    XData=real(zwn(:)),YData=imag(zwn(:)),ZData=Zlevel*ones(numel(zwn),1),...
    UserData=struct('Options',Options,'Type',"z-plane"),HelpTopicKey='isofrequencygrid');
controllib.plot.internal.utils.setColorProperty(wnlines,...
    "Color","--mw-graphics-borderColor-axes-tertiary");

%---Return handles of new gridlines
gridlines = [wnlines(:); zetalines(:); unitCircle];

%---Limits may have changed due to axis autoscaling,
%--- so requery limits prior to placing text
XLIM = ax.XLim;
YLIM = ax.YLim;
dXLIM = diff(XLIM);
dYLIM = diff(YLIM);
ContainsXAxis = YLIM(1)<=0 & YLIM(2)>=0;
ContainsYAxis = XLIM(1)<=0 & XLIM(2)>=0;

%---Construct wn midpoint information (for zeta label positioning)
%---Create wn vector which contains 0,pi
wnTs = wn*abs(Ts);
wntmp = [0 wnTs(:,wnTs<pi) pi];
%---Vector of midpoints between plotted wn lines
wnmid = (wntmp(1:end-1)+wntmp(2:end))/2;
%---Coordinates of wnmid on z-plane
e_itheta = exp(1i * (pi/2:pi/50:pi)');
e_r = exp(wnmid);
zwnmid = (ones(length(e_itheta),1)*e_r).^(e_itheta*ones(size(e_r)));

%---If y=0 line is showing, draw frequency labels above and below x-axis
if ContainsXAxis
    wn = [wn wn];
    zwn = [zwn conj(zwn)];
    wns = [wns wns];
    wnmid = [wnmid wnmid];
    zwnmid = [zwnmid conj(zwnmid)];
    %---If only negative y-values are showing, only draw frequency labels below x-axis
elseif YLIM(2)<0
    zwn = conj(zwn);
    zwnmid = conj(zwnmid);
end

%---Space fraction from axes edge
edge = 0.015;

%---Space fraction of axes used to determine label crowding
crowdlim = 1/6;

%---Try to find a label position for each wn value
wnLabels = gobjects(length(wn),1);
ct = 1;
for n=1:length(wn)
    %---Find coordinates of wn line which lie within axes limits
    wnz = zwn(~isnan(zwn(:,n)),n);
    idx = find((real(wnz)>=XLIM(1))&(real(wnz)<=XLIM(2))&...
        (imag(wnz)>=YLIM(1))&(imag(wnz)<=YLIM(2)));
    %---Initialize label position
    wnx = NaN;
    wny = NaN;
    %---If this wn line is visible, add label at position set by wn and axes limits
    if ~isempty(idx)
        %---Visible coordinate along wn which is closest to unit circle
        firstvis = idx(1);
        %---If unit circle is shown at this wn, use it for label position
        if firstvis==1
            wnx = real(wnz(1));
            wny = imag(wnz(1));
            %dx = real(wnz(2))-wnx;
            dy = imag(wnz(2))-wny;
            %slp = dy/dx;
            if wn(n)>pi/2
                HA = 'left';
            elseif wn(n)<pi/2
                HA = 'right';
            else
                HA = 'center';
            end
            %---Otherwise, interpolate a point along axes edge
        else
            w1 = wnz(firstvis-1);
            w2 = wnz(firstvis);
            x = [real(w1) real(w2)];
            y = [imag(w1) imag(w2)];
            dx = diff(x);
            dy = diff(y);
            slp = dy/dx;
            if y(1)>(YLIM(2)-dYLIM*edge)
                if ~(ContainsXAxis && abs(YLIM(2)/dYLIM)<crowdlim)
                    wny = YLIM(2)-dYLIM*edge;
                    wnx = x(1) + (wny-y(1))/slp;
                    HA = 'center';
                end
            elseif y(1)<(YLIM(1)+dYLIM*edge)
                if ~(ContainsXAxis && abs(YLIM(1)/dYLIM)<crowdlim)
                    wny = YLIM(1)+dYLIM*edge;
                    wnx = x(1) + (wny-y(1))/slp;
                    HA = 'center';
                end
            elseif x(1)<XLIM(1)+dXLIM*edge
                if ~(ContainsYAxis && abs(XLIM(1)/dXLIM)<crowdlim)
                    wnx = XLIM(1)+dXLIM*edge;
                    wny = y(1) + (wnx-x(1))*slp;
                    HA = 'left';
                end
            else %--- x(1)>XLIM(2)-dXLIM*edge
                if ~(ContainsYAxis && abs(XLIM(2)/dXLIM)<crowdlim)
                    wnx = XLIM(2)-dXLIM*edge;
                    wny = y(1) + (wnx-x(1))*slp;
                    HA = 'right';
                end
            end
        end
        %---Select vertical alignment based on dy (slope in y)
        if dy<=0
            VA = 'top';
        else
            VA = 'bottom';
        end
    end
    %---Draw label if valid coordinate was determined
    if isnan(wnx) || isnan(wny)
        continue;
    end
    wnLabels(ct) = text(wnx,wny,Zlevel,wns(n),...
        Parent=ax,FontSize=FontSize,FontWeight=FontWeight,FontAngle=FontAngle,...
        Clipping='on',HorizontalAlignment=HA,VerticalAlignment=VA,...
        Tag='CSTgridLines',HitTest='off',PickableParts='none',...
        XLimInclude='off',YLimInclude='off',...
        UserData=struct('Options',Options,'Type',"z-plane"),HelpTopicKey='isofrequencygrid');
    ct = ct+1;
end
wnLabels = wnLabels(1:ct-1);

%---If the default locations for zeta labels is visible, use them
wndef = 3.5*pi/10;
zzdef = exp(wndef*(-zeta + 1i*sqrt(1-zeta.^2)));
zzdefr = real(zzdef);
zzdefi = imag(zzdef);
zzdefin = -zzdefi;
if all(zzdefr>=XLIM(1) & zzdefr<=XLIM(2) & zzdefi>=YLIM(1) & zzdefi<=YLIM(2)) || ...
        all(zzdefr>=XLIM(1) & zzdefr<=XLIM(2) & zzdefin>=YLIM(1) & zzdefin<=YLIM(2))
    wnzeta = wndef;

    %---Otherwise, select most-visible vector from wnmid values
else
    %---Create vector of values representing visible zeta range of each wnmid vector
    zdiff = zeros(size(wnmid));
    for n=1:length(wnmid)
        %---Find coordinates of wnmid line which lie within axes limits
        wnz = zwnmid(:,n);
        idx = find((real(wnz)>=XLIM(1))&(real(wnz)<=XLIM(2))&...
            (imag(wnz)>=YLIM(1))&(imag(wnz)<=YLIM(2)));
        if isempty(idx)
            zdiff(n) = 0;
        else
            %---Visible coordinate along wnmid which is closest to unit circle
            zmin = real((-((log(wnz(idx(1)))).^2)-(wnmid(n)).^2)./(2*wnmid(n)*log(wnz(idx(1)))));
            %---Visible coordinate along wnmid which is farthest from unit circle
            zmax = real((-((log(wnz(idx(end)))).^2)-(wnmid(n)).^2)./(2*wnmid(n)*log(wnz(idx(end)))));
            %---Fix round-off error
            if abs(zmin)<10*eps,   zmin = 0; end
            if abs(1-zmax)<10*eps, zmax = 1; end
            %---Visible zeta range
            zdiff(n) = zmax-zmin;
        end
    end
    %---wnmid value associated with max(zdiff) is where the zeta labels should go
    [~,zidx] = max(zdiff);
    wnzeta = wnmid(zidx);
end

%---Draw zeta labels
if abs(YLIM(2))>=abs(YLIM(1))
    wnzetasign = 1;
else
    wnzetasign = -1;
end
zz = exp(wnzeta*(-zeta + 1i*sqrt(1-zeta.^2)));
if strcmpi(Options.GridLabelType,'overshoot')
    dispzeta = exp(-(zeta*pi)./sqrt(1-zeta.*zeta));
    dispzeta = round(1e5*dispzeta)/1e3; % round off small values
else
    dispzeta = zeta;
end
zetaLabels = gobjects(length(zeta),1);
for n=1:length(zeta)
    zetaLabels(n) = text(real(zz(n)),wnzetasign*imag(zz(n)),Zlevel,sprintf('%0.3g',dispzeta(n)),...
        Parent=ax,FontSize=FontSize,FontWeight=FontWeight,FontAngle=FontAngle,...
        Clipping='on',HorizontalAlignment=HA,VerticalAlignment=VA,...
        Tag='CSTgridLines',HitTest='off',PickableParts='none',...
        XLimInclude='off',YLimInclude='off',...
        UserData=struct('Options',Options,'Type',"z-plane"),HelpTopicKey='isodampinggrid');
end

%---Return handles of new labels
labels = [wnLabels(:);zetaLabels(:)];
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