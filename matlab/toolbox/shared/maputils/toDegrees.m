function varargout = toDegrees(fromUnits, varargin)
%toDegrees Convert angles to degrees
%
%   [D1,...,Dn] = toDegrees(fromUnits,A1,...,An) converts the angles
%   specified by A1,...,An to degrees from the angle units specified by
%   fromUnits. The value of fromUnits can be either 'degrees' or 'radians'
%   and may be abbreviated. The inputs A1,...,An and their corresponding
%   outputs are numeric arrays of various sizes, with size(Di) matching
%   size(Ai) for i = 1,...,n.
%
%   See also: fromDegrees, fromRadians, rad2deg, toRadians

% Copyright 2009-2019 The MathWorks, Inc.

varargout = abstractAngleConv( ...
    'degrees', 'radians', @rad2deg, fromUnits, varargin{:});
