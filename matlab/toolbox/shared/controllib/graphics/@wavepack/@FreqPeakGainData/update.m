function update(cd,r)
%UPDATE  Data update method @FreqPeakGainData class

%  Author(s): John Glass
%  Copyright 1986-2015 The MathWorks, Inc.

% Get data of parent response
X = cd.Parent.Frequency;  
Mag = cd.Parent.Magnitude;
Ph = cd.Parent.Phase;
nrows = length(r.RowIndex);
ncols = length(r.ColumnIndex);

% Compute Peak Response
Frequency = NaN(nrows, ncols);
PeakGain = NaN(nrows, ncols);
PeakPhase = NaN(nrows,ncols);
if ~isempty(Mag)
   for ct=1:nrows*ncols
      Yabs = Mag(:,ct);
      indMax = find(Yabs==max(Yabs),1,'last');
      % Check: indMax is not empty (e.g. Case where Yabs is all NaNs)
      if ~isempty(indMax)
         Frequency(ct) = X(indMax);
         PeakGain(ct) = Yabs(indMax);
         if ~isempty(Ph)
            PeakPhase(ct) = Ph(indMax,ct);
         end
      end
   end
end
cd.Frequency = Frequency;
cd.PeakGain = PeakGain;
cd.PeakPhase = PeakPhase;
