function boo = isvisible(this)
%ISVISIBLE  Determines actual visibility of dataview object(s).

%  Copyright 1986-2004 The MathWorks, Inc.

% Vectorized
boo = strcmp(this.Visible,'on') & this(1).Parent.isvisible;
