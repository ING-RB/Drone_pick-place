function obj = uminus(obj)
% - Unary Minus for quaternions
%   -A negates the elements of A

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

obj.a = -obj.a;
obj.b = -obj.b;
obj.c = -obj.c;
obj.d = -obj.d;
end
