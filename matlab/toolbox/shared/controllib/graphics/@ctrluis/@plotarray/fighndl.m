function fig = fighndl(h)
%FIGHNDL  Gets handle of parent figure.

%   Copyright 1986-2008 The MathWorks, Inc.

if ishghandle(h.Axes(1),'axes')
   fig = h.Axes(1).Parent;
else
   fig = fighndl(h.Axes(1));
end
