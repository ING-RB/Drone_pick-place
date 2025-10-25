function adjustview(View,Data,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(VIEW,DATA,'postlim') adjusts the HG object extent once the 
%  axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Author(s): P. Gahinet
%  Copyright 1986-2011 The MathWorks, Inc.

AxGrid = View.AxesGrid;

if strcmp(Event,'postlim') && strcmp(AxGrid.YNormalization,'on')
   % Draw normalized data once X limits are finalized
   if isempty(Data.Amplitude)
      set(double(View.Curves(:)),'XData',[],'YData',[])
   else
      TimeData = Data.Time*tunitconv(Data.TimeUnits,AxGrid.XUnits);
      if isequal(Data.Ts,0)
         for ct=1:numel(View.Curves)
            Xlims = get(ancestor(View.Curves(ct),'axes'),'Xlim');
            YData = normalize(Data,Data.Amplitude(:,ct),Xlims*tunitconv(AxGrid.XUnits,Data.TimeUnits),ct);
            set(double(View.Curves(ct)),'XData',TimeData,'YData',YData)
         end
      else
         switch View.Style
            case {'stairs','stem'}
               for ct=1:numel(View.Curves)
                  Xlims = get(ancestor(View.Curves(ct),'axes'),'Xlim');
                  [T,Y] = stairs(TimeData,Data.Amplitude(:,ct));
                  Y = normalize(Data,Y,Xlims*tunitconv(AxGrid.XUnits,Data.TimeUnits),ct);
                  set(double(View.Curves(ct)),'XData',T,'YData',Y);
               end
         end
      end
   end
end

