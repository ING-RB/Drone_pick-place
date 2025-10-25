function c = underlyingType(obj)
%underlyingType Class of matrices contained within array
%   C = underlyingType(D) returns the name of the class of the elements
%   contained within the array. C can be either 'single' or 'double'.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    c = class(obj.M);

end
