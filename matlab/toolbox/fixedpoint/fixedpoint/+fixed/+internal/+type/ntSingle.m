function y = ntSingle()
%ntSingle create numerictype('single')

%   Copyright 2020 The MathWorks, Inc.

    % by caching in persistent memory
    % this runs about 2.5X faster than repeated construction
    persistent v
    if isempty(v)
        v = embedded.numerictype;
        v.DataTypeMode = 'Single';
    end
    y = copy(v);
end
