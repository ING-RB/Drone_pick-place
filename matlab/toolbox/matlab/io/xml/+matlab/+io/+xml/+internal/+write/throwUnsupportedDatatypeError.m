function throwUnsupportedDatatypeError(datatypeName, debugString)
%

% Copyright 2020 The MathWorks, Inc.

    import matlab.io.xml.internal.write.*;

    supportedTypes = join([listSupportedDatatypes; "struct"], ", ");
    msgid = "MATLAB:io:xml:writestruct:UnsupportedDatatypeInStruct";
    msg = message(msgid, datatypeName, debugString, supportedTypes);
    error(msg);
end 
