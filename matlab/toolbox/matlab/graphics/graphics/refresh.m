function refresh(h)
%REFRESH Refresh figure.
%   REFRESH causes the current figure window to be redrawn. 
%   REFRESH(FIG) causes the figure FIG to be redrawn.

%   D. Thomas   5/26/93
%   Copyright 1984-2020 The MathWorks, Inc.

if nargin==1
    if ~any(ishghandle(h, 'figure'))
        error(message('MATLAB:refresh:InvalidHandle'))
    end
else
    h = gcf;
end

% The following toggle of the figure color property is
% only to set the 'dirty' flag to trigger a redraw. 
% The Color_I property is set to avoid toggling the ColorMode to manual.
color = get(h,'Color');
if ~ischar(color) && all(color == [0 0 0])
    tmpcolor = [1 1 1];
else
    tmpcolor = [0 0 0];
end
set(h,'Color_I',tmpcolor,'Color_I',color);
