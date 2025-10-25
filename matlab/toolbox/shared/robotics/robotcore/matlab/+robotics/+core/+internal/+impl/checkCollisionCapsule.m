function [collisionFound, distance, witnessPoints] = checkCollisionCapsule(p1, v1, D1, R1, p2, v2, D2, R2, exhaustive)
% This function is for internal use only. It may be removed in the future.

%checkCollisionCapsule Calculates the distance between line segments
%
%   COLLISIONFOUND = checkCollisionCapsule(P1,V1,D1,R1,P2,V2,D2,R2,EXHAUSTIVE=false) performs
%   a pair-wise comparison of capsules in Set1 against capsules in Set2. If
%   the number of capsules in Set2 (e.g M) is an integer multiple of the number of
%   capsules in Set1 (e.g. N), then Set1 is compared against M/N horizontally
%   concatenated set of capsules in Set2. COLLISIONFOUND is returned as an
%   N-by-(M/N) matrix of logicals, where the [i,j]-th element represents
%   the comparison of the ith capsule in Set1 against the paired capsule
%   in the jth concatenated set of capsules in Set2.
%
%       [A1 A2 .. AN] |^| [[B11 B12 .. B1N] [B21 B22 .. B2N] ... [...]]
%
%                           -> [A1_B11 A1_B21     A1_BM1
%                               A2_B12 A2_B22     A2_BM2
%                                   ...
%                               AN_B1N AN_B2N ... AN_BMN]
%
%       An individual capsule is defined by a set of parameters:
%           P   - An xy or xyz point corresponding to the start of the capsule's axis
%           V   - An xy or xyz unit vector describing the direction of the capsule's axis
%           D   - The length of the line segment at the core of the capsule
%           R   - The capsule's radius
%
%                           ,.-+-------------------+-.,
%                          /       V                   \
%                Z  Y     (    P===>- - - - - - - -+    )
%                | /       \                        \R /
%                |/_ _X     `*-+-------------------+-*`
%                              |---------D---------|
%
%       For a set of capsules, P and V are DIM-by-NumCapsule matrices, where
%       DIM is either 2 or 3 depending on whether the capsule is 2D (xy) or
%       3D (xyz). D and R can either be scalar, or NumCapsule-element vectors.
%
%   COLLISIONFOUND = checkCollisionCapsule(P1,V1,D1,R1,P2,V2,D2,R2,EXHAUSTIVE=true)
%   takes an optional logical flag, EXHAUSTIVE. If this is set to true,
%   then each capsule in Set1 is compared against ALL capsules in Set2. The
%   size of COLLISIONFOUND will be N-by-M, where the [i,j]-th element
%   represents the comparison of SetA's ith capsule with SetB's jth
%   capsule.
%
%           [A1 A2 .. AN] |^| [B1 B2 .. BN]
%
%                           -> [A1_B1 A1_B2     A1_BM
%                               A2_B1 A2_B2     A2_BM
%                                   ...
%                               AN_B1 AN_B2 ... AN_BM]
%
%   [___, DISTANCE] = checkCollisionCapsule(P1,V1,D1,R1,P2,V2,D2,R2,EXHAUSTIVE)
%   returns the distance between pairs of capsules in SetA and SetB. If a
%   pair of capsules are not in collision, then DISTANCE will contain the
%   distance between the nearest points on the capsules' boundary. If two
%   capsules are intersecting, the corresponding element of DISTANCE will
%   contain NaN.
%
%   [___, WITNESSPOINTS] = checkCollisionCapsule(P1,V1,D1,R1,P2,V2,D2,R2,EXHAUSTIVE)
%   returns the closest points, WITNESSPOINTS, between each pair of
%   compared capsules in SetA and SetB.
%   If each set only contains 1 capsule, then the result will be a DIM-by-2
%   matrix. If the number of capsules in either set is greater than 1, then
%   the output will be of size [NSetA OUTHEIGHT DIM 2], where OUTHEIGHT is
%   NSetB when EXHAUSTIVE=true and NSetB/NSetA otherwise. For any pair of
%   colliding capsules, the WITNESSPOINTS will contain NaN.
%
%   References:
%
%       [1] Distance calculation based on http://geomalgorithms.com/a07-_distance.html

%   Copyright 2020-2024 The MathWorks, Inc.

