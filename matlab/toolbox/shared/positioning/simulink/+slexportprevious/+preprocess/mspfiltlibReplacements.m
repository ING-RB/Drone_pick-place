function mspfiltlibReplacements(obj)
%mspfiltlibReplacements Removes unsupported mspfiltlib blocks during export operations.

% Copyright 2023 The MathWorks, Inc.

if isR2023bOrEarlier(obj.ver)
    obj.removeLibraryLinksTo('mspfiltlib/ecompass')
end