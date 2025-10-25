function h = axesstyle(ax)
% Returns instance of @axesstyle class

%   Author: P. Gahinet
%   Copyright 1986-2014 The MathWorks, Inc.

% RE: Optimized for speed

% Create @axesstyle instance 
h = ctrluis.axesstyle;

% Initialize with properties of supplied axes
if nargin
   ax = handle(ax);
   h.Color = ax.Color;
   h.FontAngle = ax.FontAngle;
   h.FontSize = ax.FontSize;
   h.FontWeight = ax.FontWeight;
   h.XColor = ax.XColor;
   h.XColorMode = ax.XColorMode;
   h.YColor = ax.YColor;
   h.YColorMode = ax.YColorMode;
   h.GridColor = ax.GridColor;
   h.GridColorMode = ax.GridColorMode;
end

% Listener to style changes
c = classhandle(h);
h.Listener = handle.listener(h,c.Properties(1:7),'PropertyPostSet',@LocalUpdateStyle);


%---------------------- Local Functions --------------------

function LocalUpdateStyle(eventsrc,eventdata)
% Evaluate the update fcn
h = eventdata.AffectedObject;
if strcmp(eventsrc.Name,'XColor') || strcmp(eventsrc.Name,'YColor') || strcmp(eventsrc.Name,'GridColor')
    h.([eventsrc.Name,'Mode']) = "manual";
end
if ~isempty(h.UpdateFcn)
   feval(h.UpdateFcn{1},eventsrc,eventdata,h.UpdateFcn{2:end});
end
