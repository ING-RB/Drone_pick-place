function initialize(this,Axes)
%  INITIALIZE  Initializes @nicholsview objects.

%  Author(s): Bora Eryilmaz
%  Revised :
%  Copyright 1986-2013 The MathWorks, Inc.

% Create Nichols curves (Axes = HG axes to which curves are plotted)
[Ny,Nu] = size(Axes);
Curves = repmat(wrfc.createDefaultHandle,[Ny,Nu]);
for ct = Ny*Nu:-1:1
  Curves(ct) = handle(line('XData', NaN, 'YData', NaN, ...
		    'Parent',  Axes(ct), 'Visible', 'off'));
end

this.Curves = reshape(Curves,[Ny Nu]);