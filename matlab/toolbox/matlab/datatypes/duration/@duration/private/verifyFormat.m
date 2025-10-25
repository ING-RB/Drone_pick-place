function fmt = verifyFormat(fmt)
%VERIFYFORMAT Validate duration format.
%   FMT = VERIFYFORMAT(FMT) returns the validated format, modified if
%   necessary so that FMT is a char array.

%   Copyright 2014-2020 The MathWorks, Inc.

import matlab.internal.datatypes.isCharString
fmt = convertStringsToChars(fmt);
if isCharString(fmt)
    % In simplest cases (including the seconds, minutes, etc. functions), can
    % avoid overhead of calling the internal package function
    if ~isscalar(fmt) || all(fmt ~= 'ydhms')
        try % try out the format, ignore any return value
            matlab.internal.duration.formatAsString(1234.56789,fmt,false,false);
        catch ME
            throwAsCaller(MException(message('MATLAB:duration:UnrecognizedFormat',fmt)));
        end
    end
else
    throwAsCaller(MException(message('MATLAB:duration:InvalidFormat')));
end
