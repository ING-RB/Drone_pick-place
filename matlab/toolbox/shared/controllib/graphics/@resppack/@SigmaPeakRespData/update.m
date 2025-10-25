function update(cd,r)
%UPDATE  Data update method @SigmaPeakRespData class

%  Author(s): John Glass
%  Copyright 1986-2004 The MathWorks, Inc.
Y = cd.Parent.SingularValues;
if isempty(Y)
   cd.PeakGain = NaN;
   cd.Frequency = NaN;
else
   Y = Y(:,1);
   indMax = find(Y == max(Y),1,'last');
   cd.PeakGain = Y(indMax);
   cd.Frequency = cd.Parent.Frequency(indMax);
end