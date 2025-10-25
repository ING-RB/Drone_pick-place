function xfocus = getfocus(this)
%GETFOCUS  Computes optimal X limits for Bode plots.
%
%   XFOCUS = GETFOCUS(PLOT) merges the frequency ranges of all
%   visible responses and returns the frequency focus in the current
%   frequency units (X-focus).  XFOCUS controls which portion of the
%   frequency response is displayed when the x-axis is in auto-range
%   mode.

%   Copyright 1986-2018 The MathWorks, Inc.

xunits = this.AxesGrid.XUnits;
Predmaint = ~isempty(this.Context) && strcmp(this.Context.PlotType,'pspectrum');
if Predmaint
   xfocus = localGetMinMaxFocus(this, xunits);
else
   FocusFcn = @(rdata) LocalGetFocus(rdata,this);
   xfocus = resppack.resolveFreqFocus(this,this.AxesGrid.XScale{1},xunits,FocusFcn);
end

%-------------------Local Functions ------------------------
function [xf,sf,ts] = LocalGetFocus(data, this)

if isfield(this.Options,'MinGainLimit')
   MinGainLimitPref = this.Options.MinGainLimit;
else
   MinGainLimitPref = struct('Enable','off','MinGain',0);
end

n = length(data);
xf = zeros(n,2);
sf = false(n,1);
ts = zeros(n,1);
for ct=1:n
   if isempty(data(ct).Focus)
      xf(ct,:) = NaN;
   elseif strcmp(MinGainLimitPref.Enable,'on') %Check for Min Gain option
      minlvl = idpack.specmagunitconv(MinGainLimitPref.MinGain, this.AxesGrid.YUnits, data(ct).MagUnits);
      xmgf = LocalMinGainFocus(data(ct), minlvl);
      xf(ct,:) = xmgf*funitconv(data(ct).FreqUnits,'rad/s');
   else
      xf(ct,:) = data(ct).Focus*funitconv(data(ct).FreqUnits,'rad/s');
   end
   sf(ct) = data(ct).SoftFocus;
   ts_ = data(ct).Ts;
   if iscell(ts_)
      ts_ = max(cell2mat(ts_));
   end
   ts(ct) = abs(ts_);
end

%--------------------------------------------------------------------------
function xf = LocalMinGainFocus(data,minlvl)
% Min gain focus calculation, Calculates the x range subject to a lower
% magnitude constraint
Freq = data.Frequency;
Mag = data.Magnitude;
MagSize = size(Mag);
IOSize = prod(MagSize(2:end));
Mag = reshape(Mag,[MagSize(1), IOSize]);

% Find all freqpoints below minlvl
boo = all((Mag <= minlvl),2);
if all(boo)
   xf = NaN(1,2);
else
   Freqmin = data.Focus(1);
   Freqmax = data.Focus(2);
   if boo(1)
      xminidx = find(boo==0,1,'first');
      Freqmin = max(Freq(xminidx-1),data.Focus(1));
   else
      idx = find(boo==1,1,'first');
      Freqi = Freq(idx);
      if Freqi < data.Focus(1)
         Freqmin = Freqi/10;
      end
   end
   if boo(end)
      xmaxidx = MagSize(1) - find(flipud(boo)==0,1,'first') + 1;
      Freqmax = min(Freq(xmaxidx+1),data.Focus(2));
   end
   xf = [Freqmin,Freqmax];
end

%------------------------------------------------------------------------------------
function xfocus = localGetMinMaxFocus(this, xunits)
% data based focus for predmain spectrum plot
r = this.Responses;
xfocus = [Inf, -Inf];
for ct = 1:numel(r)
   d = r(ct).Data;
   for k = 1:numel(d)
      foc = d(k).Focus;
      xfocus = [min([xfocus(1),foc(1)]),max([xfocus(2),foc(2)])];
   end
end
xfocus = xfocus*funitconv('rad/s',xunits);

% Protect against Xfocus = [a a] (g182099)
if xfocus(2)==xfocus(1)
   xfocus = xfocus .* [0.1,10] + [0 (xfocus(2)==0)];
end

if any(~isfinite(xfocus))
   xfocus = [0 1];
end
