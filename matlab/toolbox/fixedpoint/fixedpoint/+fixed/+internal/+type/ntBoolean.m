function y = ntBoolean()
%ntBool create numerictype('boolean')

%   Copyright 2020 The MathWorks, Inc.

    % by caching in persistent memory
    % this runs about 2.5X faster than repeated construction
    persistent v
    if isempty(v)
        v = embedded.numerictype;
        v.DataTypeMode = 'Boolean';
    end
    y = copy(v);
end
