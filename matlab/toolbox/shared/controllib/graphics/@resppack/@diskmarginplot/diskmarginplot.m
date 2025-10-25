function h = diskmarginplot(varargin)
% Constructor for @diskmarginplot class
%
%  H = DISKMARGINPLOT(AX) creates a @diskmarginplot object 
%  with a 1-by-1 @axesgrid object.
%
%  H = DISKMARGINPLOT(AX,'Property1','Value1',...) initializes the plot with the
%  specified attributes.

%  Copyright 1986-2014 The MathWorks, Inc.

% Create class instance
h = resppack.diskmarginplot;
% Parse input list
if nargin>0 && ishghandle(varargin{1},'axes')
   ax = varargin{1};  varargin = varargin(2:end);
else
   ax = controllib.chart.internal.utils.getEntryAxesForChart;
end
gridsize = [1 1];
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
h.set(varargin{:})
% Initialize the handle graphics objects
h.initialize(ax, gridsize);
