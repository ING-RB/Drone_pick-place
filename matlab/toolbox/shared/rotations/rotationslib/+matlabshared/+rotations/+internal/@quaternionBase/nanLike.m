function q = nanLike(obj,varargin)
%This function is for internal use only. It may be removed in the future. 
%NANLIKE Create NaN quaternion with an exemplar's datatype 

%   Copyright 2024 The MathWorks, Inc.    

%#codegen 

n = nan(varargin{:},classUnderlying(obj));
q = obj.ctor(n,n,n,n);
end
