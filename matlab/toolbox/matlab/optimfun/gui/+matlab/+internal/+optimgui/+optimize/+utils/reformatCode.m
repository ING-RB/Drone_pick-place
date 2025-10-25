function new_code = reformatCode(code, delim, newlineCode)
% This function inserts newlineCode (input argument) as generated code lines get long.
% Newlines are only inserted after delim (input argument) in the code
%
% INPUTS:
%   code (1, :) char - Original code
%   delim (1, :) char - where to break the code
%   newlineCode (1, :) char - code to make a new line
%
% OUTPUTS:
%   new_code (1, :) char - Code with any necessary newlines

% Copyright 2020-2021 The MathWorks, Inc.

% Default delim and newlineCode if not passed into the function
if nargin < 2
    delim = ',';
    newlineCode = [',...', newline, blanks(4)];
end

codeCell = strsplit(code, delim, 'CollapseDelimiters', false);

% Pre-allocate a cell array for the code that will go in-between each element of codeCell, default to delim
betweenCell = repmat({delim}, 1, numel(codeCell) - 1);

% Keep a running count of the characters in a given line.
% Back-tick chars should not count against line length
line_length = numel(codeCell{1}) - count(codeCell{1}, '`');

% Keep a running count of the delims added to the code in a given line since this adds characters
delim_count = 0;
delim_size = numel(delim);

% We don't want any line of code to exceed 80 characters. We need to account for
% code that is part of newlineCode
newlineCode_size = strfind(newlineCode, newline) - 1;

% Loop through each bit of code
for ct = 1:numel(codeCell) - 1
    
    % Update line length and delim count.
    % Back-tick chars should not count against line length
    next_length = numel(codeCell{ct + 1}) - count(codeCell{ct + 1}, '`');
    line_length = line_length + next_length;
    delim_count = delim_count + 1;
    
    % If character count passes a threshold, set newlineCode
    % as code in-between and reset the line length and delim counts
    if (line_length + (delim_count * delim_size)) > 80 - newlineCode_size
        betweenCell{ct} = newlineCode;
        line_length = next_length + 4; % +4 accounts for indent (blanks(4))
        delim_count = 0;
    end
end

% Weave together codeCell and betweenCell and return char vector
new_code = [codeCell; [betweenCell, {''}]];
new_code = new_code(:);
new_code = [new_code{:}];
end
