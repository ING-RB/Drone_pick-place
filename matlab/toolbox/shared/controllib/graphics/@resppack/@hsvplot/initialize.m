function initialize(this, ax, ~)
%  INITIALIZE  Initializes the @hsvplot objects.

%  Copyright 1986-2020 The MathWorks, Inc.

% Create @axes object
% RE: Title, etc initialized in HSVPlotOptions
Axes = ctrluis.axes(ax, ...
   'Visible',     'off', ...
   'LimitFcn',    {@updatelims this},...
   'XScale',      'Linear');

this.AxesGrid = Axes;

% Generic initialization
init_graphics(this)

% Add standard listeners
addlisteners(this)

% Other listeners
L = handle.listener(Axes,'PreLimitChanged',@(x,y) LocalAdjustView(this));
this.addlisteners(L);

%-------------------------- Local Functions ----------------------------

function LocalAdjustView(this)
% Prepares view for limit picker
if ~isempty(this.Responses)
   adjustview(this.Responses,'prelim')
end