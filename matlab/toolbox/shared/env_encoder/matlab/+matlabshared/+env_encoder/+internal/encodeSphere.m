function [encoding, nearestPoint] = encodeSphere(basisPoints, spheres)
% This function is for internal use only. It may be removed in the future.

% encodeSphere encodes spheres represented as a 4-by-n matrix using
% basis point set encoding. Each column represents the information about
% each sphere in the form of [r;x;y;z]. Here r is the radius of the sphere and
% x,y,z is the coordinates of the center of the sphere.
% The matrix basisPoints is an n-by-3 matrix representing the
% location of basis points. Each row in basisPoints represents the x,y,z
% coordinates of a basis point.

%   Copyright 2023-2024 The MathWorks, Inc.

%#codegen

    % When the spheres is empty, return encoding as inf and
    % nearest point as NaN.
    if isempty(spheres)
        encoding = inf(height(basisPoints),1);
        nearestPoint = nan(height(basisPoints),3);
        return;
    end

    numSpheres = size(spheres,2);
    numBasis = size(basisPoints,1);

    sphereCenters = spheres(2:4,:)';
    sphereRadius = spheres(1,:)';

    % Find the distance to the center of each sphere from all the basis points
    % distToSpheresCenter is a matrix with each column containing the distance
    % from a single basis point to all the sphere centers.
    diffToSpheresCenter = sphereCenters - permute(basisPoints,[3 2 1]);
    distToSpheresCenter = reshape(vecnorm(diffToSpheresCenter,2,2),numSpheres,numBasis);

    % Create a matrix containing sphere radius repeated across row
    radMat = repmat(sphereRadius, 1, numBasis);

    % Calculate the distance to the surface from each basis points to all the
    % spheres. distToSurface is a matrix with each column containing the
    % distance from all the basis points to the surface of the sphere.
    distToSurface = distToSpheresCenter - radMat;

    % When the same basis point is inside two spheres (Spheres are not separated)
    % the distance to the surface of the sphere which lies closest to the basis point
    % is returned.
    [~, index] = min(abs(distToSurface), [], 1, "linear");
    encoding = distToSurface(index)';
    [idxCorrespondsSphere,~] = ind2sub(size(distToSurface), index);
    idxCorrespondsSphere = idxCorrespondsSphere';

    % Nearest point to the basis point lies on the surface of the sphere.
    % This point is at a distance of radius away from the center of the sphere
    % in the line joining the center of the sphere with the basis point.
    diffVec = basisPoints - sphereCenters(idxCorrespondsSphere,:);
    distToCenter = vecnorm(diffVec,2,2);
    % When the basis point is on the center of the sphere, all the points
    % on the surface are equidistant and there are infinite many nearest
    % point possible. In this special case return a single point that intersect
    % the x axis and sphere surface.
    if ~all(distToCenter)
        bpOnCenterIdx = distToCenter==0;
        distToCenter(bpOnCenterIdx) = 1;
        diffVec(bpOnCenterIdx,:) = [1 0 0];
    end

    unitVec = diffVec./distToCenter;
    radiusOfClosestSphere = sphereRadius(idxCorrespondsSphere);
    nearestPoint = sphereCenters(idxCorrespondsSphere,:) + radiusOfClosestSphere.*unitVec;
end
