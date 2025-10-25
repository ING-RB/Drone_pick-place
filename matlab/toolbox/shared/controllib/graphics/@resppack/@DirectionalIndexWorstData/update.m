function update(cd,~)
%UPDATE  Data update method

%  Copyright 1986-2004 The MathWorks, Inc.
Y = cd.Parent.Index;
if isempty(Y)
   cd.MinIndex = NaN;
   cd.Frequency = NaN;
else
   indMin = find(Y == min(Y),1,'last');
   cd.MinIndex = Y(indMin);
   cd.Frequency = cd.Parent.Frequency(indMin);
end