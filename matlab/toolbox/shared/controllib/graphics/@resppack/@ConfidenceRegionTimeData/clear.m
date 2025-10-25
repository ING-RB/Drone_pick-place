function clear(this)
%CLEAR  Clears data.

%  Author(s): Craig Buhr
%  Copyright 1986-2010 The MathWorks, Inc.


% This needs to be a vectorized clear
set(this,'Data', [], 'Ts',[]);