function h = RelativeIndexPlot(varargin)
% Constructor for @RelativeIndexPlot class
%
%  H = RelativeIndexPlot([1 1]) or H = RelativeIndexPlot creates a 
%  @RelativeIndexPlot object with a 1-by-1 @axesgrid object.
%
%  H = RelativeIndexPlot([1 1],'Property1','Value1',...) initializes the 
%  plot with the specified attributes.

%  Copyright 1986-2021 The MathWorks, Inc.

% Create class instance
h = resppack.RelativeIndexPlot;
%
% Parse input list
if nargin && isscalar(varargin{1}) && ishghandle(varargin{1},'axes')
   ax = varargin{1};
else
   ax = gca;
end
gridsize = [1 1];
%
% Check for hold mode
[h,HeldRespFlag] = check_hold(h, ax, gridsize);
if HeldRespFlag
   % Adding to an existing response (h overwritten by that response's handle)
   % RE: Skip property settings as I/O-related data may be incorrectly sized (g118113)
   return
end
%
% Generic property init
init_prop(h, ax, gridsize);
%
% User-specified initial values (before listeners are installed...)
h.set(varargin{2:end});

% Initialize the handle graphics objects used in @RelativeIndexPlot class.
h.initialize(ax, gridsize);
