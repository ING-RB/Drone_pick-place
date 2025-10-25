function states = motionPrimitivesInterpolate(motionSegment, interpolatedDistance)
%motionPrimitivesInterpolate Sample poses at interpolatedDistance
%   Inputs
%     motionSegment is a struct with the following fields:
%       Curvature              - N-element vector of curvatures
%       Direction              - N-element vector of direction signs
%       StartState             - 1-by-3 pose [x y th]
%       MotionPrimitiveLength  - scalar motion primitive length
%       ForwardCost            - scalar forward cost
%       ReverseCost            - scalar reverse cost
%       DirectionSwitchingCost - N-element vector for direction switching
%                                costs
%     interpolatedDistance - scalar double distance in meter
%   
%   Outputs
%     states                   - Mx3xN 3D matrix. N is number of motion 
%                                primitives and M is number of samples on
%                                each motion primitives

%   Copyright 2023 The MathWorks, Inc.

%#codegen

narginchk(2,2);

curvature = motionSegment.Curvature(:);
direction = motionSegment.Direction(:);

nPrimitives = size(curvature,1);

samplesLength = interpolatedDistance:interpolatedDistance:motionSegment.MotionPrimitiveLength;

%Start plus states at lengthOnPrimitives length
nSamples = numel(samplesLength)+1;

states = nan(nSamples, 3, nPrimitives);

%Fill start for each motion primitives
states(1,:,:) = repmat(motionSegment.StartState, [1, 1, nPrimitives]);

primitiveIdx = 1:nPrimitives;
nonZeroCurvatures = curvature ~= 0;
stPrimitivesIdx = primitiveIdx(~nonZeroCurvatures);
cirPrimitivesIdx = primitiveIdx(nonZeroCurvatures);

if nnz(cirPrimitivesIdx)
%Samples for circular motion primitive
states(2:end,:,cirPrimitivesIdx) = getCircularPrimitiveData(samplesLength, ...
    curvature(cirPrimitivesIdx), motionSegment.StartState, direction(cirPrimitivesIdx));
end

if nnz(stPrimitivesIdx)
%Samples for straight motion primitive
states(2:end,:,stPrimitivesIdx) = getStraightPrimitiveData(samplesLength, motionSegment.StartState, direction(stPrimitivesIdx));
end
end

function newNodePoses = getCircularPrimitiveData(samplesLength, curvature, initialNodePose, direction)
%getCircularPrimitiveData Calculating the poses of new nodes generated of 
%   the circular motion primitives

% Compute poses for all primitives
nSample = numel(samplesLength);
turningRadius = 1 ./ curvature(:)'; % [1 x nPrim]
turningAngle = samplesLength(:)*curvature(:)'; % [nSample X nPrim];
centerX = initialNodePose(1) - turningRadius * sin(initialNodePose(3)); % [1 x nPrim]
centerY = initialNodePose(2) + turningRadius * cos(initialNodePose(3)); % [1 x nPrim]
xNew = centerX + turningRadius .* sin(initialNodePose(3) + direction(:)' .* turningAngle); % [nSample X nPrim];
yNew = centerY - turningRadius .* cos(initialNodePose(3) + direction(:)' .* turningAngle); % [nSample X nPrim];
headingNew = initialNodePose(3) + direction(:)' .* turningAngle;

% Combine and reshape such that each primitive lives on a page of the 3D matrix
stateMatrix = [xNew;yNew;headingNew]; % [nSample*3 x nPrim];
newNodePoses = reshape(stateMatrix,nSample,3,[]);
end

function newNodePose = getStraightPrimitiveData(samplesLength, initialNodePose, direction)
%getStraightPrimitiveData Calculating the pose of new node generated

% Calculating pose of the new node formed
xNew = initialNodePose(1) + (samplesLength(:)*direction(:)') .* cos(initialNodePose(3));
yNew = initialNodePose(2) + (samplesLength(:)*direction(:)') .* sin(initialNodePose(3));
headingNew = repmat(initialNodePose(3), [numel(samplesLength) numel(direction)]);

newNodePose = reshape([xNew; yNew; headingNew], numel(samplesLength), 3, []);

end
