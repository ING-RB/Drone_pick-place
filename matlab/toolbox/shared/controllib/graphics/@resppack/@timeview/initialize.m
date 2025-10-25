function initialize(this,Axes)
%INITIALIZE  Initializes @timeview graphics.

%  Author(s): Bora Eryilmaz, John Glass
%  Revised  : Kamesh Subbarao
%  Copyright 1986-2012 The MathWorks, Inc.

% Create empty curves (Axes = HG axes to which curves are plotted)
[Ny,Nu] = size(Axes);
Curves = repmat(wrfc.createDefaultHandle,[Ny*Nu, 1]);
StemLines = repmat(wrfc.createDefaultHandle,[Ny*Nu, 1]);
for ct = Ny*Nu:-1:1
  Curves(ct,1) = handle(line('XData', NaN, 'YData', NaN, ...
		    'Parent',  Axes(ct), 'Visible', 'off','Tag','Curves'));
  StemLines(ct,1) = handle(line( NaN, NaN, ...
            'Parent',  Axes(ct),'Visible', 'off','HitTest','off','Tag','StemLines'));
end
this.Curves = reshape(Curves,[Ny Nu]);
this.StemLines = reshape(StemLines,[Ny Nu]);

