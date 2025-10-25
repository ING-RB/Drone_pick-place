function draw(this, Data,~)
%DRAW  Draw method for the @sigmaview class (Singular Value Plots).

%   Copyright 1986-2012 The MathWorks, Inc.
AxGrid = this.AxesGrid;   
Freq = Data.Frequency;    % rad/s
SV = 1./Data.SingularValues; % abs

% Compute 0dB crossovers
nf = numel(Freq);
logSV = log(SV);
ic = find((logSV(1:nf-1)<=0 & logSV(2:nf)>=0) | (logSV(1:nf-1)>=0 & logSV(2:nf)<=0));
wc = Freq(ic) .* exp(-logSV(ic) .* log(Freq(ic+1)./Freq(ic))./(logSV(ic+1)-logSV(ic)));
gc = ones(size(wc));
if SV(1)<1
   wc = [Freq(1) ; wc];
   gc = [SV(1) ; gc];
end
if SV(end)<1
   wc = [wc ; Freq(end)];
   gc = [gc ; SV(end)];
end

% Create patches (each patch is a column in XData,YData)
XData = [];  YData = [];
for k=1:numel(wc)/2
   wStart = wc(2*k-1);  wEnd = wc(2*k);
   ix = find(Freq>wStart & Freq<wEnd);
   x = [wStart ; Freq(ix) ; wEnd ; wEnd ; flipud(Freq(ix)) ; wStart ; wStart];
   gStart = gc(2*k-1);  gEnd = gc(2*k);
   y = [gStart ; SV(ix) ; gEnd ; 1 ; ones(numel(ix),1) ; 1 ; gStart];
   [XData,YData] = localAppend(XData,YData,x,y);
end   
   
% Map data to patch
XData = XData*funitconv(Data.FreqUnits,AxGrid.XUnits);
YData = unitconv(YData,Data.MagUnits,AxGrid.YUnits);
ZData = this.ZLevel * ones(size(XData));
set(double(this.Patch), 'XData', XData, 'YData', YData,'ZData',ZData);

%----------------------
function [XData,YData] = localAppend(XData,YData,x,y)
% Pads columns to make them the same length
if isempty(XData)
   XData = x;  YData = y;
else
   m = size(XData,1)-size(x,1);
   XData = cat(2,[XData ; repmat(XData(end,:),[-m 1])],[x ; repmat(x(end),[m 1])]);
   YData = cat(2,[YData ; repmat(YData(end,:),[-m 1])],[y ; repmat(y(end),[m 1])]);
end