function initialize(this, Axes)
%INITIALIZE  Initializes @IOTimeView graphics.

%  Copyright 2013 The MathWorks, Inc.

% Create empty curves (Axes = HG axes to which curves are plotted)
[nr, nc] = size(Axes);
Curves = [];
for ct = nr*nc:-1:1
   % Note: Using NaN breaks to handle multidimensional signals   
   Curves(ct,1) = handle(line('Parent',Axes(ct), ...
      'Xdata',NaN, 'YData', NaN, 'Visible', 'off'));   
end
this.Curves = handle(reshape(Curves,[nr nc]));
