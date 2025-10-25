function c = classUnderlying(q)
%CLASSUNDERLYING Class of elements contained within a quaternion array
%   C = CLASSUNDERLYING(D) returns the name of the class of the elements
%   contained within the quaternion D.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

c = class(q.a);
end
