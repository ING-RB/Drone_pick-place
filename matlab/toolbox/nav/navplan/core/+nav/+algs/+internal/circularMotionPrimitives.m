function [motionPrim, motionPrimLookup, motionPrim3D] = circularMotionPrimitives(curvature, direction, arclength, samples, distsamples)
% This class is for internal use only. It may be removed in the future.

% circularMotionPrimitives Generate motion primitives relative to origin
%
%   Inputs:
%       CURVATURE :  Row vector containing the curvatures for the motion
%                    primitives. For straight paths the curvatures are
%                    equal zero. Length of the vector is equal to
%                    the number of motion primitives to be computed.
%       DIRECTION :  Row vector containing the direction for the motion
%                    primitives. +1 means forward, -1 means reverse.
%                    Length of the vector is equal to the number of
%                    motion primitives to be computed.
%       ARCLENGTH :  Arc length of each motion primitive
%         SAMPLES :  Number of equidistant samples on each motion
%                    primitive, or, vector of distance samples (can be
%                    non-equidistant) along the length of the motion
%                    primitive.
%      DISTSAMPLES:  Boolean indicating whether the SAMPLES is a vector
%                    representing distance samples. Default is false.
%
%   Outputs:
%       MOTIONPRIM:  2D matrix of shape [numPoints*numMotionPrim,3].
%                    The first dimension refers to a pose on the motion
%                    primitive. The second dimension refers to the
%                    vehicle pose [x,y,yaw]. This format gives faster
%                    performance when you want to transform many motion
%                    primitives poses relative a single pose.
% MOTIONPRIMLOOKUP:  Lookup indices to extract a particular motion
%                    primitive from the MOTIONPRIM matrix.
%     MOTIONPRIM3D:  3D matrix representation of MOTIONPRIM of shape
%                    [numPoints,3,numMotionPrim]. This format gives good
%                    performance when you want to transform each motion
%                    primitive relative to multiple different reference
%                    poses.
%
%{
% Example 1:

  curvatures = [-0.1, 0, 0.1, -0.1, 0, 0.1];
  directions = [1, 1, 1, -1, -1, -1];
  arclength = 1.5;
  numPoints = 20;
  numMotionPrim = length(curvatures);
% Generate and plot motion primitives
  [motionPrim, motionPrimLookup] = nav.algs.internal.circularMotionPrimitives(curvatures, directions, arclength, numPoints);
% Extract and plot motion primitives
  for i = 1:numMotionPrim
  lookup = motionPrimLookup(:,i);
  motionPrimCurrent = motionPrim(lookup(:),:);
% Plot selected motion primitive
  hold on;
  plot(motionPrimCurrent(:,1), motionPrimCurrent(:,2), plannerLineSpec.path{:});
  hold on
  plot(motionPrimCurrent(1,1), motionPrimCurrent(1,2), plannerLineSpec.start{:})
  plot(motionPrimCurrent(end,1), motionPrimCurrent(end,2), plannerLineSpec.goal{:})
  end

% Example 2:
  curvatures = [-0.2, -0.1, 0, 0.1, 0.2, -0.2, -0.1, 0, 0.1, 0.2];
  directions = [1, 1, 1, 1, 1, -1, -1, -1, -1, -1];
  arclength = 2;
  numPoints = 15;
  numMotionPrim = length(curvatures);
% Generate and plot motion primitives in 3D matrix format
  [~, ~, motionPrim3D] = nav.algs.internal.circularMotionPrimitives(curvatures, directions, arclength, numPoints);
% Plot all motion primitives
  figure;
  for i = 1:numMotionPrim
  plot(motionPrim3D(:,1,i), motionPrim3D(:,2,i), plannerLineSpec.path{:}); hold on
  plot(motionPrim3D(1,1,i), motionPrim3D(1,2,i), plannerLineSpec.start{:});
  plot(motionPrim3D(end,1,i), motionPrim3D(end,2,i), plannerLineSpec.goal{:});
  end

% Example 3:
  curvatures = 0.1;
  directions = 1;
  arclength = 2;
  samples = [0.3, 0.7, 1.1, 1.8];
  numMotionPrim = length(curvatures);
% Generate and plot motion primitives in 3D matrix format
  [~, ~, motionPrim3D] = nav.algs.internal.circularMotionPrimitives(curvatures, directions, arclength, 10);
  [~, ~, motionPrimSamples] = nav.algs.internal.circularMotionPrimitives(curvatures, directions, arclength, samples);
% Plot all motion primitives
  figure;
  plot(motionPrim3D(:,1,i), motionPrim3D(:,2,i), plannerLineSpec.path{:}); hold on
  plot(motionPrimSamples(:,1), motionPrimSamples(:,2), plannerLineSpec.state{:})
  plot(motionPrim3D(1,1,i), motionPrim3D(1,2,i), plannerLineSpec.start{:});
  plot(motionPrim3D(end,1,i), motionPrim3D(end,2,i), plannerLineSpec.goal{:});

%}

%   Copyright 2023 The MathWorks, Inc.

%#codegen

arguments
    curvature(1,:)
    direction(1,:)
    arclength(1,1)
    samples(1,:)
    distsamples (1,1) logical = false
end

numMotionPrim = numel(curvature);

% Samples along the motion primitives
if ~distsamples
    numSamples = samples(1);
    ratios =  linspace(0, 1, numSamples)';
else
    numSamples = length(samples);
    ratios = samples(:)/arclength;
end

% Turning radius
% For straight lines the turningRadius=inf
turningRadius = 1 ./ curvature;

% Turning angle
turningAngle = arclength * curvature;
yaw = direction .* turningAngle; % with directions

% Compute poses (x,y,yaw) for circular motion primitives
yaw = ratios * yaw;
x = turningRadius .* sin(yaw);
y = turningRadius .* (1 - cos(yaw));

% Compute x, y positions for straight motion primitives
straightLine = curvature==0;
if any(straightLine)
    x(:, straightLine) = ratios*direction(straightLine)*arclength;
    y(:, straightLine) = 0;
end

% Output motion primitives of shape [numPoints*numMotionPrim, 3]
motionPrim = [x(:), y(:), yaw(:)];

% Output lookup for
if nargout>1
    motionPrimLookup = 1:int16(numSamples*numMotionPrim);
    motionPrimLookup = reshape(motionPrimLookup, numSamples, numMotionPrim);
end

% Output motion primitives as a 3D matrix
if nargout>2
    motionPrim3D = reshape(motionPrim, [numSamples, numMotionPrim, 3]);
    motionPrim3D = permute(motionPrim3D, [1,3,2]);
end
