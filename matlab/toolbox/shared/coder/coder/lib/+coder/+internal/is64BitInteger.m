function p = is64BitInteger(n)
%MATLAB Code Generation Private Function
%
%   Returns true if n belongs to either the class: int64 or uint64 and false
%   otherwise.

%   Copyright 2013-2019 The MathWorks, Inc.
%#codegen
coder.inline('always');
p = isa(n,'uint64') || isa(n,'int64');
