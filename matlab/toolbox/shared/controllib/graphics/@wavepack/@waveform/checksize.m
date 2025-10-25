function boo = checksize(this,dataobj)
%CHECKSIZE  Checks data size against waveform size.

%  Copyright 1986-2004 The MathWorks, Inc.
rcsize = getsize(dataobj);
boo = all(isnan(rcsize) | rcsize==[length(this.RowIndex),length(this.ColumnIndex)]);
