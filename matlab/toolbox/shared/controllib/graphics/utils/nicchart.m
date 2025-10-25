function [varargout] = nicchart(varargin)
%NICCHART  Generates the Nichols grid.
%
%    [PHASE,GAIN,LABELS] = NICCHART(PMIN,PMAX,GMIN) generates the
%    data for plotting the Nichols chart. PMIN and PMAX specify the
%    phase interval in degrees and GMIN is the smallest gain in dB.
%    NICCHART returns
%      * PHASE and GAIN: grid data
%      * LABELS: three-row matrix containing the x,y positions
%                and the label values
%
%    [GRIDHANDLES,TEXTHANDLES] = NICCHART(AX)  plots the Nichols chart
%    in the axis AX.  NICCHART uses the current axis limits.
%
%    [GRIDHANDLES,TEXTHANDLES] = NICCHART(AX,OPTIONS) specifies additional
%    grid options.  OPTION is a structure with fields:
%      * PhaseUnits: 'deg' or 'rad' (default = deg)
%      * Zlevel    : real scalar (default = 0)
%
%    See also NICHOLS, NGRID.

%   Authors: K. Gondoly and P. Gahinet
%   Copyright 1986-2003 The MathWorks, Inc.

% Note: GMIN is assumed to be in dB
ni = nargin;

% Defaults
Options = gridopts('nichols');
if ni==2 && isa(varargin{2},'struct')
    s = varargin{2};
    f = fieldnames(s);
    for ct=1:length(f)
        Options.(f{ct}) = s.(f{ct});
    end
end
PhaseUnits = Options.PhaseUnits;
MagUnits = Options.MagUnits;
LimInclude  = Options.LimInclude;
Zlevel  = Options.Zlevel;

% Framing
if ni==3
    [pmin,pmax,gmin] = deal(varargin{1:3});
else
    ax = varargin{1};
    % Bounding rectangle PMIN,PMAX,GMIN
    Xlim = ax.XLim;
    Ylim = ax.YLim;
    pmin = Xlim(1);
    pmax = Xlim(2);
    gmin = Ylim(1);
end

% Unit conversion
pmin = unitconv(pmin,PhaseUnits,'deg');
pmax = unitconv(pmax,PhaseUnits,'deg');
gmin = unitconv(gmin,MagUnits,'dB');

if isinf(gmin) %catch for 0 abs
    gmin = -100;
end

% Round Gmin from below to nearest multiple of -20dB,
% and Pmin,Pmax to nearest multiple of 360
gmin = min([-20 20*floor(gmin/20)]);
pmax = 360*ceil(pmax/360);
pmin = min(pmax-360,360*floor(pmin/360));

% (1) Generate isophase lines for following phase values:
p1 = [1 5 10 20 30 50 90 120 150 180];

% Gain points (in dB)
g1 = [6 3 2 1 .75 .5 .4 .3 .25 .2 .15 .1 .05 0 -.05 -.1 ...
    -.15 -.2 -.25 -.3 -.4 -.5 -.75 -1 -2 -3 -4 -5 -6 -9 ...
    -12 -16 -20:-10:max(-40,gmin) gmin(:,gmin<-40)];

% Compute gains GH and phases PH in H plane
[p,g] = meshgrid((pi/180)*p1,10.^(g1/20)); % in H/(1+H) plane
z = g .* exp(1i*p);
H = z./(1-z);
gH = 20*log10(abs(H));
pH = rem((180/pi)*angle(H)+360,360);

% Add phase lines for angle between 180 and 360 (using symmetry)
gH = [gH , gH];
pH = [pH , 360-pH];

% Each column of GH/PH corresponds to one phase line
% Pad with NaN's and convert to vector
m = size(gH,2);
gH = [gH ; NaN(1,m)];
pH = [pH ; NaN(1,m)];
gain = gH(:);   phase = pH(:);

% (2) Generate isogain lines for following gain values:
g2 = [6 3 1 .5 .25 0 -1 -3 -6 -12 -20 -40:-20:gmin];

% Phase points
p2 = [1 2 3 4 5 7.5 10 15 20 25 30 45 60 75 90 105 ...
    120 135 150 175 180];
p2 = [p2 , fliplr(360-p2(1:end-1))];

[g,p] = meshgrid(10.^(g2/20),(pi/180)*p2);  % mesh in H/(1+H) plane
z = g .* exp(1i*p);
H = z./(1-z);
gH = 20*log10(abs(H));
pH = rem((180/pi)*angle(H)+360,360);

% Each column of GH/PH describes one gain line
% Pad with NaN's and convert to vector
m = size(gH,2);
gH = [gH ; NaN(1,m)];
pH = [pH ; NaN(1,m)];
gain = [gain ; gH(:)];
phase = [phase ; pH(:)];

