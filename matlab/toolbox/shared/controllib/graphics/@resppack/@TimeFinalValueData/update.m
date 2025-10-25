function update(cd,r)
%UPDATE  Data update method for @TimeFinalValueData class.

%   Copyright 1986-2023 The MathWorks, Inc.

% Compute final value responses for each of the data objects in the response
DataSrc = r.DataSrc;
if isempty(DataSrc)
   % No source, no info.
   cd.FinalValue = NaN(length(r.RowIndex),length(r.ColumnIndex));
else
   % If the response contains a source object compute the final value
   cd.FinalValue = real(getFinalValue(r.DataSrc,find(r.Data==cd.Parent),r));
end    
