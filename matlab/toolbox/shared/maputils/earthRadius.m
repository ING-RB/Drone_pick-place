function r = earthRadius(unitOfLength)
%Mean radius of planet Earth
%
%   R = earthRadius returns the scalar value 6371000, the mean radius
%   of the Earth in meters.
%
%   R = earthRadius(LENGTHUNIT) returns the mean radius of the Earth using
%   the specified unit of length.  LENGTHUNIT is any string accepted by the
%   validateLengthUnit function.
%
%   Examples
%   --------
%   earthRadius             % Returns 6371000
%   earthRadius('meters')   % Returns 6371000
%   earthRadius('km')       % Returns 6371
%
%   See also UNITSRATIO, validateLengthUnit.

% Copyright 2009-2011 The MathWorks, Inc.

r = 6371000;
if nargin > 0
    r = r * unitsratio(unitOfLength, 'meter');
end
