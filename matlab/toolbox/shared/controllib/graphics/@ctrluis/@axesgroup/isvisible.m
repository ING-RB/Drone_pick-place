function boo = isvisible(this)
%ISVISIBLE  Determines effective visibility of @axesgroup object.

%  Copyright 1986-2014 The MathWorks, Inc.
boo = strcmp(this.Visible,'on') && (strcmp(this.Parent.Visible,'on') || ...
    strcmp(this.Parent.VisibleMode,'auto'));
