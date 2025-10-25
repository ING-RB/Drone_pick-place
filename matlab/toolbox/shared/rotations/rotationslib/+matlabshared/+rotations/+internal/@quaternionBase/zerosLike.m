function o = zerosLike(obj,varargin)
%This function is for internal use only. It may be removed in the future. 
%ZEROSLIKE Create quaternion zeros with an exemplar's datatype 

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

z = zeros(varargin{:},classUnderlying(obj));
o = obj.ctor(z,z,z,z);
end
