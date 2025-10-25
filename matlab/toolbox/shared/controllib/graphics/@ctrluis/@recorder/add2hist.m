function add2hist(h,HistoryLine)
%ADD2HIST  Adds entry to history record.

%   Copyright 1986-2004 The MathWorks, Inc.

h.History = [h.History ; {HistoryLine}];  
