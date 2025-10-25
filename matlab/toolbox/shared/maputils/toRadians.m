function varargout = toRadians(fromUnits, varargin)
%toRadians Convert angles to radians
%
%   [R1,...,Rn] = toRadians(fromUnits,A1,...,An) converts the angles
%   specified by A1,...,An to radians from the angle units specified by
%   fromUnits. The value of fromUnits can be either 'degrees' or 'radians'
%   and may be abbreviated. The inputs A1,...,An and their corresponding
%   outputs are numeric arrays of various sizes, with size(Ri) matching
%   size(Ai) for i = 1,...,n.
%
%   See also: deg2rad, fromDegrees, fromRadians, toDegrees

% Copyright 2009-2019 The MathWorks, Inc.

varargout = abstractAngleConv( ...
    'radians', 'degrees', @deg2rad, fromUnits, varargin{:});
