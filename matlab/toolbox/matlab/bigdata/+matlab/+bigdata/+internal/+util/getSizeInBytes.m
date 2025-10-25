function bytes = getSizeInBytes(data) %#ok<INUSD>
%getSizeInBytes Get the size of a block of data in bytes.

% Copyright 2019 The MathWorks, Inc.

narginchk(1,1);
stats = whos('data');
bytes = stats.bytes;
end
