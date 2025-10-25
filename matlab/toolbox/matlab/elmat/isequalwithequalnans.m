function tf = isequalwithequalnans(a,b,varargin)
%ISEQUALWITHEQUALNANS True if arrays are numerically equal.
%
%   ISEQUALWITHEQUALNANS is not recommended. Use ISEQUALN instead.
%
%   See also ISEQUALN, ISEQUAL, EQ.

%   Copyright 1984-2024 The MathWorks, Inc.

tf = isequaln(a,b,varargin{:});

