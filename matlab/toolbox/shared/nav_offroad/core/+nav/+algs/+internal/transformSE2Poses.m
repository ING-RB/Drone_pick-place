function poses = transformSE2Poses(poses, refPose)
% This class is for internal use only. It may be removed in the future.

% transformSE2Pose Transform SE(2) poses relative to reference pose(s)
% INPUTS:
%   POSES   : Pose matrix of shape [N, 3] or [M, 3, N]
%   REFPOSE : Reference pose relative to which POSES is transformed. You
%             can transform the POSES of shape [N, 3] relative a single
%             REFPOSE of shape [1,3]. You can also transform POSES of shape
%             [M, 3, N] relative to multiple REFPOSE of shape [N, 3].
%
%{
% Example 1:

  curvatures = [-0.3, 0, 0.3, -0.3, 0, 0.3];
  directions = [1, 1, 1, -1, -1, -1];
  arclength = 1.5;
  numPoints = 20;
  numMotionPrim = length(curvatures);

% Generate and plot motion primitives
  [motionPrim, motionPrimLookup] = nav.algs.internal.circularMotionPrimitives(curvatures, directions, arclength, numPoints);

% Transform all motion primitives relative a [1,2,pi/6]
  motionPrimT = nav.algs.internal.transformSE2Poses(motionPrim, [1,2,pi/6]);

% Extract and plot motion primitives
  for i = 1:numMotionPrim
  lookup = motionPrimLookup(:,i);
  motionPrimCurrent = motionPrimT(lookup(:),:);
% Plot selected motion primitive
  hold on;
  plot(motionPrimCurrent(:,1), motionPrimCurrent(:,2), plannerLineSpec.path{:});
  hold on
  plot(motionPrimCurrent(1,1), motionPrimCurrent(1,2), plannerLineSpec.start{:})
  plot(motionPrimCurrent(end,1), motionPrimCurrent(end,2), plannerLineSpec.goal{:})
  end


% Example 2:

  curvatures = [0.2, 0.3];
  directions = [1, -1];
  arclength = 2;
  numPoints = 15;
  numMotionPrim = length(curvatures);

% Generate and plot motion primitives in 3D matrix format
  [~, ~, motionPrim3D] = nav.algs.internal.circularMotionPrimitives(curvatures, directions, arclength, numPoints);

% Reference poses relative to which we want to transform
  refPoses = [1, 2, pi/10; 2.72, 2.98, pi/10];

% Transform all motion primitives relative refPoses
  motionPrim3DT = nav.algs.internal.transformSE2Poses(motionPrim3D, refPoses);

% Plot all motion primitives
  figure;
  for i = 1:numMotionPrim
  plot(motionPrim3DT(:,1,i), motionPrim3DT(:,2,i), plannerLineSpec.path{:}); hold on
  plot(motionPrim3DT(1,1,i), motionPrim3DT(1,2,i), plannerLineSpec.start{:});
  plot(motionPrim3DT(end,1,i), motionPrim3DT(end,2,i), plannerLineSpec.goal{:});
  end


%}

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    arguments
        poses (:,3,:)
        refPose (:,3)
    end

    if ismatrix(poses) && isvector(refPose)
        %   poses: [N, 3]
        %   refPoses: [1, 3]

        R = [cos(refPose(3))  sin(refPose(3));
             -sin(refPose(3)), cos(refPose(3))];
        poses(:,1:2) = poses(:,1:2)*R + refPose(1:2);
        poses(:,3) = poses(:,3) + refPose(3);

    else

        %   poses: [M, 3, N]
        %   refPoses: [N, 3]
        %   N: number of motion primitives
        %   M: number of points on each motion primitive
        theta = poses(:,3,:);
        R = robotics.internal.theta2rotm(refPose(:,3));
        poses(:,1:2,:) = pagemtimes(poses(:,1:2,:),'none',R,'transpose') + reshape(refPose(:,1:2)', 1, 2, []);
        poses(:,3,:) = reshape(refPose(:,3),1,1,[]) + theta;
    end
