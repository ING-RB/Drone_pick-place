function y = ntInt16()
%ntInt8 create numerictype('int16')

%   Copyright 2020 The MathWorks, Inc.

    % by caching in persistent memory
    % this runs about 2.5X faster than repeated construction
    persistent v
    if isempty(v)
        v = embedded.numerictype;
        %v.DataTypeMode = 'Fixed-point: binary point scaling';
        v.SignednessBool = true;
        v.WordLength = 16;
        v.FixedExponent = 0;
    end
    y = copy(v);
end
