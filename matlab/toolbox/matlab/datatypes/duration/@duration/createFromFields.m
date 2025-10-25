function ms = createFromFields(fields)
%

%CREATEFROMFIELDS Calculate duration millisecond data from raw field data.
%   MS = CREATEFROMFIELDS(FIELDS) calculates millisecond data that can be
%   assigned directly to the 'millis' property of a duration. FIELDS must
%   be a cell array of numeric data.
%
%   MS = CREATEFROMFIELDS({H,MI,S}) returns millisecond data for a
%   duration of H hours, MI minutes, and S seconds.
%
%   MS = CREATEFROMFIELDS({H,MI,S,MS}) returns millisecond data for a
%   duration of H hours, MI minutes, S seconds, and MS milliseconds.

%   Copyright 2014-2024 The MathWorks, Inc.

try

    sz = [1 1];
    for i = 1:length(fields)
        f = fields{i};
        if ~isreal(f)
            error(message('MATLAB:duration:InputMustBeReal'));
        elseif isscalar(f)
            % OK
        elseif isequal(sz,[1 1])
            sz = size(f);
        elseif ~isequal(size(f),sz)
            error(message('MATLAB:duration:InputSizeMismatch'));
        end
    end

    h = double(fields{1});
    m = double(fields{2});
    s = double(fields{3});
    
    % Any field can be positive or negative, with any range, have a fractional
    % part, or be Inf or NaN.
    ms = full(h*3600000 + m*60000 + s*1000); % s -> ms
    
    if length(fields) == 4
        ms = ms + double(fields{4});
    end

catch ME
    throwAsCaller(ME);
end
