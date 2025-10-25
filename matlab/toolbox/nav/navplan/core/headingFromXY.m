function heading = headingFromXY(inputPath)
%headingFromXY Compute heading from XY points of path
%
%   HEADING = headingFromXY(INPUTPATH) computes HEADING based on the XY
%   points of INPUTPATH. 
% 
%   INPUTPATH is a N-by-2 matrix, where the first column represents the 
%   X-coordinate and the second column represents the Y-coordinate of the  
%   path. 
% 
%   HEADING is an N-by-1 vector whose Nth element is same as the (N-1)th
%   element. HEADING angle is in radians.
%
%   Example:
%       % Create a binary occupancy map
%       rng('default')
%       map = mapClutter(5, MapSize=[20,20], MapResolution=1);
%
%       % Create plannerAStarGrid object with map
%       planner = plannerAStarGrid(map);
%       pathXY = plan(planner, [1 1], [18 18],'world');
%
%       % Compute heading from path
%       heading = headingFromXY(pathXY);
%
%       % Visualize heading angle on path
%       show(map); 
%       hold on;
%       plot(pathXY(:,1), pathXY(:,2), ".-")
%       quiver(pathXY(:,1), pathXY(:,2), cos(heading), sin(heading), 0.2)
%
% See also controllerTEB, plannerAStarGrid, mobileRobotPRM

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

% Validate number of inputs
narginchk(1, 1);

% Validation of input path to be of double and 2D array.
validateattributes(inputPath,{'double'},...
    {'nonempty', 'nonnan', 'finite', 'real', '2d', 'ncols', 2},...
    'headingFromXY', 'inputPath');

% Validation of input path height
coder.internal.errorIf(height(inputPath)<2, ...
                    'nav:navalgs:controllerteb:MinPathPointsHeading');

% Compute the first difference between the rows
delta = diff(inputPath);

% Compute the heading angle
dirT = atan2(delta(:,2), delta(:,1));

% Wrap the heading angle
dirT = robotics.internal.wrapToPi(dirT);

% Assigning direction to last pose.
heading = [dirT;dirT(end)];
end
