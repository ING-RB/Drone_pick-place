function boo = isvisible(this)
%ISVISIBLE  Determines effective visibility of @plot object.

%  Copyright 1986-2014 The MathWorks, Inc.
boo = strcmp(this.Visible,'on') && (strcmp(this.AxesGrid.Parent.Visible,'on') || ...
    strcmp(this.AxesGrid.Parent.VisibleMode,'auto'));