% Replicate Nichols chart if necessary
lp = length(phase);
dn = round((pmax-pmin)/360);     % number of 360 degree windup
gain = repmat(gain,dn,1);
phase = repmat(phase,dn,1);
shift = kron(pmin+360*(0:dn-1)',ones(lp,1));
ix = find(~isnan(phase));
phase(ix) = phase(ix) + shift(ix);
pH = pH + shift(end);

% Generate label output
labels = [pH(end-1,:) ; gH(end-1,:) ; g2];

if ni>=3
    % Return data only
    varargout = {phase,gain,labels};
else
    phase = unitconv(phase,'deg',PhaseUnits);
    gain = unitconv(gain,'dB',MagUnits);
    labels(1,:) = unitconv(labels(1,:),'deg',PhaseUnits);
    labels(2,:) = unitconv(labels(2,:),'dB',MagUnits);
    labels(3,:) = unitconv(labels(3,:),'dB',MagUnits);

    % Plot grid
    FSize   = ax.FontSize;
    FWeight = ax.FontWeight;
    FAngle  = ax.FontAngle;
    GridWidth = ax.GridLineWidth;
    GridStyle = ax.GridLineStyle;

    GridHandles = gobjects(2,1);
    GridHandles(1) = matlab.graphics.chart.primitive.Line(Parent=ax,...
        LineStyle=GridStyle,LineWidth=GridWidth,Tag='CSTgridLines',HitTest='off',...
        PickableParts='none',XLimInclude=LimInclude,YLimInclude=LimInclude,...
        XData=phase,YData=gain,ZData=Zlevel*ones(size(gain)));
    controllib.plot.internal.utils.setColorProperty(GridHandles(1),...
        "Color","--mw-graphics-borderColor-axes-tertiary");

    pcr = unitconv((pmin+180):360:pmax,'deg',PhaseUnits);
    gcr = unitconv(zeros(1,length(pcr)),'dB',MagUnits);
    GridHandles(2) = matlab.graphics.chart.primitive.Scatter(Parent=ax,...
        Marker='+',LineWidth=GridWidth,Tag='CSTgridLines',HitTest='off',...
        PickableParts='none',XLimInclude=LimInclude,YLimInclude=LimInclude,...
        XData=pcr,YData=gcr,ZData=Zlevel*ones(size(gcr)),...
        SizeData=get(groot,"DefaultLineMarkerSize")^2);
    controllib.plot.internal.utils.setColorProperty(GridHandles(2),...
        "MarkerEdgeColor","--mw-graphics-borderColor-axes-tertiary");

    TextHandles = gobjects(size(labels,2),1);
    for jloop = 1:length(TextHandles)
        switch MagUnits
            case 'dB'
                txt = sprintf(' %.3g dB', labels(3,jloop));
            otherwise
                txt = sprintf(' %.3g', labels(3,jloop));
        end
        TextHandles(jloop) = text(labels(1,jloop), labels(2,jloop), Zlevel, ...
            txt, Parent=ax,XLimInclude='off',YLimInclude='off',...
            FontWeight=FWeight,FontAngle=FAngle,FontSize=FSize, ...
            Tag='CSTgridLines',HitTest='off',PickableParts='none',Clipping='on');
    end
    controllib.plot.internal.utils.setColorProperty(TextHandles,...
        "Color","--mw-graphics-borderColor-axes-tertiary");

    % Position grid labels to multiple of 360 degree nearest to
    % rightmost X limit
    Xlim = ax.XLim;
    Ylim = ax.YLim;
    twopi = unitconv(360,'deg',PhaseUnits);
    DesiredX = twopi * round((0.02*Xlim(1)+0.98*Xlim(2))/twopi);  % desired position
    TextPositions = {TextHandles.Position};
    CurrentX = twopi * round(TextPositions{1}(1)/twopi);
    ShiftX = DesiredX-CurrentX;
    for h=TextHandles(:)'
        Position = h.Position;
        NewPosition = [Position(1)+ShiftX , Position(2:end)];
        if prod(NewPosition(1)-Xlim)<0 && ...
                prod(NewPosition(2)-Ylim)<0
            % Label within current axis limits
            set(h,Position=NewPosition,Visible='on')
        else
            set(h,Position=NewPosition,Visible='off')
        end

        % Change anchor point if label lies outside of axes limit
        ex = h.Extent;
        if ex(1)<Xlim(1)
            h.HorizontalAlignment = 'left';
        elseif ex(1)+ex(3)>Xlim(2)
            h.HorizontalAlignment = 'right';
        end
        if ex(2)<Ylim(1)
            h.VerticalAlignment = 'bottom';
        elseif ex(2)+ex(4)>Ylim(2)
            h.VerticalAlignment = 'top';
        end
    end
    % Send to back
    gridObjs = [GridHandles;TextHandles];
    otherObjs = ax.Children(:);
    for ii = numel(otherObjs):-1:1
        if any(otherObjs(ii)==gridObjs)
            otherObjs(ii) = [];
        end
    end
    ax.Children = [otherObjs;gridObjs];
    set(gridObjs,HandleVisibility='off');
    varargout = {GridHandles,TextHandles};
end
end