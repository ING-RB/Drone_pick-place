function xfocus = getfocus(this)
%GETFOCUS  Computes optimal X limits for Bode plots.
% 
%   XFOCUS = GETFOCUS(PLOT) merges the frequency ranges of all 
%   visible responses and returns the frequency focus in the current
%   frequency units (X-focus).  XFOCUS controls which portion of the
%   frequency response is displayed when the x-axis is in auto-range
%   mode.

%   Copyright 2013-2015 The MathWorks, Inc.
xunits = this.AxesGrid.XUnits;
FocusFcn = @(r) LocalGetFocus(r,this);
xfocus = resppack.resolveFreqFocus(this,this.AxesGrid.XScale{1},xunits,FocusFcn);

%-------------------Local Functions ------------------------

function [xf,sf,ts] = LocalGetFocus(data, this)

if isfield(this.Options,'MinGainLimit')
    MinGainLimitPref = this.Options.MinGainLimit;
else
    MinGainLimitPref = struct('Enable','off','MinGain',0);
end

sf = data.SoftFocus;
MinGainLimitPrefEnabled = strcmp(MinGainLimitPref.Enable,'on');
if isempty(data.Focus)
   xf = NaN(1,2);
elseif MinGainLimitPrefEnabled %Check for Min Gain option
   minlvl = unitconv(MinGainLimitPref.MinGain, this.AxesGrid.YUnits{1}, data.MagUnits);
   xf = LocalMinGainFocus(data, minlvl);
else
   xf = data.Focus;
end
ts = abs(cat(1,data.Ts{:}));

%-------------------------------------------------------------------------
function xf = LocalMinGainFocus(data,minlvl)
% Min gain focus calculation, Calculates the x range subject to a lower
% magnitude constraint
Freq = data.Frequency;
Mag = data.Magnitude;

%IOSize = data.IOSize;
%Mag = reshape(Mag,[MagSize(1), IOSize]);

% Find all freqpoints below minlvl
booc = cellfun(@(x)all((x <= minlvl),2),Mag,'uni',0);
xf = NaN(numel(booc),2);
for ct = 1:numel(xf)
   boo = booc{ct};
   Freqct = Freq{ct};
   MagSize = size(Mag{ct});
   if ~all(boo)
      Freqmin = data.Focus(1);
      Freqmax = data.Focus(2);
      if boo(1)
         xminidx = find(boo==0,1,'first');
         Freqmin = max(Freqct(xminidx-1),data.Focus(1));
      else
         idx = find(boo==1,1,'first');
         Freqi = Freqct(idx);
         if Freqi < data.Focus(1)
            Freqmin = Freqi/10;
         end
      end
      if boo(end)
         xmaxidx = MagSize(1) - find(flipud(boo)==0,1,'first') + 1;
         Freqmax = min(Freqct(xmaxidx+1),data.Focus(2));
      end
      xf(ct,:) = [Freqmin,Freqmax];
   end
end
xf = ltipack.mrgfocus(xf);