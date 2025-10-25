function draw(this, Data, varargin)
%DRAW  Draws Bode response curves.
%
%  DRAW(VIEW,DATA) maps the response data in DATA to the curves in VIEW.

% varargin for NormalRefresh

%  Copyright 1986-2021 The MathWorks, Inc.

if ~isempty(this.Context) && strcmp(this.Context.PlotType,'pspectrum')
   % predmaint plot
   this.Context.IVArray = Data.Context.IVArray;
   this.Context.IVNames = Data.Context.IVNames;
   if Data.Context.UsePatch
      localPredMaintViewPatch(this,Data,varargin{:})
   else
      localPredMaintViewCurves(this,Data,varargin{:})
   end
   return
end

Ts = Data.Ts;
AxGrid = this.AxesGrid;
if Ts~=0
   nf = pi/abs(Ts)*funitconv('rad/s',AxGrid.XUnits);
end

% Input and output sizes
[Ny, ~] = size(this.MagCurves);

% use abs(data) for plot since we are not tracking phase spectrum
if isprop(Data,'IsError') && Data.IsError
   Mag = abs(Data.Error.Magnitude);
   Freq = Data.Error.Frequency*funitconv(Data.FreqUnits,AxGrid.XUnits);
else
   Mag = abs(Data.Magnitude);
   Freq = Data.Frequency*funitconv(Data.FreqUnits,AxGrid.XUnits);
   % check if this is a predmaint plot and a slice needs to be extracted
   % for a particular IV instant.
end
Mag = idpack.specmagunitconv(Mag,Data.MagUnits,AxGrid.YUnits);

% Eliminate zero or negative frequencies in log scale
if strcmp(AxGrid.XScale{1},'log')
   idxf = find(Freq>0);
   Freq = Freq(idxf);
   if ~isempty(Mag)
      Mag = Mag(idxf,:);
   end
end

% Mag curves
for ct = 1:Ny^2
   % REVISIT: remove conversion to double (UDD bug where XOR mode ignored)
   set(double(this.MagCurves(ct)), 'XData', Freq, 'YData', Mag(:,ct));
end

% Mag Nyquist lines (invisible to limit picker)
if Ts==0
   YData = [];  XData = [];
else
   YData = idpack.specmagunitconv(infline(0,Inf),'abs',AxGrid.YUnits);
   XData = nf(:,ones(size(YData)));
end
set(this.MagNyquistLines,'XData',XData,'YData',YData)

%------------------------------------------------------------------------------------
function localPredMaintViewCurves(this,Data,varargin)
% predmaint view of ensemble member curves
% no nyquist line

AxGrid = this.AxesGrid;
Ts = Data.Ts;
[nMem, nsig] = size(Ts);
F1 = funitconv(Data.FreqUnits,AxGrid.XUnits);
P = this.Context;
nRPM = P.NominalRPM;
nPeaks = P.GeneralPlotOptions.MarkNumPeaks;

for k = 1:nsig
   Map = cell(0, 5);
   for ct = 1:nMem
      [t_,Ind] = localGetFrameIndex(P,ct,k);
      %if isequal(Ind, this.DrawnFrameRange), continue; end
      %this.DrawnFrameRange = Ind;
      for jt = 1:numel(Ind)
         Magct = idpack.specmagunitconv(abs(Data.Magnitude{ct,k}{Ind(jt)}),...
            Data.MagUnits,AxGrid.YUnits);
         Freqct = Data.Frequency{ct,k}{Ind(jt)}*F1;
         Map(end+1,1:3) = {t_(jt), Magct, Freqct};
         if isfinite(nRPM(k)) && nPeaks>0
            [pA,pw] = findpeaks(Magct,Freqct,'SortStr','descend','NPeaks',nPeaks);
            Map(end,4:5) = {pA, pw};
         end
      end
   end
   
   tv = cat(1,Map{:,1});
   [t,~] = unique(tv);
   axx = ancestor(this.MagCurves(k),'axes');
   c = findobj(axx,'type','line','tag','shadowcurves');
   delete(c);
   c = findobj(axx,'type','line','tag','orderpeaks');
   delete(c);
   
   MC = repmat(wrfc.createDefaultHandle,numel(t)-1);
   col = this.MagCurves(k).Color;
   
   if isempty(t)
      set(this.MagCurves(k), 'XData', NaN, 'YData', NaN,...
         'Tag','latestcurve');
   else
      for jt = 1:numel(t)
         J = find(tv==t(jt));
         Magp = []; Freqp = [];
         for jJ = 1:numel(J)
            M = Map{J(jJ),2};
            f = Map{J(jJ),3};
            Mp = Map{J(jJ),4};
            fp = Map{J(jJ),5};
            if jJ==1
               Mag = M;
               Freq = f;
            else
               Mag  = [Mag; NaN; M];
               Freq = [Freq;NaN; f];
            end
            [fp,I] = sort(fp,'ascend');
            Magp = [Magp; Mp(I)];
            Freqp = [Freqp; fp];
         end
         
         colt = col+(1-col)*(1-jt/numel(t));
         if jt<numel(t)
            MC(jt) = line(Freq, Mag, 'Color', colt,...
               'Tag','shadowcurves','parent',axx);
         else
            set(this.MagCurves(k), 'XData', Freq, 'YData', Mag,...
               'Tag','latestcurve');
         end
         
         if isfinite(nRPM(k)) && nPeaks>0
            %Freqp = [Freqp, NaN(nPeaks,1)]';
            %Magp = [Magp, NaN(nPeaks,1)]';
            line(Freqp,Magp,'LineStyle','none','Marker','s',...
               'MarkerEdgeColor',colt,'MarkerFaceColor',colt,...
               'Color','k','Parent',axx,'Tag','orderpeaks');
         end
      end
   end
