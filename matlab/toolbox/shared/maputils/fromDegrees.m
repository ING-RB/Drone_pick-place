function varargout = fromDegrees(toUnits, varargin)
%fromDegrees Convert angles from degrees
%
%   [A1,...,An] = fromDegrees(toUnits,D1,...,Dn) converts the angles
%   specified by D1,...,Dn from degrees to the angle units specified
%   by toUnits. The value of toUnits can be either 'degrees' or 'radians'
%   and may be abbreviated.  The inputs D1,...,Dn and their corresponding
%   outputs are numeric arrays of various sizes, with size(Ai) matching
%   size(Di) for i = 1,...,n.
%
%   See also: deg2rad, fromRadians, toDegrees, toRadians

% Copyright 2009-2019 The MathWorks, Inc.

varargout = abstractAngleConv( ...
    'degrees', 'radians', @deg2rad, toUnits, varargin{:});
