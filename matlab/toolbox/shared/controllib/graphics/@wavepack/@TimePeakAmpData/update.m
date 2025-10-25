function update(cd,r)
%UPDATE  Data update method @TimePeakRespData class

%   Copyright 1986-2010 The MathWorks, Inc.


% RE: Assumes response data is valid (shorted otherwise)
X = cd.Parent.Time;
Y = cd.Parent.Amplitude;
S = size(Y);
nrows = length(r.RowIndex);
ncols = length(r.ColumnIndex);

% Compute Peak Response
Time = NaN(nrows, ncols);
PeakData = NaN(nrows, ncols);
if ~isempty(Y)
   for ct=1:nrows*ncols
      % Allow for scalar expansion, used for input view in LSIM
      cty = min(ct,prod(S(2:end)));
      % Compute peak
      Yabs = abs(Y(:,cty));
      indMax = find(Yabs==max(Yabs));
      indMax = indMax(end);   % to correctly compute Time for first-order-like systems
      Time(ct) = X(indMax);
      PeakData(ct) = Y(indMax,cty);
   end
end
cd.Time = Time;
cd.PeakResponse = PeakData;
cd.TimeUnits = cd.Parent.TimeUnits;
