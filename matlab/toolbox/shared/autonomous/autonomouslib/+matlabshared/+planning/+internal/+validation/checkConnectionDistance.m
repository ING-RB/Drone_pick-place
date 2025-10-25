function cdist = checkConnectionDistance(cdist, sourceName)
%checkConnectionDistance(cdist, sourceName)

%#codegen

% Copyright 2017-2018 The MathWorks, Inc.

validateattributes(cdist, {'single','double'}, ...
    {'real', 'nonsparse', 'scalar', 'positive','nonnan'}, ...
    sourceName, 'ConnectionDistance');
end
