function tf = isempty(obj)
%ISEMPTY True if input is an empty quaternion array

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

tf = isempty(obj.a);
end
