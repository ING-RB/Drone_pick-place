function str = rcinfo(this,RowName,ColName) %#ok<INUSL>
%RCINFO  Constructs data tip text locating component in axes grid.

%   Author(s): Pascal Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.

if isnumeric(RowName)
   % RowName = row index in axes grid. Display as Out(*)
   RowName = getString(message('Controllib:plots:strOutIndex',RowName));
end
if isnumeric(ColName)
   % ColName = column index in axes grid. Display as In(*)
   ColName = getString(message('Controllib:plots:strInIndex',ColName));
end

if isempty(ColName)
   str = getString(message('Controllib:plots:strOutputLabel',RowName));
elseif isempty(RowName)
   str = getString(message('Controllib:plots:strInputLabel',ColName));
else
   str = getString(message('Controllib:plots:strIOLabel',ColName,RowName));
end