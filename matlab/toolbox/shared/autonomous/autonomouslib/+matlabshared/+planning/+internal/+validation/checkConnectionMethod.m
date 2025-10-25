function cmethod = checkConnectionMethod(cmethod, sourceName)
%cmethod = checkConnectionMethod(cmethod, sourceName)

%#codegen

% Copyright 2017-2018 The MathWorks, Inc.

validateattributes(cmethod, {'char','string'}, {'scalartext'}, ...
    sourceName, 'ConnectionMethod');

cmethod = validatestring(cmethod, {'Dubins','Reeds-Shepp'}, sourceName, ...
    'ConnectionMethod');
end
