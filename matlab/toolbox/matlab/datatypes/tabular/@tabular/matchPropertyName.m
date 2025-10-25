function name = matchPropertyName(name,propertyNames,exact)
%MATCHPROPERTYNAME Validate a table property name.

%   Copyright 2012-2019 The MathWorks, Inc.

if ~matlab.internal.datatypes.isScalarText(name)
    error(message('MATLAB:table:InvalidPropertyName'));
end

if nargin < 2 || ~exact
    j = find(strncmpi(name,propertyNames,length(name)));
else
    j = find(matches(propertyNames,name));
end
if isempty(j)
    error(message('MATLAB:table:UnknownProperty', name));
elseif ~isscalar(j)
    error(message('MATLAB:table:AmbiguousProperty', name));
end

name = propertyNames{j};
