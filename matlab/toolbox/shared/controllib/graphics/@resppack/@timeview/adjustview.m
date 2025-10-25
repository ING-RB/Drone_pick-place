function adjustview(View,Data,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(VIEW,DATA,'postlim') adjusts the HG object extent once the 
%  axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Author(s): P. Gahinet
%  Copyright 1986-2012 The MathWorks, Inc.

AxGrid = View.AxesGrid;
if strcmp(Event,'postlim') && strcmp(AxGrid.YNormalization,'on')
    % Draw normalized data once X limits are finalized
    if isempty(Data.Amplitude)
       % NaN system
       set(double([View.Curves(:);View.StemLines(:)]),'XData',[],'YData',[])
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
             case 'stairs'
                for ct=1:numel(View.Curves)
                   Xlims = get(ancestor(View.Curves(ct),'axes'),'Xlim');
                   [T,Y] = stairs(TimeData,Data.Amplitude(:,ct));
                   Y = normalize(Data,Y,Xlims*tunitconv(AxGrid.XUnits,Data.TimeUnits),ct);
                   set(double(View.Curves(ct)),'XData',T,'YData',Y);
                end
             case 'stem'
                for ct=1:numel(View.Curves)
                   Xlims = get(ancestor(View.Curves(ct),'axes'),'Xlim');
                   YData = normalize(Data,Data.Amplitude(:,ct),Xlims*tunitconv(AxGrid.XUnits,Data.TimeUnits),ct);
                   set(double(View.Curves(ct)),'XData',TimeData,'YData',YData)
                   Y0 = normalize(Data,0,Xlims*tunitconv(AxGrid.XUnits,Data.TimeUnits),ct);
                   [T,Y] = localStems(TimeData,YData-Y0);
                   set(double(View.StemLines(ct)), 'XData', T,'YData', Y+Y0);
                end
          end
       end
    end
end


function [X,Y] = localStems(X0,Y0)

[m,n] = size(X0(:));
X = NaN(3*m,n);
X(1:3:3*m,:) = X0;
X(2:3:3*m,:) = X0;

[m,n] = size(Y0(:));
Y = zeros(3*m,n);
Y(2:3:3*m,:) = Y0;
Y(3:3:3*m,:) = NaN;

