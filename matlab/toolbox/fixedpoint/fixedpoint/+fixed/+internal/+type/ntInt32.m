function y = ntInt32()
%ntInt32 create numerictype('int32')

%   Copyright 2020 The MathWorks, Inc.

    % by caching in persistent memory
    % this runs about 2.5X faster than repeated construction
    persistent v
    if isempty(v)
        v = embedded.numerictype;
        %v.DataTypeMode = 'Fixed-point: binary point scaling';
        v.SignednessBool = true;
        v.WordLength = 32;
        v.FixedExponent = 0;
    end
    y = copy(v);
end
