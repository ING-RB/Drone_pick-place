function y = ntUint8()
%ntUint8 create numerictype('uint8')

%   Copyright 2020 The MathWorks, Inc.

    % by caching in persistent memory
    % this runs about 2.5X faster than repeated construction
    persistent v
    if isempty(v)
        v = embedded.numerictype;
        %v.DataTypeMode = 'Fixed-point: binary point scaling';
        v.SignednessBool = false;
        v.WordLength = 8;
        v.FixedExponent = 0;
    end
    y = copy(v);
end
