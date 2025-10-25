function fmt = verifyFormat(fmt,tz,warnForConflicts,acceptDefaultStr)
%VERIFYFORMAT Validate datetime format.
%   FMT = VERIFYFORMAT(FMT,TZ) validates datetime format FMT and timezone
%   TZ returning the validated format, modified if necessary.
%
%   FMT = VERIFYFORMAT(FMT,TZ,WARNFORCONFLICTS), when WARNFORCONFLICTS is
%   true, will warn if there are conflicts in FMT. WARNFORCONFLICTS is
%   false by default. See datetime::checkFormatWarnings in
%   formatErrorWarning.cpp for examples of conflicts.
%
%   FMT = VERIFYFORMAT(FMT,TZ,WARNFORCONFLICTS,ACCEPTDEFAULTSTR), when
%   ACCEPTDEFAULTSTR is true, forces permission of 'default' and
%   'defaultdate' as format strings to support setting an array's display
%   back to its default behavior. The difference between these two values
%   is not significant - when .fmt property is empty datetime would display
%   or not display the time of the day depending on what's in the data.
%   ACCEPTDEFAULTSTR is false by default.
%   
%   FMT = VERIFYFORMAT(FMT) returns the validated format, modified if
%   necessary so that FMT is a char array with the minimum required format
%   specifiers.

%   Copyright 2014-2020 The MathWorks, Inc.

arguments
    fmt
    tz
    warnForConflicts = false;
    acceptDefaultStr = false;
end

try
    % Verify that the format string is valid
    fmt = matlab.internal.datetime.validateFormatTokens(fmt,warnForConflicts,acceptDefaultStr);
    
    if ~isempty(fmt)
        try % Try out the format, ignore any return value
            matlab.internal.datetime.formatAsString(0,fmt,tz,false);
        catch ME
            matlab.internal.datatypes.throwInstead(ME,'MATLAB:datetime:mexErrors:FormatError',message('MATLAB:datetime:UnrecognizedFormat',fmt,getString(message('MATLAB:datetime:LinkToFormatDoc'))));
        end
    end

catch ME
    throwAsCaller(ME);
end