%#codegen

    narginchk(9,9)

    numSeg1 = size(p1,2);
    numSeg2 = size(p2,2);
    dim = size(p1,1);

    if numSeg1 == 0
        collisionFound = false(0,1);
        distance = [];
        witnessPoints = [];
        return;
    end

    if numSeg2 == 0
        collisionFound = false(numSeg1,1);
        if nargout == 2
            distance = inf(numSeg1,1);
            witnessPoints = nan(3,2);
        else
            distance = [];
            witnessPoints = [];
        end
        return;
    end

    if exhaustive
        % The first set of line-segments will be checked exhaustively
        % against the second set

        % Calculate values needed to vectorize operations
        numChecks = numSeg1*numSeg2;

        % Replicate vectors
        v = repmat(v1.*repelem(D1,dim,1),1,numSeg2);
        u = repelem(v2.*repelem(D2,dim,1),1,numSeg1);

        % Calculate distance between beginning of line-segment pairs
        P1 = repmat(p1,1,numSeg2);
        P2 = repelem(p2,1,numSeg1);
        w0 = P2-P1; % Vector from lineSeg1-base to lineSeg2-base

        % Calculate distance thresholds for each pair of radii
        RR1 = repmat(R1(:)',1,numChecks/numel(R1));
        RR2 = repelem(R2(:)',1,numChecks/numel(R2));
        combinedRSquared = (RR1 + RR2).^2;

        % Calculate height dimension of output
        outputHeight = numSeg1;
    else
        % Each line-segment in xy1's ith column will be checked against
        % the set of line segments in xy2, corresponding to columns
        % i:size(xy1,2):end

        % Calculate the number of times set1 must be checked against set2
        numObj = numSeg2/numSeg1;
        validateattributes(numObj,{'numeric'},{'integer','positive'},'collisionCheckCapsuleVectorized','LineSegRatio');
        outputHeight = size(p1,2);

        % Replicate vectors
        v = repmat(v1.*D1,1,numObj);
        u = v2.*repelem(D2,dim,1);

        % Calculate distance between beginning of line-segment pairs
        P1 = repmat(p1,1,numObj);
        P2 = p2;
        w0 = p2-P1;

        % Calculate distance thresholds for each pair of radii
        RR1 = repmat(R1(:)',1,numObj*numSeg1/numel(R1));
        RR2 = R2;
        combinedRSquared = (RR1+R2).^2;

        numChecks = size(p1,2)*numObj;
    end

    % Find parametric values for nearest points on each line segment
    [tClosest, sClosest] = findNearestPoints(v, u, w0);

    % Calculate closest distance between pairs of line segments
    squareDist = sum((w0 + repmat(sClosest,dim,1).*u - repmat(tClosest,dim,1).*v).^2);

    % If distance is below the bounding radii of the two capsules, a
    % collision has occurred
    collisionFound = reshape(squareDist(:) <= combinedRSquared(:), outputHeight, []);

    if nargout >= 2
        % Calculate distance
        distance = reshape(sqrt(max(squareDist(:),0))-sqrt(combinedRSquared(:)), outputHeight, []);
        distance(distance<0) = nan;
    end

    if nargout == 3
        if coder.internal.isConstTrue(isscalar(distance))
            if isnan(distance)
                witnessPoints = nan(3,2);
            else
                % Calculate boundary point on both capsules
                witnessPoints = calculateWitnessPoints(p1,v,R1,tClosest,p2,u,R2,sClosest,distance);
            end
        else
            pts = nan(numChecks,1,dim,2);
            for i = 1:numChecks
                if ~isnan(distance)
                    pts(i,1,:,:) = calculateWitnessPoints(P1(:,i),v(:,i),RR1(i),...
                                                          tClosest(i),P2(:,i),u(:,i),RR2(i),sClosest(i),distance(i));
                end
            end
            witnessPoints = reshape(pts,outputHeight,[],dim,2);
        end
    end
end

function pts = calculateWitnessPoints(p1,vd1,r1,tClosest,p2,vd2,r2,sClosest,dist)
% Evaluate both line-segments with parametric length
    pA = p1 + vd1*tClosest;
    pB = p2 + vd2*sClosest;

    % Calculate unit distance vector
    vWitness = pB-pA;
    vWitness = vWitness/(dist+r1+r2);
    pts = [pA + vWitness*r1, pB - vWitness*r2];
end

function [tN, sN] = findNearestPoints(v,u,w0)
%findNearestPoints Find the nearest points between two sets of line-segments
%
%   Takes in a set of DIM-by-N matrices (v, u, w0), wherein the i'th
%   columns represent two sets of parametetric line segments:
%
%       Segment 1: P(T) = p0 + v*T
%       Segment 2: Q(S) = q0 + u*S
%
%   where:
%       v = vHat*D1
%       u = uHat*D2
%       w0 = dot(v,q0-p0)
%       T = tN/tD
%       S = sN/sD
%
%   tN and sN are constrained to be within [0, tD], [0, sD], respectively,
%   resulting in T, S limited to [0,1]

% Calculate parametric variables for P/Q
    a = sum(u.*u);  % D2^2
    b = sum(v.*u);  % Unnormalized dot product between v1*D1, v2*D2
    c = sum(v.*v);  % D1^2
    d = sum(u.*w0); % Projective distance of (q0-p0) onto u
    e = sum(v.*w0); % Projective distance of (q0-p0) onto v

    % Calculate numerator & denominator for the parameters of the line-segments
    numChecks  = numel(a);
    denom      = a.*c - b.*b;
    tN = a.*e-b.*d;
    sN = b.*e-c.*d;

    % Precalc our floating-point check rather than repeatedly calculate
    sqrtEps = sqrt(eps);

    for i = 1:numChecks
        % Constrain parameter S to limits of segment Q, then recalculate T
        sD = denom(i);
        if sD < sqrtEps
            % Degenerate case where lines are co-linear or parallel
            sN(i) = 0;      % Snap S arbitrarily to the base point q0
            sD = 1;         % Set length to 1
            tN(i) = e(i);   % tN becomes dot(v1*D1, q0-p0)
            tD = c(i);      % tD becomes D1^2
        elseif sN(i) < 0
            sN(i) = 0;
            tN(i) = e(i);
            tD = c(i);
        elseif sN(i) > sD
            sN(i) = sD;
            tN(i) = e(i)+b(i);
            tD = c(i);
        else
            tD = denom(i);
        end

        % Constrain parameter T to limits of segment P while minimizing
        % the distance between P, Q
        if tN(i) < 0
            % Snap T to p0 if q0 projection lies in opposite direction of v
            tN(i) = 0;
            if -d(i) < 0
                % If p0's projection on u points away from u, then sN
                % stays constrained to q0
                sN(i) = 0;
            elseif -d(i) > a(i)
                % If projection of p0 onto u lies outside Q, then snap to
                % the far end of the segment.
                sN(i) = sD;
            else
                % If within the segment bounds:
                sN(i) = -d(i); % S becomes projection of p0 on u
                sD = a(i); % Updated S-denom is D2^2
            end
        elseif tN(i) >= tD
            % Snap T to end point if p2 projection on v lies beyond end of
            % seg 2
            tN(i) = tD;
            if (-d(i) + b(i)) < 0
                % If updated point on v, projected on u, lies before seg 2
                % base, snap S to base.
                sN(i) = 0;
            elseif (-d(i) + b(i) > a(i))
                % If constrained projection of T lies past seg 2, snap S to
                % end
                sN(i) = sD;
            else
                % Otherwise, S is located at the projection of T on u
                sN(i) = -d(i) + b(i);
                sD = a(i);
            end
        end

        % Recalculate parameters using updated numerator and denominator
        if denom(i) < sqrtEps && tN(i) > 0 && tN(i) < tD
            % Degenerate case where parallel segments partially or wholly
            % overlap. We need to find the overlap region, then set T, S
            % to the center of this overlap.

            % Store current T parameter, this will be first of the overlap
            % bounds.
            tN1 = tN(i);

            % Find projection of Q's endpoint in T by adding projected
            % length of Q (D2) to the current tN1
            %   tN2 = tN1+d2ScaledInT*signOfD2InT
            %   d2InT*signOfD2InT <=> (v1*D1)*(v2*D2) == b
            tN2 = tN1+b(i);

            % Constrain new point to limits of P
            tN2 = min(max(tN2,0),tD);

            % Calculate midpoint
            tN(i) = (tN1+tN2)/2;

            % Convert change in T to change in S
            %   Parametric equation of line
            %       P(T) = p0 + v*T, where T = tN/tD^2, v = vHat*D1;
            %
            %   Translation along P due to change in T
            %       P(T2)-P(T1) = v*(T2-T1)
            %
            %   Let Q be a separate line-segment
            %       Q(S2)-Q(S1) = u*(S2-S1)
            %
            %   Translation along parallel lines is equivalent, set them equal
            %       dX = u*DEL_S = v*DEL_T
            %
            %   Multiply both sides by v
            %       v*u*DEL_S = v*v*DEL_T
            %
            %   From earlier:
            %           b = v*u
            %           c = v*v
            %           tD = c
            %   Therefore:
            %       ==> DEL_S = c/b*DEL_T = c/b*(tC2-tC1)/tD => (tC2-tC1)/b

            % Calculate length of Q projected onto v
            tShift = tN(i)-tN1;

            % Transform change in T to change in S
            sShift = tShift/b(i);
            sN(i) = sN(i)+sShift;

            % Limit S to range
            sN(i) = min(max(sN(i),0),sD);

            % Normalize T to range [0, 1]
            tN(i) = tN(i)/tD;
        else
            % Non-degenerate case, points will always have a unique
            % minimum, all that needs to be done is floating-point cleanup
            % and scaling to [0 1].
            if sN(i) < sqrtEps
                sN(i) = 0;
            else
                sN(i) = sN(i)/sD;
            end
            if tN(i) < sqrtEps
                tN(i) = 0;
            else
                tN(i) = tN(i)/tD;
            end
        end
    end
end
