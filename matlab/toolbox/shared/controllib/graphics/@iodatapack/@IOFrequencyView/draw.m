function draw(this, Data, ~)
%DRAW  Draws frequency domain signal curves (mag, phase).
%
%  DRAW(VIEW,DATA) maps the response data in DATA to the curves in VIEW.

%  Copyright 2013 The MathWorks, Inc.
AxGrid = this.AxesGrid;
Ts = Data.Ts;

% Input and output sizes
N = numel(this.MagCurves);
Fac = funitconv(Data.FreqUnits,AxGrid.XUnits);
MU = Data.MagUnits;
PU = Data.PhaseUnits;
doComparePhase = strcmp(this.ComparePhase.Enable, 'on');
UnwrapOff = strcmp(this.UnwrapPhase, 'off');
Pi = unitconv(pi,'rad',AxGrid.YUnits{2});
for ct = 1:N
   Freq = Data.Frequency{ct}*Fac;
   Mag = unitconv(Data.Magnitude{ct}, MU, AxGrid.YUnits{1});
   Phase = unitconv(Data.Phase{ct}, PU, AxGrid.YUnits{2});
   % Eliminate zero frequencies in log scale
   if strcmp(AxGrid.XScale{1},'log')
      idxf = find(Freq>0);
      Freq = Freq(idxf);
      if ~isempty(Mag)
         Mag = Mag(idxf,:);
      end
      if ~isempty(Phase)
         Phase = Phase(idxf,:);
      end
   end
   s = size(Mag);
   if s(2)>1
      Mag1 = NaN(s(1)*s(2)+(s(2)-1),1); Freq1 = max(Freq)*ones(size(Mag1));
      L_ = 0;
      for ky = 1:s(2)
         Mag1(L_+(1:s(1)),1) = Mag(:,ky);
         Freq1(L_+(1:s(1)),1) = Freq;
         L_ = L_ + s(1) + 1;
      end
   else
      Mag1 = Mag; Freq1 = Freq;
   end
   set(double(this.MagCurves(ct)), 'XData', Freq1, 'YData', Mag1);
   
   % Mag Nyquist lines (invisible to limit picker)
   if Ts{ct}==0
      YData = [];  XData = [];
   else
      nf = pi/abs(Ts{ct})*Fac;
      YData = unitconv(infline(0,Inf),'abs',AxGrid.YUnits{1});
      XData = nf(:,ones(size(YData)));
   end
   set(this.MagNyquistLines(ct),'XData',XData,'YData',YData)
   
   % Phase curves
   if isempty(Phase)
      set([this.PhaseCurves(ct); this.PhaseNyquistLines(ct)], ...
         'XData', [], 'YData', [])
   else
      if UnwrapOff
         Branch = unitconv(this.PhaseWrappingBranch,'rad',AxGrid.YUnits{2});
         Phase = mod(Phase - Branch,2*Pi) + Branch;
      end
      
      % Phase Matching
      if doComparePhase
         idx = find(Freq>this.ComparePhase.Freq,1,'first');
         if isempty(idx)
            idx = 1;
         end
         
         % If compare Phase(idx,ct) is nan find nearest phase which is not
         % NaN to do comparison. Otherwise the phase response will become
         % NaN.
         if isnan(Phase(idx))
            [~, nidx] = sort(abs(Freq-Freq(idx)));
            nidx = nidx(find(~isnan(Phase(nidx)),1,'first'));
            if ~isempty(nidx)
               idx = nidx;
            end
         end
         n = round(abs(Phase(idx)-this.ComparePhase.Phase)/(2*Pi));
         Phase = Phase-sign(Phase(idx)-this.ComparePhase.Phase)*n*2*Pi;
      end
      
      if s(2)>1
         Phase1 = NaN(s(1)*s(2)+(s(2)-1),1); 
         L_ = 0;
         for ky = 1:s(2)
            Phase1(L_+(1:s(1)),1) = Phase(:,ky);
            L_ = L_ + s(1) + 1;
         end
      else
         Phase1 = Phase; 
      end
      
      set(double(this.PhaseCurves(ct)), 'XData', Freq1, 'YData', Phase1);
      
      % Phase Nyquist lines (invisible to limit picker)
      if Ts{ct}==0
         YData = [];  XData = [];
      else
         YData = infline(-Inf,Inf);
         XData = nf(:,ones(size(YData)));
      end
      set(this.PhaseNyquistLines(ct),'XData',XData,'YData',YData)
   end
end
