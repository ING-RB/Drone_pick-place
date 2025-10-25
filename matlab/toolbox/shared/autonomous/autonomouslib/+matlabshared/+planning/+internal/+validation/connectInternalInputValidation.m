function pathSegments = connectInternalInputValidation(...
    startPose, goalPose, varargin)
%This function is for internal use only. It may be removed in the future.

%connectInternalInputValidation
%   Utility function to validate connectInternal inputs. This code has been
%   used by the matlabshared.planning.internal.DubinsConnection &
%   matlabshared.planning.internal.ReedsSheppConnection.

% Copyright 2018 The MathWorks, Inc.

%#codegen

nStartPoses = size(startPose, 1);
nGoalPoses = size(goalPose, 1);

% Validation of the size of start & goal
coder.internal.errorIf((nStartPoses > 1 && nGoalPoses > 1 && nStartPoses ~= nGoalPoses), ...
    'shared_autonomous:motionModel:InvalidSizeStartAndGoal');

validateattributes(startPose, {'single', 'double'}, ...
    {'real', 'ncols', 3, 'finite'}, 'connect', 'startPose');

validateattributes(goalPose, {'single', 'double'}, ...
    {'real', 'ncols', 3, 'finite'}, 'connect', 'goalPose');

% Define names and default values for name-value pairs
names = {'PathSegments'};
defaultValues = {'optimal'};

% Parse name-value pairs
parser = matlabshared.autonomous.core.internal.NameValueParser(names, defaultValues);
parse(parser, varargin{:});

segs = parameterValue(parser, 'PathSegments');
validatestring(segs, {'optimal' 'all'}, 'connect', 'PathSegments');
pathSegments = lower(convertStringsToChars(segs));

end