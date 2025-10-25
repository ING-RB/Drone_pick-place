function adjustview(cv,cd,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 

%  Author(s): John Glass, P. Gahinet
%  Copyright 1986-2021 The MathWorks, Inc.

if ~isempty(cv.MagPoints) && strcmp(Event,'postlim')
   % Clear all data
   set([cv.MagLines;cv.MagCrossLines;cv.PhaseLines;cv.PhaseCrossLines],...
      'Xdata',[NaN NaN],'Ydata',[NaN NaN])
   set([cv.MagPoints;cv.PhasePoints],'Xdata',NaN,'Ydata',NaN)

   rData = cd.Parent;
   if isempty(rData.Magnitude)
      % NaN system
      return
   end
   AxGrid = cv.AxesGrid;
   ax = cv.MagPoints(1).Parent;
   Xlim = get(ax,'Xlim'); 
   Ylim = get(ax,'Ylim');
   
   % Adjust phase data
   ZerodB = unitconv(1,'abs',AxGrid.YUnits);
   Pi = unitconv(pi,'rad',AxGrid.XUnits);
   GMPhase = unitconv(cd.GMPhase,'deg',AxGrid.XUnits);
   PMPhase = unitconv(cd.PMPhase,'deg',AxGrid.XUnits);
   if strcmp(cv.Parent.ComparePhase.Enable, 'on')
      Freq = rData.Frequency*funitconv(rData.FreqUnits,'rad/s');
      Phase = unitconv(rData.Phase, rData.PhaseUnits, AxGrid.XUnits);
      ix = findNearestMatch(Freq,Phase,cv.Parent.ComparePhase.Freq);
      if ~isempty(ix)
         Offset = (2*Pi) * round((Phase(ix)-cv.Parent.ComparePhase.Phase)/(2*Pi));
         GMPhase = GMPhase - Offset;   PMPhase = PMPhase - Offset;
      end
   end
   if strcmp(cv.Parent.UnwrapPhase, 'off')
      Branch = unitconv(cv.Parent.PhaseWrappingBranch,'rad',AxGrid.XUnits);
      GMPhase = mod(GMPhase - Branch,2*Pi) + Branch;
      PMPhase = mod(PMPhase - Branch,2*Pi) + Branch;
   end
   
   % Locate phase crossings for gain margin dots
   GM = cd.GainMargin;
   XDot = GMPhase;
   YDot = unitconv(1./GM,'abs',AxGrid.YUnits);  
   Xo = unique(XDot);        % vertical lines anchoring GM dots
   Io = cell(2,numel(Xo));   % 1=bottom, 2=top
   nGM = 0;
   for ct=1:numel(GM)
      X = XDot(ct);  Y = YDot(ct);
      if GM(ct)>0 && GM(ct)<Inf && X>=Xlim(1) && X<=Xlim(2)
         % vertical line must be visible to show anything
         if Y>=Ylim(1) && Y<=Ylim(2)
            % Show as solid marker when in focus
            nGM = nGM+1;
            set(cv.MagPoints(nGM),'XData',X,'YData',Y,...
               'MarkerFaceColor',cv.MagPoints(1).Color,'UserData',ct)
            set(cv.MagLines(nGM),'XData',[X X],'YData',[ZerodB Y])
            set(cv.PhaseCrossLines(nGM),'XData',[X X],'YData',Ylim)
         else
            % Attach to top or bottom open-circle marker for XDot phase line
            i = 1+(Y>Ylim(2));  j = find(Xo==X);  
            Io{i,j} = [Io{i,j} ct];
         end
      end
   end
   % Gain margin markers out of focus
   for j=1:size(Io,2)
      for i=1:2
         if ~isempty(Io{i,j})
            nGM = nGM+1;
            set(cv.MagPoints(nGM),'XData',Xo(j),'YData',Ylim(i),...
               'MarkerFaceColor','none','UserData',Io{i,j})
            set(cv.PhaseCrossLines(nGM),'XData',Xo([j j]),'YData',Ylim)
         end
      end
   end
     
   % Phase margin markers
   PM = unitconv(cd.PhaseMargin, 'deg', AxGrid.XUnits);
   XDot = PMPhase;
   PmLine = Pi * round((XDot-PM)/Pi); % nearest -180 mod 360 line
   Xo = Xlim;  Io = cell(1,2);
   nPM = 0;
   for ct=1:numel(PM)
      if isfinite(PM(ct))
         X = XDot(ct);
         if X>=Xlim(1) && X<=Xlim(2)
            % Show as solid marker
            nPM = nPM+1;
            set(cv.PhasePoints(nPM),'XData',X,'YData',ZerodB,...
               'MarkerFaceColor',cv.PhasePoints(1).Color,'UserData',ct)
            set(cv.PhaseLines(nPM),'XData',[PmLine(ct) X],...
               'YData',[ZerodB ZerodB])
         else
            % Attach to left or right open-circle marker
            i = 1+(X>Xlim(2));
            Io{i} = [Io{i} ct];
         end
      end
   end
   % Phase margin markers out of focus
   for ct=1:numel(Io)
      if ~isempty(Io{ct})
         nPM = nPM+1;
         set(cv.PhasePoints(nPM),'XData',Xo(ct),'YData',ZerodB,...
          'MarkerFaceColor','none','UserData',Io{ct})
      end
   end
end 

%-------------------- local functions -------------------------------

function ix = findNearestMatch(f,ph,f0)
% Watch for NaN phase (causes entire curve to become NaN)
f(isnan(ph),:) = NaN;
[~,ix] = min(abs(flipud(f)-f0));  % favor positive match when tie
ix = numel(f)+1-ix;