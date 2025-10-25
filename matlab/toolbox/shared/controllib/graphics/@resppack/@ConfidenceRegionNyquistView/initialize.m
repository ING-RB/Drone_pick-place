function initialize(this,Axes)
%INITIALIZE  Initialization for @UncertainPZView class

%  Author(s): Craig Buhr
%  Copyright 1986-2011 The MathWorks, Inc.

% Create empty curves
[Ny,Nu] = size(Axes);

% Create empty curves
UncertainNyquistCurves = zeros(Ny*Nu,1); 
UncertainNyquistNegCurves = zeros(Ny*Nu,1); 
UncertainNyquistMarkers = zeros(Ny*Nu,1); 
UncertainNyquistNegMarkers = zeros(Ny*Nu,1); 
for ct = 1:Ny*Nu
   UncertainNyquistCurves(ct,1) = line('XData', [], 'YData', [], ...
      'Parent',  Axes(ct), 'Visible', 'off');
   UncertainNyquistNegCurves(ct,1) = line('XData', [], 'YData', [], ...
      'Parent',  Axes(ct), 'Visible', 'off');
  UncertainNyquistMarkers(ct,1) = line('XData', [], 'YData', [], ...
      'Parent',  Axes(ct), 'Visible', 'off','Marker','+','LineStyle','none');
  UncertainNyquistNegMarkers(ct,1) = line('XData', [], 'YData', [], ...
      'Parent',  Axes(ct), 'Visible', 'off','Marker','+','LineStyle','none');
end
this.UncertainNyquistCurves = reshape(handle(UncertainNyquistCurves),[Ny Nu]);
this.UncertainNyquistNegCurves = reshape(handle(UncertainNyquistNegCurves),[Ny Nu]);
this.UncertainNyquistMarkers = reshape(handle(UncertainNyquistMarkers),[Ny Nu]);
this.UncertainNyquistNegMarkers = reshape(handle(UncertainNyquistNegMarkers),[Ny Nu]);