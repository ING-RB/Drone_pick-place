function xfocus = getfocus(this)
%GETFOCUS  Computes optimal X limits for Bode plots.
% 
%   XFOCUS = GETFOCUS(PLOT) merges the frequency ranges of all 
%   visible responses and returns the frequency focus in the current
%   frequency units (X-focus). XFOCUS controls which portion of the
%   frequency response is displayed when the x-axis is in auto-range
%   mode.

%   Copyright 1986-2021 The MathWorks, Inc.
FocusFcn = @(rdata) LocalGetFocus(rdata,this);
xfocus = resppack.resolveFreqFocus(this,...
   this.AxesGrid.XScale{1},this.AxesGrid.XUnits,FocusFcn);

%-------------------Local Functions ------------------------

function [xf,sf,ts] = LocalGetFocus(data, this)
% Determine log-scale frequency focus for individual response
if isfield(this.Options,'MinGainLimit')
   MinGainLimitPref = this.Options.MinGainLimit;
else
   MinGainLimitPref = struct('Enable','off','MinGain',0);
end
n = numel(data);
xf = zeros(n,2);
sf = false(n,1);
ts = zeros(n,1);
for ct=1:n
   if isempty(data(ct).Focus)
      xf(ct,:) = NaN;
   elseif strcmp(MinGainLimitPref.Enable,'on') %Check for Min Gain option
      minlvl = unitconv(MinGainLimitPref.MinGain, this.AxesGrid.YUnits{1}, data(ct).MagUnits);
      xmgf = LocalMinGainFocus(data(ct), minlvl);
      xf(ct,:) = xmgf*funitconv(data(ct).FreqUnits,'rad/s');
   else
      xf(ct,:) = data(ct).Focus*funitconv(data(ct).FreqUnits,'rad/s');
   end
   sf(ct) = data(ct).SoftFocus;
   ts(ct) = abs(data(ct).Ts);
end

%-----------------------------------

function xf = LocalMinGainFocus(data,minlvl)
% Min gain focus calculation, Calculates the x range subject to a lower
% magnitude constraint
Freq = abs(data.Frequency);
Mag = max(data.Magnitude(:,:),[],2);
FIS = Freq(Freq>=data.Focus(1) & Freq<=data.Focus(2) & Mag>=minlvl,:); % in scope
if isempty(FIS)
   xf = NaN(1,2);
else
   xf = [min(FIS) max(FIS)];
end
