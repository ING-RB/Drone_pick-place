function update(cd,r)
%UPDATE  Data update method @MeanValueData class.

%   Copyright 2013-2015 The MathWorks, Inc.

% RE: Assumes response data is valid (shorted otherwise)
Data = cd.Parent;
u = Data.InputData;
y = Data.OutputData;
alldata = [y;u];
nrows = length(r.RowIndex);
ncols = length(r.ColumnIndex);
Mean = cell(nrows,ncols);

% Compute mean values
for ct = 1:nrows
   Y = alldata(ct).Data;
   for j = 1:ncols
      if j==1
         YY = mean(real(Y),1);
      else
         YY = mean(imag(Y),1);
      end
      Mean{ct,j} = YY;
   end
end
cd.Mean = Mean;
