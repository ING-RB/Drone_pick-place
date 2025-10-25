function propNames = removeRenamedPropertyNames(propNames, dimensionNames)
% This function is undocumented and may change in a future release.

%   Copyright 2021 The MathWorks, Inc.

% removeRenamedPropertyNames gets AbstractScatter's renameable properties,
% renames them using dimensionNames, and then remove any exact matches from
% propNames

renamedProperties = string(matlab.graphics.chart.primitive.internal.AbstractScatter.getRenamableProperties);

% Rename properties using dimensionNames

xprops = renamedProperties.startsWith('X');
yprops = renamedProperties.startsWith('Y');
zprops = renamedProperties.startsWith('Z');

renamedProperties(xprops) = dimensionNames(1) + renamedProperties(xprops).extractAfter("X");
renamedProperties(yprops) = dimensionNames(2) + renamedProperties(yprops).extractAfter("Y");
renamedProperties(zprops) = dimensionNames(3) + renamedProperties(zprops).extractAfter("Z");

% Important to cast propNames to string, it may be a cell or a mix of
% string and cell. Wrapping in try/end to prevent errors due to string
% coercion, these should be caught elsewhere.
try
    propNames(ismember(string(propNames), renamedProperties)) = [];
end

end