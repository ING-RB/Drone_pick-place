function baseIntClass = getEnumBaseType(enumClassname)
%

%   Copyright 2024 The MathWorks, Inc.

supers = superclasses(enumClassname);
possible = {'int8', 'uint8','int16', 'uint16', 'int32','uint32'};
for i=1:numel(possible)
    if any(strcmp(supers, possible{i}))
        baseIntClass = possible{i};
        return;
    end
end
baseIntClass = '';
end
