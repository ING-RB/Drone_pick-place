function q = onesLike(obj,varargin)
%This function is for internal use only. It may be removed in the future. 
%ONESLIKE Create identity quaternion with an exemplar's datatype 

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

z = zeros(varargin{:},classUnderlying(obj));
o = ones(varargin{:},classUnderlying(obj));
q = obj.ctor(o,z,z,z);
end
