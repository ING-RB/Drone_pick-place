function finalListing = createBasicStruct(size)
%CREATEBASICSTRUCT Pre-allocate struct to be filled with dir output

% Copyright 2020 The MathWorks, Inc.
persistent listing 
if ~isstruct(listing)
    
    listing = struct("name", cell(1,1), "isdir", zeros(1,1), ...
                          "bytes", zeros(1,1), "date", '', "datenum", zeros(1,1));
end
finalListing = repmat(listing,[size,1]);
end
