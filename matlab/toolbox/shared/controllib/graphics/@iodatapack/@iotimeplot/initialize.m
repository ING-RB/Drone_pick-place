function initialize(this, ax, iosize)
%  INITIALIZE  Initializes the @iotimeplot objects.
%
%  INITIALIZE(H, AX, iosize) creates an @ioaxesgrid object of size
%  [sum(iosize) 1 1 1] to display the plots.

%  Copyright 2013 The MathWorks, Inc.

% Axes geometry parameters
if iosize(1)==iosize(2)
   vg = 40;
else
   vg = 45;
end

geometry = struct('HeightRatio',[],...
   'HorizontalGap', 40, 'VerticalGap', vg, ...
   'LeftMargin', 0, 'TopMargin', 10);

% Create @axesgrid object
this.AxesGrid = iodatapack.axesrows(iosize, ax, ...
   'Visible',     'off', ...
   'Geometry',    geometry, ...
   'LimitFcn',  {@updatelims this}, ...
   'Title',   getString(message('Controllib:plots:strIOData')), ...
   'XLabel',  getString(message('Controllib:plots:strTime')),...
   'YLabel',  getString(message('Controllib:plots:strAmplitude')),...
   'XUnit',  'seconds');

% Generic initialization
init_graphics(this)

% Add listeners
addlisteners(this)
