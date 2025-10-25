function adjustview(cv,cd,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(cVIEW,cDATA,'prelim') hides HG objects that might interfere  
%  with limit picking.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlim') adjusts the HG object extent once  
%  the axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Author(s): P. Gahinet
%  Copyright 1986-2021 The MathWorks, Inc.

% Note: Only for SISO Bode plots
if ~isempty(cv.MagPoints) && strcmpi(Event,'postlim')
   % Clear all data
   set([cv.MagLines;cv.MagCrossLines;cv.PhaseLines;cv.PhaseCrossLines],...
      'xdata',[NaN NaN], 'ydata', [NaN NaN])
   set([cv.MagPoints;cv.PhasePoints],'xdata',NaN, 'ydata', NaN)

   rData = cd.Parent;
   if isempty(rData.Magnitude)
      % NaN system
      return
   end
   AxGrid = cv.AxesGrid;
   MagUnits = AxGrid.YUnits{1};
   PhaseUnits = AxGrid.YUnits{2};
   Xlim = get(cv.MagPoints(1).Parent,'Xlim');
   LOG = strcmp(AxGrid.XScale,'log');
   ZerodB = unitconv(1,'abs',MagUnits);
   Pi = unitconv(pi,'rad',PhaseUnits);
   
   % Adjust phase data
   Freq = rData.Frequency*funitconv(rData.FreqUnits,AxGrid.XUnits);
   Mag = unitconv(rData.Magnitude,rData.MagUnits,MagUnits);
   Phase = unitconv(rData.Phase,rData.PhaseUnits,PhaseUnits);
   PMPhase = unitconv(cd.PMPhase,'deg',PhaseUnits);
   if strcmp(cv.Parent.ComparePhase.Enable, 'on')
      ix = findNearestMatch(Freq,Phase,cv.Parent.ComparePhase.Freq);
      if ~isempty(ix)
         Offset = (2*Pi) * round((Phase(ix)-cv.Parent.ComparePhase.Phase)/(2*Pi));
         Phase = Phase-Offset;  PMPhase = PMPhase-Offset;
      end
   end
   if strcmp(cv.Parent.UnwrapPhase, 'off')
      Branch = unitconv(cv.Parent.PhaseWrappingBranch,'rad',PhaseUnits);
      Phase = mod(Phase - Branch,2*Pi) + Branch;
      PMPhase = mod(PMPhase - Branch,2*Pi) + Branch;
   end
   
   % Gain margin dots in scope
   GM = cd.GainMargin;
   XDot = cd.GMFrequency*funitconv(cd.FreqUnits,AxGrid.XUnits); % can be negative
   YDot = unitconv(1./GM,'abs', MagUnits);
   Xo = [Xlim -Xlim];
   Io = cell(1,4);
   nGM = 0;
   for ct=1:numel(GM)
      if GM(ct)>0 && GM(ct)<Inf
         F = XDot(ct);  Y = YDot(ct);
         if LOG
            X = abs(F);
         else
            X = F;
         end
         if X>=Xlim(1) && X<=Xlim(2)
            % Show as solid dot when in focus
            nGM = nGM+1;
            set(cv.MagPoints(nGM),'XData',X,'YData',Y,...
               'MarkerFaceColor',cv.MagPoints(1).Color,'UserData',ct)
            set(cv.MagLines(nGM),'XData',[X X],'YData',[ZerodB Y])
         else
            % Attach to one of the open-circle markers
            if LOG
               i = 1+(X>Xlim(2))+2*(F<0);
            else
               i = 1+(X>Xlim(2));
            end
            Io{i} = [Io{i} ct];
         end
      end
   end
   % Gain margin markers out of focus
   for j=1:numel(Xo)
      if ~isempty(Io{j})
         X = Xo(j);
         if LOG
            ind = find(sign(X)*Freq>0);
            X = abs(X);
            Y = utInterp1(log(abs(Freq(ind))),Mag(ind),log(X));
         else
            Y = utInterp1(Freq,Mag,X);
         end
         nGM = nGM+1;
         set(cv.MagPoints(nGM),'XData',X,'YData',Y,...
            'MarkerFaceColor','none','UserData',Io{j})
      end
   end
         
  % Phase margin dots
  PM = unitconv(cd.PhaseMargin,'deg',PhaseUnits);
  XDot = cd.PMFrequency*funitconv(cd.FreqUnits,AxGrid.XUnits);
  YDot = PMPhase;
  PMline = Pi * round((YDot-PM)/Pi); % nearest -180 mod 360 line
  Xo = [Xlim -Xlim];
  Io = cell(1,4);
  nPM = 0;
  for ct=1:numel(PM)
     if isfinite(PM(ct))
        F = XDot(ct);  Y = YDot(ct);
        if LOG
           X = abs(F);
        else
           X = F;
        end
        if X>=Xlim(1) && X<=Xlim(2)
           nPM = nPM+1;
           set(cv.PhasePoints(nPM),'XData',X,'YData',Y,...
              'MarkerFaceColor',cv.PhasePoints(1).Color,'UserData',ct)
           set(cv.PhaseLines(nPM),'XData',[X X],'YData',[PMline(ct) Y])
           set(cv.PhaseCrossLines(nPM),'XData',Xlim,'YData',PMline([ct ct]))
        else
           % Attach to one of the open-circle markers
           if LOG
              i = 1+(X>Xlim(2))+2*(F<0);
           else
              i = 1+(X>Xlim(2));
           end
           Io{i} = [Io{i} ct];
        end
     end
  end
  % Phase margin markers out of focus
  for j=1:numel(Xo)
     if ~isempty(Io{j})
        X = Xo(j);
        if LOG
           ind = find(sign(X)*Freq>0);
           X = abs(X);
           Y = utInterp1(log(abs(Freq(ind))),Phase(ind),log(X));
        else
           Y = utInterp1(Freq,Phase,X);
        end
        nPM = nPM+1;
        set(cv.PhasePoints(nPM),'XData',X,'YData',Y,...
           'MarkerFaceColor','none','UserData',Io{j})
     end
  end

   % 0dB line
   if nGM>0 || nPM>0
      set(cv.MagCrossLines(1),'XData',Xlim,'YData',[ZerodB ZerodB])
   end
   
end


%------------------------------
function ix = findNearestMatch(f,ph,f0)
% Watch for NaN phase (causes entire curve to become NaN)
f(isnan(ph),:) = NaN;
[~,ix] = min(abs(flipud(f)-f0));  % favor positive match when tie
ix = numel(f)+1-ix;