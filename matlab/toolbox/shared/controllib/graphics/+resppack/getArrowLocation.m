function [ia1,ia2] = getArrowLocation(X,Y,XLim,YLim)
% Find best location to place the arrows in BODE/SIGMA plots.
% IA1 is for the negative arrow and IA2 for the positive arrow.

%   Copyright 2021 The MathWorks, Inc.
iz = find(isnan(X));
ix = 1:numel(X);
% Note: X=|w| with NaN to separate w<0 and w>0
InScope = (X>XLim(1) & X<XLim(2) & Y>YLim(1) & Y<YLim(2));
ix1 = find(ix<iz-1 & InScope);  w1 = X(:,ix1);  % w<0 in scope, decreasing
ix2 = find(ix>iz & InScope);    w2 = X(:,ix2);  % w>0 in scope, increasing
if isempty(ix1) || isempty(ix2)
   % One or both of the branches is not visible. Put arrow near center of range
   wc = sqrt(XLim(1)*XLim(2));
   [~,ia1] = min(abs(w1-wc));  ia1 = ix1(ia1);
   [~,ia2] = min(abs(w2-wc));  ia2 = ix2(ia2);
else
   % Put arrows near frequency of maximum separation between the two curves
   w = logspace(log10(XLim(1)),log10(XLim(2)),10);
   Y1 = utInterp1(w1,Y(:,ix1),w);
   Y2 = utInterp1(w2,Y(:,ix2),w);
   [~,imax] = max(abs(Y1-Y2));
   [~,ia1] = min(abs(w1-w(imax)));  ia1 = ix1(ia1);
   [~,ia2] = min(abs(w2-w(imax)));  ia2 = ix2(ia2);
end
ia1 = [ia1 ia1+1];  % < iz
ia2 = [ia2 ia2+1];  % > iz
%X([ia1 ia2])