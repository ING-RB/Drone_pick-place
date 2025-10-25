function data = discardZeros(data)

%   Copyright 2019-2020 The MathWorks, Inc.

% Target sends zeros for serial read, if requested bytes are not
% available. Filter out these zeros before storing to
% IOProtcol buffer.
if ~any(data)
    data = [];
end
end

