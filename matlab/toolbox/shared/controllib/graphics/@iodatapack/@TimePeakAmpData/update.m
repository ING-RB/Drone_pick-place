function update(cd,r)
%UPDATE  Data update method @TimePeakAmpData class

%   Copyright 2013-2015 The MathWorks, Inc.

% RE: Assumes response data is valid (shorted otherwise)
Data = cd.Parent;
u = Data.InputData;
y = Data.OutputData;
alldata = [y;u];
nrows = length(r.RowIndex);
ncols = length(r.ColumnIndex);
PeakData = cell(nrows,ncols);
Time = cell(nrows,ncols);
TU = cell(nrows,ncols);
% Compute Peak Value
for ct = 1:nrows
   Y = alldata(ct).Data;
   T = alldata(ct).Time;
   for j = 1:ncols
      if j==1
         YY = real(Y);
      else
         YY = imag(Y);
      end
      [~, iMax] = max(abs(YY),[],1);
      PeakData{ct,j} = zeros(1,numel(iMax));
      for k = 1:numel(iMax)
         PeakData{ct,j}(1,k) = YY(iMax(k),k);
      end
      Time{ct,j} = T(iMax);
      TU{ct,j} = alldata(ct).TimeInfo.Units;
   end
end
cd.Time = Time;
cd.PeakResponse = PeakData;
%RE: Peak data is in native time units that may be different across I/O
%channels.
cd.TimeUnit = TU;
