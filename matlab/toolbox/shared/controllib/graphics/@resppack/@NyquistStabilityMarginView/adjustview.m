function adjustview(cv,cd,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(cVIEW,cDATA,'prelim') hides HG objects that might interfer  
%  with limit picking.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlim') adjusts the HG object extent once  
%  the axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Author(s): John Glass
%  Copyright 1986-2021 The MathWorks, Inc.
if ~isempty(cv.MagPoints) && strcmp(Event,'postlim')
   ax = cv.MagPoints(1).Parent;
   Xlim = ax.XLim;   Ylim = ax.YLim;
   
   % Clear all data
   set([cv.MagLines;cv.PhaseLines],'Xdata',[NaN NaN],'Ydata',[NaN NaN])
   set([cv.MagPoints;cv.PhasePoints],'Xdata',NaN,'Ydata',NaN)
   
   % Locate phase crossings for gain margin dots
   GM = cd.GainMargin;
   Xo = Xlim;   Io = cell(1,2);
   nGM = 0;
   for ct=1:numel(GM)
      if GM(ct)>0 && GM(ct)<Inf
         X = -1/GM(ct);
         if X>=Xlim(1) && X<=Xlim(2)
            % Show as solid marker
            nGM = nGM+1;
            set(cv.MagPoints(nGM),'XData',X,'YData',0,...
               'MarkerFaceColor',cv.MagPoints(1).Color,'UserData',ct)
            set(cv.MagLines(nGM),'XData',[-1 X],'YData',[0 0])
         else
            % Attach to left or right open-circle marker
            i = 1+(X>Xlim(2));
            Io{i} = [Io{i} ct];
         end
      end
   end
   % Gain margin markers out of focus
   for ct=1:numel(Io)
      if ~isempty(Io{ct})
         nGM = nGM+1;
         set(cv.MagPoints(nGM),'XData',Xo(ct),'YData',0,...
            'MarkerFaceColor','none','UserData',Io{ct})
      end
   end
      
   % Phase margin markers
   PM = (pi/180) * cd.PhaseMargin; % in rad
   [Xo,Yo] = localOpenMarkerLocations(Xlim,Ylim);
   Io = cell(size(Xo));
   nPM = 0;
   for ct=1:numel(PM)
      if isfinite(PM(ct))
         X = cos(pi+PM(ct));
         Y = sin(pi+PM(ct));
         if X>=Xlim(1) && X<=Xlim(2) && Y>=Ylim(1) && Y<=Ylim(2)
            % Display as solid dot when in focus
            nPM = nPM+1;
            set(cv.PhasePoints(nPM),'XData',X,'YData',Y,...
               'MarkerFaceColor',cv.MagPoints(1).Color,'UserData',ct)
            set(cv.PhaseLines(nPM),'XData',[0 X],'YData',[0 Y])
         elseif ~isempty(Io)
            % Attach to nearest location for open marker
            [~,imin] = min((Xo-X).^2+(Yo-Y).^2);
            Io{imin} = [Io{imin} ct];
         end
      end
   end
   % Phase margin markers out of focus
   for ct=1:numel(Io)
      if ~isempty(Io{ct})
         nPM = nPM+1;
         set(cv.PhasePoints(nPM),'XData',Xo(ct),'YData',Yo(ct),...
          'MarkerFaceColor','none','UserData',Io{ct})
      end
   end
end

%---------------------
function [Xo,Yo] = localOpenMarkerLocations(Xlim,Ylim)
% Find intersection points of limits bounding box with with unit circle
dx = 1e-3*(Xlim(2)-Xlim(1));
dy = 1e-3*(Ylim(2)-Ylim(1));
thx = acos(Xlim+[dx,-dx]);
thy = asin(Ylim+[dy,-dy]);
th = [thx, -thx, thy, pi-thy];
th = th(:,imag(th)==0);
Xo = cos(th);
Yo = sin(th);
ix = find(Xo>Xlim(1) & Xo<Xlim(2) & Yo>Ylim(1) & Yo<Ylim(2));
Xo = Xo(:,ix);
Yo = Yo(:,ix);

