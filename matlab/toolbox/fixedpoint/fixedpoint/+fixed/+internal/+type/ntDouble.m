function y = ntDouble()
%ntDouble create numerictype('double')

%   Copyright 2020 The MathWorks, Inc.

    % by caching in persistent memory
    % this runs about 2.5X faster than repeated construction
    persistent v
    if isempty(v) || ~isdouble(v)
        v = embedded.numerictype;
        v.DataTypeMode = 'Double';
    end
    y = copy(v);
end
