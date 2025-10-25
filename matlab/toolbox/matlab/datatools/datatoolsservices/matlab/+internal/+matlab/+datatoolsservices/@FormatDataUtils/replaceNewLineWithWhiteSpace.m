% Replace new lines and carriage returns with white space in a cell array of
% strings.

% Copyright 2015-2023 The MathWorks, Inc.

function vals = replaceNewLineWithWhiteSpace(r)
    % Replace the newlines and carriage return with white space.
    carriageReturn = internal.matlab.datatoolsservices.FormatDataUtils.CARRIAGE_RETURN;
    vals = cellfun(@(dt) strrep(strrep(dt, newline, ' '), carriageReturn, ' '), r, 'UniformOutput', false);
end
