% Returns true if the data is a plain text type

% Copyright 2014-2023 The MathWorks, Inc.

function flag = isPlainTextType(data)
    flag = isa(data, 'datetime') || isa(data, 'duration') || ...
        isa(data, 'calendarDuration') || isa(data, 'categorical');
end
