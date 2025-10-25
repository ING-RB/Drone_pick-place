function xfocus = getfocus(this)
%GETFOCUS  Computes optimal X limits for Bode plots.
% 
%   XFOCUS = GETFOCUS(PLOT) merges the frequency ranges of all 
%   visible responses and returns the frequency focus in the current
%   frequency units (X-focus).  XFOCUS controls which portion of the
%   frequency response is displayed when the x-axis is in auto-range
%   mode.

%   Copyright 1986-2021 The MathWorks, Inc.
FocusFcn = @(rdata) LocalGetFocus(rdata);
xfocus = resppack.resolveFreqFocus(this,...
   this.AxesGrid.XScale{1},this.AxesGrid.XUnits,FocusFcn);

%-------------------Local Functions ------------------------

function [xf,sf,ts] = LocalGetFocus(data)
n = length(data);
xf = zeros(n,2);
sf = false(n,1);
ts = zeros(n,1);
for ct=1:n
   if isempty(data(ct).Focus)
      xf(ct,:) = NaN;
   else
      xf(ct,:) = data(ct).Focus;
   end
   sf(ct) = data(ct).SoftFocus;
   ts(ct) = abs(data(ct).Ts);
end
