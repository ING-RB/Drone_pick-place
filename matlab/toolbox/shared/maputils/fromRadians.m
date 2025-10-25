function varargout = fromRadians(toUnits, varargin)
%fromRadians Convert angles from radians
%
%   [A1,...,An] = fromRadians(toUnits,R1,...,Rn) converts the angles
%   specified by R1,...,Rn from radians to the angle units specified
%   by toUnits. The value of toUnits can be either 'degrees' or 'radians'
%   and may be abbreviated.  The inputs R1,...,Rn and their corresponding
%   outputs are numeric arrays of various sizes, with size(Ai) matching
%   size(Ri) for i = 1,...,n.
%
%   See also: fromDegrees, rad2deg, toDegrees, toRadians

% Copyright 2009-2019 The MathWorks, Inc.

varargout = abstractAngleConv( ...
    'radians', 'degrees', @rad2deg, toUnits, varargin{:});
