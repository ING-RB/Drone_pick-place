function Td = single(obj)
%SINGLE Convert underlying matrix to single precision
%
%   Td = SINGLE(T) returns a new se3 object, Td, with the same data as T, but
%   using single as underlying data type.
%
%   See also double, cast.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if strcmp(underlyingType(obj), 'single')
        Td = obj;
    else
        Td = obj.fromMatrix(single(obj.M), size(obj.MInd));
    end

end
