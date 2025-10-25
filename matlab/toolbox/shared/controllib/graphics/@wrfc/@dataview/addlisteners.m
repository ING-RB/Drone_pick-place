function addlisteners(this, L)
%ADDLISTENERS  Adds new listeners to listener set.

%  Copyright 1986-2004 The MathWorks, Inc.
this.Listeners = [this.Listeners; L];
