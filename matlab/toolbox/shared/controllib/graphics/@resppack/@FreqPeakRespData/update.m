function update(cd,r)
%UPDATE  Data update method @FreqPeakRespData class

%  Author(s): John Glass
%  Copyright 1986-2004 The MathWorks, Inc.

% Get data of parent response
X = cd.Parent.Frequency;
Y = cd.Parent.Response;
nrows = length(r.RowIndex);
ncols = length(r.ColumnIndex);

% Compute Peak Response
Frequency = NaN(nrows, ncols);
PeakResp = NaN(nrows, ncols);
if ~isempty(Y)
   for ct=1:nrows*ncols
      Yabs = abs(Y(:,ct));
      indMax = find(Yabs==max(Yabs),1,'last');
      Frequency(ct) = X(indMax);
      PeakResp(ct) = Y(indMax,ct);
   end
end
cd.Frequency = Frequency;
cd.PeakResponse = PeakResp;
