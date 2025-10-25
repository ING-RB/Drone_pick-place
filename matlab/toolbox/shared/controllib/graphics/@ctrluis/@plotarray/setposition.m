function setposition(h,Position)
%SETPOSITION   Sets plot array position and refreshes plot.

%   Author(s): P. Gahinet
%   Copyright 1986-2004 The MathWorks, Inc.

h.Position = Position;  % RE: no listener!
% Refresh plot
if h.Visible
   refresh(h)
end
