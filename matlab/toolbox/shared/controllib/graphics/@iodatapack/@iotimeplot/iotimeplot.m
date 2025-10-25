function h = iotimeplot(varargin)
%TIMEPLOT  Constructor for @iotimeplot class (time series plot).
%
%  H = IOTIMEPLOT(AX,[Ny Nu]) creates a @iotimeplot object with Ny+Nu axes
%  (channels) in the area occupied by the axes with handle AX.
%
%  H = IOTIMEPLOT([Ny Nu]) uses GCA as default axes.
%
%  H = IOTIMEPLOT([Ny Nu],'Property1','Value1',...) initializes the plot
%  with the specified attributes.

%  Copyright 2013 The MathWorks, Inc.

% Create class instance
h = iodatapack.iotimeplot;

% Parse input list
if ishghandle(varargin{1},'axes')
   ax = varargin{1};
   varargin = varargin(2:end);
else
   ax = gca;
end
gridsize = [sum(varargin{1}) 1 1 1];
h.IOSize = varargin{1};

% Check for hold mode
[h,HeldRespFlag] = check_hold(h, ax, gridsize);
if HeldRespFlag
   % Adding to an existing response (h overwritten by that response's handle)
   % RE: Skip property settings as I/O-related data may be incorrectly sized (g118113)
   return
end

% Generic property init
init_prop(h, ax, gridsize);

% User-specified initial values (before listeners are installed...)
h.set(varargin{2:end});

% Initialize the handle graphics objects used in @timeplot class.
h.initialize(ax, varargin{1});