end

%------------------------------------------------------------------------------------
function localPredMaintViewPatch(this,Data,varargin)
% predmaint view of spectral patch
% no nyquist line

AxGrid = this.AxesGrid;
Ts = Data.Ts;
[~, nsig] = size(Ts);
F1 = funitconv(Data.FreqUnits,AxGrid.XUnits);
P = Data.Context;
N = P.GeneralPlotOptions.NumSD;
for k = 1:nsig
   Ind = localGetFrameIndex(P,1,k);
   if isequal(Ind, this.DrawnFrameRange), continue; end
   this.DrawnFrameRange = Ind;
   Min = idpack.specmagunitconv(abs(Data.Min{k}{Ind}),Data.MagUnits,AxGrid.YUnits);
   Max = idpack.specmagunitconv(abs(Data.Max{k}{Ind}),Data.MagUnits,AxGrid.YUnits);
   Mean = abs(Data.Mean{k}{Ind});
   SD = abs(Data.SD{k}{Ind});
   Freqct = Data.CommonFrequency{k}{Ind}*F1;
   px = [Freqct; flipud(Freqct)];
   pz = -2 * ones(size(px));
   py = [Mean+N*SD; flipud(Mean-N*SD)];
   Mean = idpack.specmagunitconv(Mean,Data.MagUnits,AxGrid.YUnits);
   py = idpack.specmagunitconv(py,Data.MagUnits,AxGrid.YUnits);
   
   set(double(this.MinLines(k)), 'XData', Freqct, 'YData', Min);
   set(double(this.MaxLines(k)), 'XData', Freqct, 'YData', Max);
   set(double(this.MeanLines(k)), 'XData', Freqct, 'YData', Mean);
   set(double(this.MagPatches(k)), 'XData', px, 'YData', py, 'ZData',pz);
end

%------------------------------------------------------------------------------------
function [t,Ind] = localGetFrameIndex(P,ct,k)
% Get indices of the frames for a member and signal number.

t = 0;
if isempty(P.IVArray)
   Ind = 1;
   return
else
   IVVal = P.IVArray{ct,k};
   if size(IVVal,1)<=1
      Ind = 1;
      if ~isempty(IVVal)
         t = IVVal(1);
      end
      return
   end
end

% here on segmented data only
PeerIVs = extractAfter(P.IVNames{k},"/");
IVNames = predmaint.internal.options.SegmentationOptions.utGetSegmentIVNames(P.IVType);
IV1 = IVVal(:,PeerIVs==IVNames(1));
IV2 = IVVal(:,PeerIVs==IVNames(2));
if isempty(IV1) || isempty(IV2)
   error(message('predmaint:plot:SegmentationIVNotFound',IVNames(1),IVNames(2)))
end
T = P.IVInstant;
if isempty(T)
   Ind = 1;
elseif isscalar(T)
   Ind = predmaint.internal.utFindFrames(IV1, IV2, T);
   Ind = Ind(1); % plot only the closest one
else
   Ind = predmaint.internal.utFindFrames(IV1, IV2, T(1), T(2));
end
t = IV1(Ind);
