function outname = matchPropertyName(inname,propertyNames,exact)  %#codegen
%MATCHPROPERTYNAME Validate a table property name.

%   Copyright 2019 The MathWorks, Inc.
if nargin < 3
    exact = false;
end
coder.internal.prefer_const(exact);

coder.internal.assert(matlab.internal.coder.datatypes.isScalarText(inname),...
    'MATLAB:table:InvalidPropertyName');

inname_len = length(inname);
j = 0;
coder.unroll();
for i = 1:numel(propertyNames)
    if (exact && strcmp(inname,propertyNames{i})) || ...
            (~exact && strncmpi(inname,propertyNames{i},inname_len))
        coder.internal.assert(j == 0, 'MATLAB:table:AmbiguousProperty', inname);
        j = i;
    end
end
coder.internal.assert(j > 0, 'MATLAB:table:UnknownProperty', inname);
outname = propertyNames{j};
