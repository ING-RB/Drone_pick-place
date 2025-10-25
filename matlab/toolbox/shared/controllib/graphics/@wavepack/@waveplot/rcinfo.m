function str = rcinfo(this,RowName,ColName)  %#ok<INUSD,INUSL>
%RCINFO  Constructs data tip text locating component in axes grid.

%   Author(s): Pascal Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.
if isnumeric(RowName)
   % RowName = row index in axes grid. Display as Ch(*)
   RowName = sprintf('Ch(%d)',RowName);
end
str =  getString(message('Controllib:plots:strChannelLabel',RowName));
