function Td = double(obj)
%DOUBLE Convert underlying matrix to double precision
%
%   Td = DOUBLE(T) returns a new se3 object, Td, with the same data as T, but
%   using double as underlying data type.
%
%   See also single, cast.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    if strcmp(underlyingType(obj), 'double')
        Td = obj;
    else
        Td = obj.fromMatrix(double(obj.M), size(obj.MInd));
    end

end
