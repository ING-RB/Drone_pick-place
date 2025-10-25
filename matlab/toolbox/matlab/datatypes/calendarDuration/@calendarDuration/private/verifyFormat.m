function fmt = verifyFormat(fmt)
%VERIFYFORMAT Validate calendarDuration format.
%   FMT = VERIFYFORMAT(FMT) returns the validated format, modified if
%   necessary so that FMT is a char array with the minimum required format
%   specifiers.

%   Copyright 2014-2020 The MathWorks, Inc.

import matlab.internal.datatypes.isCharString

try

    fmt = convertStringsToChars(fmt);
    if isCharString(fmt)
        
        yqmwdt = 'yqmwdt';
        [tf,i] = ismember(fmt,yqmwdt);
        
        % The empty string or strings with invalid characters are errors.
        if isempty(tf) || ~all(tf)
            error(message('MATLAB:calendarDuration:UnrecognizedFormat',fmt,yqmwdt));
            
        % Duplicate characters are an error.
        elseif any(diff(i)==0)
            error(message('MATLAB:calendarDuration:DuplicateFormatCharacters'));
        end
        
    else
        % Handle non-string input
        error(message('MATLAB:calendarDuration:InvalidFormat'));
    end
    
    % Fix calendarDuration formats that are simply missing a required
    % character.
    % The format string must include 'mdt'.
    % The format string may include:
    %    'y' (in which 12 months are rolled into 1 year)
    %    'q' (in which 3 months are rolled into 1 quarter)
    %    'w' (in which 7 days are rolled into 1 week)
    
    suggestedFmt = yqmwdt(union(i,[3 5 6]));
        
    % Out of order characters is an error.
    if ~all(diff(i)>0)
        error(message('MATLAB:calendarDuration:OutOfOrderFormatCharacters',fmt,suggestedFmt));
    end
    
    % If format does not include 'mdt', include these at minimum.
    if length(suggestedFmt) ~= length(fmt)
        
        % Warn on invalid format string, and put in correct format.
        warnState = warning('off','backtrace');
        c = onCleanup(@()warning(warnState));
        warning(message('MATLAB:calendarDuration:InvalidCalendarDurationFormatWarn',fmt,suggestedFmt));
        fmt = suggestedFmt;
        
    end
    
catch ME
    throwAsCaller(ME);
end
