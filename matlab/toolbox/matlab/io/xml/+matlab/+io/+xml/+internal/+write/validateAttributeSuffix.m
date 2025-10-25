function attributeSuffix = validateAttributeSuffix(attributeSuffix)
%

% Copyright 2020 The MathWorks, Inc.

    validateattributes(attributeSuffix, ["string", "char"], "scalartext",...
                       "writestruct", "AttributeSuffix");
    attributeSuffix = string(attributeSuffix);
end
