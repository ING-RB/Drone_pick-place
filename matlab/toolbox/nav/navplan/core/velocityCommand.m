function velout = velocityCommand(velcmds, timestamps, timeq)
%velocityCommand Retrieve velocity from time series of velocity commands
%
%   VELOUT = velocityCommand(VELCMDS, TIMESTAMPS, TIMEQ) retrieves velocity
%   command VELOUT at a queried time instant TIMEQ from a series of  
%   velocity commands, VELCMDS, and the corresponding time stamps, 
%   TIMESTAMPS. 
% 
%   VELCMDS is a N-by-2 matrix, where the first column represents the 
%   linear velocity and the second column represents the angular velocity. 
%   TIMESTAMPS is a N-by-1 vector that represents time stamps for each row 
%   in VELCMDS. 
%
%   VELOUT is a 1-by-2 vector containing the linear and angular velocity at
%   the queried time TIMEQ.  
%
%   Example:
%       velcmds = [0, 0.5, 1.0, 1.2, 1.4, 1.5; ...
%                  0, 0.2, 0.5, 0.2,   0,   0]';
%       timestamps = [0; 0.11; 0.2; 0.32; 0.45; 0.7];
%       timeq = 0.55;
%
%       velout = velocityCommand(velcmds, timestamps, timeq);
%       disp("Send " + velout(1) + " as linear velocity and " + ...
%           velout(2) + " as angular velocity")
%
%   See also controllerTEB, plannerAStarGrid, mobileRobotPRM

%   Copyright 2022 The MathWorks, Inc.

%#codegen

% Validate number of inputs
narginchk(3, 3);

% Validate velcmds matrix input
validateattributes(velcmds, {'double'},...
    {'nonempty', 'nonnan', 'finite', 'real', '2d', 'ncols', 2}, ...
    'velocityCommand', 'velcmds')
numSamples = height(velcmds);

% Validate timestamps vector input
% Note that the timestamps must be non-negative and increasing
validateattributes(timestamps, {'double'}, ...
    {'nonempty', 'nonnan', 'finite', 'real', 'nonnegative', 'increasing', 'size', [numSamples, 1]}, ...
    'velocityCommand', 'timestamps')

% Validate timeq scalar input
validateattributes(timeq, {'double'}, {'scalar', 'real', 'nonnan', 'finite', 'nonnegative'},...
    'velocityCommand', 'timeq')

idx = find(timestamps>timeq, 1) - 1;
idxIsInvalid = (isempty(idx) || idx(1) == 0);
if idxIsInvalid
  velout = [0 0];
else
  velout = velcmds(idx, :);
end

end

