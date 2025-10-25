function c = underlyingType(q)
%UNDERLYINGTYPE Class of elements contained within a quaternion array
%   C = UNDERLYINGTYPE(D) returns the name of the class of the elements
%   contained within the quaternion D.

%   Copyright 2022 The MathWorks, Inc.    

%#codegen 

c = class(q.a);
end
