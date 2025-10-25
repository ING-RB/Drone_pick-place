function draw(this, Data,varargin)
% Draw method.

%  Author(s): P. Gahinet, C. Buhr
%  Copyright 1986-2014 The MathWorks, Inc.

hsv = Data.HSV;
nsv = numel(hsv);
nns = sum(isinf(hsv)); % number of infinite HSV
hsvf = hsv(nns+1:nsv,:);
aux = hsvf(hsvf>0,:);
if isempty(aux)
   minHSV = 1;
else
   minHSV = min(aux);
end

% Get Y limits, set baseline
Axes = this.AxesGrid;
Ylims = getylim(Axes,1);
LINSCALE = strcmp(Axes.YScale,'linear');
if LINSCALE
   BaseValue = 0;
elseif Ylims(1)>0
   BaseValue = 0.1*Ylims(1);
else
   BaseValue = 0.1*minHSV;
end

% Stable HSV
if nns==nsv
    % Setting data to [] has no effect on bar char
    % workaround for (g401115)
    set(this.FiniteSV,'Xdata',nan,'Ydata',nan)
elseif LINSCALE
   % Linear scale
   set(this.FiniteSV,'Xdata',nns+1:nsv,'YData',hsvf,'BaseValue',BaseValue)
else
   % Log scale
   hsvf(hsvf==0) = NaN;
   set(this.FiniteSV,'Xdata',nns+1:nsv,'YData',hsvf,'BaseValue',BaseValue)
end

% If no stable modes turn off its legend entry
hasbehavior(double(this.FiniteSV),'legend',(nns<nsv))

% Unstable HSV
if nns == 0
   % Setting data to [] has no effect on bar char
   % workaround for (g401115)
   set(this.InfiniteSV,'Xdata',nan,'Ydata',nan)
else
   set(this.InfiniteSV,'Xdata',1:nns,...
      'YData',repmat(2*Ylims(2),1,nns),'BaseValue',BaseValue)
end

% If no unstable modes turn off its legend entry
hasbehavior(double(this.InfiniteSV),'legend',(nns>0))

% Error bound (Note: last entry is always zero)
errbnd = Data.ErrorBound;
if all(isnan(errbnd(1:end-1)))
   % No error bound for band-limited,...
   set(this.ErrorBnd,'Xdata',NaN,'YData',NaN,'Zdata',NaN)
   hasbehavior(double(this.ErrorBnd),'legend',false)
else
   errbnd(errbnd<BaseValue) = BaseValue;
   set(this.ErrorBnd,'Xdata',0:nsv,'YData',errbnd,'ZData',ones(1,nsv+1))
   if strcmp(Data.ErrorType,'abs')
      this.ErrorBnd.DisplayName = getString(message('Controllib:plots:strHSVAbsoluteErrorBound'));
   else
      this.ErrorBnd.DisplayName = getString(message('Controllib:plots:strHSVRelativeErrorBound'));
   end
   hasbehavior(double(this.ErrorBnd),'legend',true)
end

% barseries.refresh messes up with the tick mode
hgAxes = getaxes(Axes);
set(hgAxes,'XTickMode','auto')

% Force ticks to be integer
XTicks = get(hgAxes,'XTick');
intXTicks = (XTicks-floor(XTicks))==0;
if ~all(intXTicks)
   % Set ticks to be integers
   set(hgAxes,'Xtick',XTicks(intXTicks));
end