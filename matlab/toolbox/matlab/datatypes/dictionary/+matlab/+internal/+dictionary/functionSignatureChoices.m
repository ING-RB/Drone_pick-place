function names = functionSignatureChoices(d)
% Used to offer literal suggestions for dictionaries with string key type

%   Copyright 2022 The MathWorks, Inc.

keyType = types(d);

if keyType == "string"
    names = keys(d);
elseif keyType == "char"
    names = num2cell(keys(d));
else
    names = {};
end
