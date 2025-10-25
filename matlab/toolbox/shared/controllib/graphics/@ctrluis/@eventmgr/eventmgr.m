function h = eventmgr(Container)
% Returns instance of @eventmgr class

%   Copyright 1986-2004 The MathWorks, Inc.

h = ctrluis.eventmgr;
if nargin
    h.SelectedContainer = Container;
end
