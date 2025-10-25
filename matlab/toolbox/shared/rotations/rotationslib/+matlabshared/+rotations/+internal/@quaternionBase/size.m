function varargout = size(obj,varargin)
%SIZE Size of a quaternion array

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

[varargout{1:nargout}] = size(obj.a,varargin{:});
end
