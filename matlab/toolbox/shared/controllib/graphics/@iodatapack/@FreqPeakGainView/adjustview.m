function adjustview(cv,cd,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits.
%
%  ADJUSTVIEW(cVIEW,cDATA,'prelim') hides HG objects that might interfer
%  with limit picking.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlimit') adjusts the HG object extent once
%  the axes limits have been finalized (invoked in response, e.g., to a
%  'LimitChanged' event).

%   Copyright 2013 The MathWorks, Inc.

if strcmp(Event,'postlim')
   % Position dot and lines given finalized axes limits
   AxGrid = cv.AxesGrid;
   Xauto = strcmp(AxGrid.XlimMode,'auto');
   rData = cd.Parent;
   FreqFactor = funitconv(rData.FreqUnits, cv.AxesGrid.XUnits);
   MagUnits = AxGrid.YUnits;
   if iscell(MagUnits)
      MagUnits = MagUnits{1};  % mag/phase plots
   end
   
   % Position dot and lines given finalized axes limits
   nr = numel(cv.Points);
   for ct = 1:nr
      % Parent axes and limits
      ax = cv.Points(ct).Parent;
      Freq = FreqFactor * rData.Frequency{ct};
      Xlim = get(ax,'Xlim');
      Ylim = get(ax,'Ylim');
      
      % Adjust dot position based on the X limits
      XDot = FreqFactor * cd.Frequency{ct};
      if strcmp(AxGrid.XScale,'log')
         Xlim(1) = max(Xlim(1), eps);
         XDot = max(XDot, eps);
      end
      OutScope = (Xauto(ceil(ct/nr)) & (XDot<Xlim(1) | XDot>Xlim(2)));
      YDot = unitconv(cd.PeakGain{ct},rData.MagUnits,MagUnits);
      if any(OutScope) && length(Freq)>1
         % Dot falls outside auto limit box
         XDot(OutScope) = max(Xlim(1),min(Xlim(2),XDot(OutScope)));
         MagData = unitconv(rData.Magnitude{ct},rData.MagUnits,MagUnits);
         if strcmp(AxGrid.XScale,'log')
            % Remove any points in the frequency response that are zero
            ind = find(Freq ~= 0);
            Freq = Freq(ind);
            MagData = MagData(ind,:);
            YDot(OutScope) = utInterp1(log(Freq),MagData,log(XDot(OutScope)));
         else
            YDot = utInterp1(Freq,MagData,XDot(OutScope));
         end
         Color = get(ax,'Color');   % open circle
      else
         Color = get(cv.Points(ct),'Color');
      end
      Invalid = OutScope | isnan(XDot);
      
      if numel(XDot)>1
         HlineX = zeros(1,0);  HlineY = zeros(1,0);
         VlineX = zeros(1,0);  VlineY = zeros(1,0);    
         InvalidV = true(1,0);
         for j = 1:numel(XDot)
            HlineX = [HlineX, Xlim(1), XDot(j), NaN]; %#ok<*AGROW>
            HlineY = [HlineY, YDot(j), YDot(j), NaN];
            VlineX = [VlineX, XDot(j), XDot(j), NaN];
            VlineY = [VlineY, Ylim(1), YDot(j), NaN];
            InvalidV = [InvalidV, Invalid(j), Invalid(j), false];
         end
         HlineX = HlineX(1:end-1);
         HlineY = HlineY(1:end-1);
         LineZ = -10*ones(size(HlineX));
         ZDot = 5*ones(size(XDot));
         VlineX = VlineX(1:end-1);
         VlineY = VlineY(1:end-1);
         InvalidV = InvalidV(1:end-1);      
      else
         HlineX = [Xlim(1), XDot];
         HlineY = [Ylim(1), YDot];
         VlineX = [XDot XDot];
         VlineY = [Ylim(1) YDot];
         LineZ = [-10, -10];
         ZDot = 5;
         InvalidV = [Invalid, Invalid];
      end
      HlineX(InvalidV) = NaN;
      HlineY(InvalidV) = NaN;
      VlineX(InvalidV) = NaN;
      VlineY(InvalidV) = NaN;
      
      set(double(cv.HLines(ct)),'XData',HlineX,'YData',HlineY,'Zdata',LineZ)
      set(double(cv.VLines(ct)),'XData',VlineX,'YData',VlineY,'Zdata',LineZ)
      
      % Position dots
      set(double(cv.Points(ct)),'XData',XDot,'YData',YDot, 'Zdata', ZDot,...
         'MarkerFaceColor',Color,'Linestyle','none')
   end
end
