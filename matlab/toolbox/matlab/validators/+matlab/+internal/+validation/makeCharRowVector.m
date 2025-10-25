function out = makeCharRowVector(value)
% makeCharRowVector is for internal use only and may be removed or
% modified at any time

% makeCharRowVector accepts a char array of any shape and coerces it to a
% row vector. If the input is a scalar string, it coerces it to a char
% value. All empty char and string inputs will be converted to a 0x0 char

%   Copyright 2019-2020 The MathWorks, Inc.
    if isempty(value)
        % Empty char and string values will always be coerced to 0x0 empty
        % char
        out = char.empty;
    elseif ischar(value)
        % Char values of any shape will be coerced to a row vector
        out = value(:)';
    else
        % Input is a not a char array and a non-empty string - String 
        % values are coerced to char values
        out = char(value);
    end
end
