function y = ntUint64()
%ntUint64 create numerictype('uint64')

%   Copyright 2020 The MathWorks, Inc.

    % by caching in persistent memory
    % this runs about 2.5X faster than repeated construction
    persistent v
    if isempty(v)
        v = embedded.numerictype;
        %v.DataTypeMode = 'Fixed-point: binary point scaling';
        v.SignednessBool = false;
        v.WordLength = 64;
        v.FixedExponent = 0;
    end
    y = copy(v);
end
