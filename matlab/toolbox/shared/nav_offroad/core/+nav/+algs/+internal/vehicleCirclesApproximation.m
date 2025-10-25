function [centers, radius] = vehicleCirclesApproximation(dimensions, numCircles, refPosition)
% This function is for internal use only. It may be removed in the future.

% Approximate a robot using a series of equally sized circles that fully
% encompass it.
%
%
%   INPUTS:
%       DIMENSIONS  : Vector specifying the vehicle's [length, width].
%       NUMCIRCLES  : Number of circles that approximate the robot.
%       REFPOSITION : Rear edge center position of the vehicle rectangle .
%                     We assume REFPOSITION to be at vehicle origin by
%                     default.
%   OUTPUTS:
%       CENTERS    : Nx2 matrix containing the center of circles where each
%                    row represents the center of each circle
%       RADIUS     : The radius of the circles, given as a scalar.

%{
% Example

% Length and width of the vehicle
vehicleDimensions = [1, 0.5];

% Number of collision circles to approximate vehicle
numCircles = 3;

% Approximate the vehicle with collision circles
[centers, radius] = nav.algs.internal.vehicleCirclesApproximation(vehicleDimensions, numCircles);

% Visualize the collision circles on the robot
rectangle('Position', [0, -vehicleDimensions(2)/2, vehicleDimensions(1), vehicleDimensions(2)]);
hold on
% Plot collision circles
for i = 1:height(centers)
    rectangle('Position',[centers(i,1)-radius,....
        centers(i,2)-radius,...
        2*radius, 2*radius],...
        'Curvature',[1,1], 'EdgeColor','r', 'LineWidth',2);
    hold on
    scatter(centers(i,1), centers(i,2), 'filled', 'o', MarkerFaceColor='r')
end
h = scatter(0,0,'filled', DisplayName='Vehicle Origin');
axis equal
legend(h)

%}


% Copyright 2024 The MathWorks, Inc.

%#codegen

arguments
    dimensions (1,2) double {mustBeNonnegative}
    numCircles (1,1) double {mustBeInteger, mustBePositive} = 3
    refPosition (1,2) double = [0,0]
end

if all(dimensions)
    robotLength = dimensions(1);
    robotWidth = dimensions(2);
    centerPlacements = (0.5/numCircles) : (1/numCircles) : 1;
    centerPlacements = centerPlacements * robotLength;
    radius = hypot(robotLength/(2*numCircles), robotWidth/2 );
else
    centerPlacements = 0;
    radius = 0;
end

centers = [centerPlacements(:), zeros(length(centerPlacements),1)];