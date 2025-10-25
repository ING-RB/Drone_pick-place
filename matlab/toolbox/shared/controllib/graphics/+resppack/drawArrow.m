function drawArrow(harrow,X,Y,RelArrowSize)
% Draws arrowhead on line segment connecting (X(1),Y(1)) and (X(2),Y(2)). 
% The arrowhead point in the segment direction and is equilateral regardless 
% of scale, limits, and plot aspect ratio.

%   Copyright 1986-2021 The MathWorks, Inc.
if isempty(X)
   set(harrow,'Xdata',[],'Ydata',[])
else
   % Geometry
   ax = ancestor(harrow,'axes');
   Xlim = ax.XLim;
   Ylim = ax.YLim;
   AR = ax.PlotBoxAspectRatio(1:2);
   AR = AR/norm(AR);
   XLOG = strcmp(ax.XScale,'log');
   YLOG = strcmp(ax.YScale,'log');
   if XLOG
      Xlim = log10(Xlim);  X = log10(X);
   end
   if YLOG
      Ylim = log10(Ylim);  Y = log10(Y);
   end
   % data to pixel scale factors
   xsf = AR(1)/(Xlim(2)-Xlim(1));
   ysf = AR(2)/(Ylim(2)-Ylim(1));
   
   % Create arrowhead
   aux = exp(2i*pi/3);
   Z = RelArrowSize * [1 aux conj(aux)];   % equilateral triangle pointing east
   dir = complex((X(2)-X(1))*xsf,(Y(2)-Y(1))*ysf);   % desired pointing direction
   Z = Z * (dir/abs(dir));                 % rotate to point in desired direction
   % Note: Place arrow halfway to minimize risk of overlap and 
   %       to stay away from possible kinks at frequency points
   XData = (X(1)+X(2))/2 + real(Z)/xsf;
   YData = (Y(1)+Y(2))/2 + imag(Z)/ysf;
   if XLOG
      XData = 10.^XData;
   end
   if YLOG
      YData = 10.^YData;
   end
   set(harrow,'Xdata',XData,'Ydata',YData)
end