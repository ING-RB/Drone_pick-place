function update(cd,r)
%UPDATE  Data update method @TimeMeanValueData class

%   Copyright 2005 The MathWorks, Inc.


% RE: Assumes response data is valid (shorted otherwise)
Y = cd.Parent.Amplitude;
nrows = length(r.RowIndex);
ncols = length(r.ColumnIndex);

% Compute Peak Response
MeanData = zeros(nrows, ncols);
for ct = 1:nrows*ncols
   % Compute mean
   MeanData(ct) = mean(Y(:,ct),1);
end
cd.Mean = MeanData;
