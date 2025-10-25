function [w,x,y,z] = parts(q)
%PARTS Extract quaternion parts
%   [W,X,Y,Z] = PARTS(Q) for a quaternion Q returns arrays that are the same size as Q
%   each holding a part of the quaternion W + X*i + Y*j + Z*k.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

w = q.a;
x = q.b;
y = q.c;
z = q.d;
end
