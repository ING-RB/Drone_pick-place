function boo = isvisible(this)
%ISVISIBLE  Determines effective visibility of @waveform object.

%  Copyright 1986-2004 The MathWorks, Inc.
boo = strcmp(this.Visible,'on') && isvisible(this.Parent);