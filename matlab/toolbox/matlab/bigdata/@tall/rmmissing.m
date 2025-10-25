function [B, I] = rmmissing(A,varargin)
%RMMISSING   Remove rows or columns with missing entries
%
%   B = rmmissing(A)
%   B = rmmissing(A,dim)
%   B = rmmissing(___,Name,Value)
%   [B,I] = rmmissing(___)
%
%   Limitations:
%   1) 'DataVariables' cannot be specified as a function_handle
%   2) rmmissing(A,2) is not supported for tall tables.
%   3) Table and timetable inputs are not supported for
%      ''MissingLocations'' argument.
%
%   See also RMMISSING, TALL/ISMISSING, TALL/FILLMISSING

% Copyright 2017-2024 The MathWorks, Inc.

nargoutchk(0,2);
[B,I] = rmMissingOutliers('rmmissing',A,varargin{:});
