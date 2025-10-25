function initialize(this,Axes)
%INITIALIZE  Initializes @timeview graphics.

%  Author(s): Bora Eryilmaz, John Glass
%  Revised  : Kamesh Subbarao
%  Copyright 1986-2011 The MathWorks, Inc.

% Create empty curves (Axes = HG axes to which curves are plotted)
[Ny,Nu] = size(Axes);
Curves = [];
% StemLines = [];
for ct = Ny*Nu:-1:1
  Curves(ct,1) = line('XData', NaN, 'YData', NaN, ...
		    'Parent',  Axes(ct), 'Visible', 'off');
%   StemLines(ct,1) = line( NaN, NaN, ...
%             'Parent',  Axes(ct),'Visible', 'off','HitTest','off');
end
this.Curves = handle(reshape(Curves,[Ny Nu]));
% this.StemLines = handle(reshape(StemLines,[Ny Nu]));

