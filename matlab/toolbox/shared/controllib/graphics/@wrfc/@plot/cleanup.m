function cleanup(this)
% cleanup Clean up function for @plot class

%  Author(s): Bora Eryilmaz
%  Copyright 1986-2008 The MathWorks, Inc.

delete(this.AxesGrid(ishandle(this.AxesGrid)))  
wfs = allwaves(this);
delete(wfs(ishandle(wfs))) 
this.Listeners.deleteListeners;