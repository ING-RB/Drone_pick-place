function boo = checksize(this,dataobj)
%CHECKSIZE  Checks data size against waveform size.

%  Copyright 2013 The MathWorks, Inc.
iosize = getIOSize(dataobj);
boo = all(isnan(iosize) | iosize==[length(this.OutputIndex),length(this.InputIndex)]);
