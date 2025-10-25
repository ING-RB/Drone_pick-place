function throwExactAttributeSuffixMatchError(attributeSuffix)
%

% Copyright 2020 The MathWorks, Inc.
    import matlab.io.xml.internal.write.*;
    msgid = "MATLAB:io:struct_:writestruct:FieldNameCannotBeExactAttributeSuffixMatch";
    error(message(msgid, attributeSuffix, attributeSuffix));
end
