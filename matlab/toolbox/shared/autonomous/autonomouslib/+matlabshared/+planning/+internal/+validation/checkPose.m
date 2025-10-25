function checkPose(pose, poseDim, poseName, sourceName, varargin)
%checkPose(pose, poseDim, poseName, sourceName, varargin)

% Copyright 2017-2018 The MathWorks, Inc.


%#codegen

validateMultiplePoses = (nargin==5) && varargin{1};

if validateMultiplePoses
    validateattributes(pose, {'single', 'double'}, ...
    {'real', 'nonsparse', '2d', 'ncols', poseDim, 'finite'}, sourceName, poseName);    
else
    validateattributes(pose, {'single', 'double'}, ...
    {'real', 'nonsparse', 'row', 'numel', poseDim, 'finite'}, sourceName, poseName);
end

end