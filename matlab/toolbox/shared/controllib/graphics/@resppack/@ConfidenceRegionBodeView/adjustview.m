function adjustview(this,Data,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlim') adjusts the HG object extent once
%  the axes limits have been finalized (invoked in response, e.g., to a
%  'LimitChanged' event).

%  Copyright 1986-2016 The MathWorks, Inc.

if strcmp(Event,'prelim')
   this.draw(Data);
   
elseif strcmp(Event,'postlim')
   
   % Input and output sizes
   [Ny, Nu] = size(this.UncertainMagPatch);
   
   if strcmpi(this.UncertainType,'Bounds')
      % Redraw the patch
      set(this.UncertainMagLines,'Visible','off');
      set(this.UncertainPhaseLines,'Visible','off');
      set(this.UncertainMagPatch,'Visible','on');
      set(this.UncertainPhasePatch,'Visible','on');
      % Map data to curves
      % Plot data as a line
      if isempty(Data.Data)
         % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires
         % finalized X limits)
         set(double(this.UncertainMagPatch),'XData',[],'YData',[],'ZData',[])
         set(double(this.UncertainPhasePatch),'XData',[],'YData',[],'ZData',[])
      else
         YUnits1 = this.Parent.AxesGrid.YUnits{1};
         YUnits2 = this.Parent.AxesGrid.YUnits{2};
         for ct = 1:Ny*Nu
            Freq = Data.Data(ct).Frequency*funitconv('rad/TimeUnit',...
               this.Parent.AxesGrid.xUnits,Data.TimeUnits);
            % One could have NaN bounds on finite data due to
            % interpolation effects
            Mag = Data.Data(ct).Magnitude(:);
            Ph = Data.Data(ct).Phase(:);
            dMag = Data.Data(ct).MagnitudeSD(:);
            dPh = Data.Data(ct).PhaseSD(:);
            if isempty(dMag), continue; end
            
            i1m = isnan(Mag);
            i1p = isnan(Ph);
            
            LowerMagnitudeBound = unitconv(Mag - dMag,'abs',YUnits1);
            UpperMagnitudeBound = unitconv(Mag + dMag,'abs',YUnits1);
            
            Pi = unitconv(pi,'rad',YUnits2);
            PhaseData = unitconv(Ph,'rad',YUnits2);
            PhaseSDData = unitconv(dPh,'rad',YUnits2);
            
            
            %%% Magnitude
            % Remove NaN entries
            iNaN = i1m | i1p;
            Freq = Freq(~iNaN);
            LowerMagnitudeBound = LowerMagnitudeBound(~iNaN);
            UpperMagnitudeBound = UpperMagnitudeBound(~iNaN);
            PhaseData = PhaseData(~iNaN);
            PhaseSDData = PhaseSDData(~iNaN);
            
            % Convert to axes units to determine elements that are not
            % finite.
            YLims = get(ancestor(this.UncertainMagPatch(ct),'axes'),'Ylim');
            TempLowerData = LowerMagnitudeBound;
            TempLowerData(~isfinite(LowerMagnitudeBound)) = YLims(1);
            TempUpperData = UpperMagnitudeBound;
            TempUpperData(~isfinite(TempUpperData)) = YLims(2);
            
            XData = [Freq;Freq(end:-1:1)];
            ZData = -2 * ones(size(XData));
            
            MagData = [TempUpperData(:);TempLowerData(end:-1:1)];
            set(double(this.UncertainMagPatch(ct)), 'XData', XData, ...
               'YData',MagData,'ZData',ZData);
            
            %%% Phase
            if strcmp(this.Parent.ComparePhase.Enable, 'on')
               ix = findNearestMatch(Freq,PhaseData,this.Parent.ComparePhase.Freq);
               if ~isempty(ix)
                  PhaseData = PhaseData - ...
                     (2*Pi) * round((PhaseData(ix)-this.Parent.ComparePhase.Phase)/(2*Pi));
               end
            end
            
            if strcmp(this.Parent.UnwrapPhase, 'off')
               Branch = unitconv(this.Parent.PhaseWrappingBranch,'rad',YUnits2);
               PhaseData = mod(PhaseData - Branch,2*Pi) + Branch;
            end
            
            PhaseBoundData = [PhaseData+PhaseSDData;PhaseData(end:-1:1)-PhaseSDData(end:-1:1)];
            set(double(this.UncertainPhasePatch(ct)), 'XData', XData, ...
               'YData',PhaseBoundData,'ZData',ZData);
         end
      end
   end
   
end


%------------------------------
function ix = findNearestMatch(f,ph,f0)
% Watch for NaN phase (causes entire curve to become NaN)
f(isnan(ph),:) = NaN;
[~,ix] = min(abs(flipud(f)-f0));  % favor positive match when tie
ix = numel(f)+1-ix;