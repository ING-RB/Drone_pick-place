function summary = getOneLineSummary(value,maxLength)
% This function is undocumented and may change in a future release.

% The second input argument, maxLength, only apples when the first input
% argument is a string scalar or character vector.

% Copyright 2022 The MathWorks, Inc.

import matlab.automation.internal.diagnostics.displayValue;
import matlab.display.internal.getEllipsisCharacter;

if nargin < 2
    maxLength = 20;
end

if builtin('islogical', value) && builtin('isscalar', value)
    summary = string(value);
    return;
end

s.f = value; %#ok<STRNU>
displayedValue = evalc('displayValue(s, false, 30);');
summary = regexp(displayedValue, 'f: (.*)', 'once','tokens','dotexceptnewline');
summary = string(summary{1});

if (builtin('ischar', value) && isrow(value)) ...
        || (builtin('isstring', value) && isscalar(value))
    % Further truncate chars and strings to maxLength characters
    % (maxLength+2 if you include the display quotes)
    maxLengthIncludingQuotes = maxLength + 2;
    len = summary.strlength;
    if len > maxLengthIncludingQuotes
        closingQuote = summary.extractAfter(len-1);
        suffix = getEllipsisCharacter + closingQuote;
        summary = summary.extractBefore(maxLengthIncludingQuotes-suffix.strlength+1) + suffix;
    end
end
end

% LocalWords:  STRNU dotexceptnewline isstring strlength
