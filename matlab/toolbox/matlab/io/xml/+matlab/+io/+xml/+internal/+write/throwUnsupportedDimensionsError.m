function throwUnsupportedDimensionsError(debugString)
%

% Copyright 2020 The MathWorks, Inc.
    import matlab.io.xml.internal.write.*;
    msgid = "MATLAB:io:xml:writestruct:UnsupportedMultiDimensionalField";
    supportedDatatypes = join([listSupportedDatatypes(); "struct"], ", ");
    error(message(msgid, debugString, supportedDatatypes));
end
