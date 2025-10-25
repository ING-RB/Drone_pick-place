function o = empty(varargin)
%EMPTY Create an empty array of quaternions

%   Copyright 2018 The MathWorks, Inc.    

a = double.empty(varargin{:});
b = double.empty(varargin{:});
c = double.empty(varargin{:});
d = double.empty(varargin{:});
o = quaternion(a,b,c,d);
end
