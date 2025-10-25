function clear(this)
%CLEAR  Clears data.

%  Author(s): Craig Buhr
%  Copyright 1986-2010 The MathWorks, Inc.

[this.Data.Poles] = deal({[]});
[this.Data.Zeros] = deal({[]});

this.Ts = [];