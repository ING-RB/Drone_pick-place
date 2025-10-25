classdef PolynomialTrajectoryOrientation < handle
% This file is for internal use only.
% It may be removed in a future release.

%PolynomialTrajectoryOrientation Calculate orientation from
%polynomial trajectory
%   Stores the roots of the polynomial and calculates the continuous orientation
%   from the trajectory.

%   Copyright 2023 The MathWorks, Inc.

%#codegen
    properties(Access = private)
        %Roots of the piecewise polynomial
        Roots

        %Trajectory piecewise polynomial
        PosPP

        %Velocity piecewise polynomial
        VelPP

        %Acceleration piecewise polynomial
        AccelPP

        %Jerk piecewise polynomial
        JerkPP

        %Start and end of root clusters in pairs
        ClusterRoots

        %Time to use to evaluate orientation for roots within each cluster
        ClusterTimesToUse

        %Flag for whether the last cluster includes the last break
        LastClusterIncludesBreak

        %Offset value for when last break is in a cluster or is a velocity
        %zero
        TimeOffsetForLastBreak = 1e-4

        %Time threshold between roots to be included in cluster
        RangeBetweenRootsOfCluster = 1e-3
    end

    methods
        function obj = PolynomialTrajectoryOrientation(pp)
        %PolynomialTrajectoryOrientation


            obj.VelPP = obj.derivpp(pp);
            obj.AccelPP = obj.derivpp(obj.VelPP);
            obj.JerkPP = obj.derivpp(obj.AccelPP);
            obj.PosPP = pp;
            obj.Roots = obj.getVelocityRoots(obj.VelPP);

            breaks = unmkpp(obj.PosPP);

            %Find cluster of roots and the time to evaluate for each
            %cluster
            [obj.ClusterRoots, obj.ClusterTimesToUse, obj.LastClusterIncludesBreak] = ...
                obj.getClusterRoots(breaks);
        end

        function [orientation, angularVelocity] = getOrientationFromPolynomial( ...
            obj, tPts, autoPitch, autoRoll, gravity)
        %getOrientationFromPolynomial Calculate orientation from polynomial
        %trajectory
        % Uses higher order derivatives to calculate the orientation

        %  tPts    - Time points at which to calculate the orientation
        %
        %  autoBank   - pitch and roll compensate for gravity when true
        %  autoPitch  - lock pitch to direction of motion when true, regardless
        %               of autobank setting
        %  gravity    - local gravity at each point -ve for ENU, +ve for NED

        %#codegen
        % To construct the rotation matrix, we compute row vectors:
        %  R = [u' v' w'].
        %
        %  u, v, and w obey a right-handed coordinate system (u x v = w):
        %    (w = u x v, u = v x w, v = w x u).
        %
        %  For ENU: u, v, and w correspond to "forward" "left" and "up"
        %  For NED: u, v, and w correspond to "forward" "right" and "down"
        %
        %  when R = eye(3), then object is aligned with its coordinate system.

            acceleration = ones(numel(tPts), 3);
            acceleration(1:numel(tPts), :) = pagetranspose(ppval(obj.AccelPP, tPts));

            jerk = ones(numel(tPts), 3);
            jerk(1:numel(tPts), :) = pagetranspose(ppval(obj.JerkPP, tPts));

            alignment = ones(numel(tPts),1);

            if autoPitch
                % align unit tangent vector with 3-D velocity
                [uVector, duVector] = obj.unitdPP(tPts, true);


                if autoRoll
                    [vVector, dvVector, wVector, dwVector] = ...
                        fusion.scenario.internal.OrientationCalculationUtils.fixedWing(acceleration, jerk, uVector, duVector, gravity);
                else
                    [vVector, dvVector, wVector, dwVector] = ...
                        fusion.scenario.internal.OrientationCalculationUtils.groundVehicle(uVector, duVector);
                end
            else
                % set tangent vector to horizontal plane.
                [uVector, duVector] = obj.unitdPP(tPts, false);

                if autoRoll
                    [uVector, duVector, vVector, dvVector, wVector, dwVector] = ...
                        fusion.scenario.internal.OrientationCalculationUtils.rotaryWing(acceleration, jerk, uVector, duVector, alignment, gravity);
                else
                    [uVector, duVector, vVector, dvVector, wVector, dwVector] = ...
                        fusion.scenario.internal.OrientationCalculationUtils.marineVehicle(uVector, duVector, alignment);
                end
            end

            [orientation, angularVelocity] = fusion.scenario.internal.OrientationCalculationUtils.getOrientationAndAngularVelocity(uVector, vVector, wVector, ...
                                                                                                                                   duVector, dvVector, dwVector);
        end

        function [uOut, duOut] = unitdPP(obj, tpts, zFlag)
        %unitdPP Calculate the unit vector from the first non-zero
        %derivative
        %Use L'Hospital theorem to calculate unit vector when velocity is
        %zero. This also makes use of the clustered roots approach to
        %remove any discontinuities in the calculated orientation.
        % compute unit vector and its derivative from polynomial

            uOut = nan(numel(tpts), 3);
            duOut = nan(numel(tpts), 3);
            flagToFlip=true;
            %If velocity is 0 at a point and acceleration is ~0, that means the
            %orientation has flipped at this point
            %If the acceleration is 0 and jerk is ~0, there is a change in sign of
            %acceleration at this point and so it is a saddle point for the
            %velocity. So there is no sign change for the orientation.
            [breaks,~,~, order] = unmkpp(obj.PosPP);

            clusterRoots = obj.ClusterRoots ;
            clusterTimesToUse = obj.ClusterTimesToUse;
            lastClusterIncludesBreak = obj.LastClusterIncludesBreak;


            pp1 = obj.VelPP;
            for i=1:order-1
                flagToFlip=~flagToFlip;
                pp2 = obj.derivpp(pp1);
                [u, du] = obj.calcUdU(pp1, pp2, tpts, zFlag);

                %Indices of valid u and du values to use as output
                idxToReplace = any(isnan(uOut), 2) & ~any(isnan(u), 2);
                if any(idxToReplace)
                    uToReplace = u(idxToReplace, :);
                    duToReplace = du(idxToReplace, :);

                    %Find the clusters that the timepoints belong to
                    t = tpts(idxToReplace);
                    [x, y] = meshgrid(clusterRoots, t);
                    %Take the difference between each root and each timepoint. Take
                    %the signum of this difference. Then take the 1st order diff
                    %between the columns of the grid
                    diffSignMatrix = diff(sign(x-y), 1, 2);
                    %The non zero values in the odd columns of this diff tell us
                    %which time points are in clusters
                    diffSignMatrix = diffSignMatrix(:, 1:2:size(diffSignMatrix, 2));

                    %Logical index of the timepoints that are in clusters
                    tInClusterLogicalIdx = any(diffSignMatrix, 2);

                    if any(tInClusterLogicalIdx)
                        nTPtsInCluster = nnz(tInClusterLogicalIdx);
                        idxToFlip = false(nTPtsInCluster, 1);
                        tClusterIdx = nan(1, nTPtsInCluster);
                        diffSignVector = diffSignMatrix(tInClusterLogicalIdx,:);
                        %Loop through the timepoints to get the index of the
                        %cluster that each belongs to
                        for m = 1:nTPtsInCluster
                            clusterIdx = find(diffSignVector(m,:));
                            tClusterIdx(m) = clusterIdx(1);
                            %If the cluster that the timepoint belongs to is the
                            %last cluster AND an even derivative is currently being
                            %used AND the last cluster contains the last break
                            %point, then flip the sign of the unit vector
                            if clusterIdx(1) == numel(clusterTimesToUse) && flagToFlip && lastClusterIncludesBreak
                                idxToFlip(m) = true;
                            end
                        end

                        [u, du] = obj.calcUdU(pp1, pp2, clusterTimesToUse(tClusterIdx), zFlag);

                        %Flip the sign of the last unit vector
                        if any(idxToFlip)
                            u(idxToFlip, :) = u(idxToFlip, :).*-1;
                            du(idxToFlip, :) = du(idxToFlip, :).*-1;
                        end

                        uToReplace(tInClusterLogicalIdx, :) = u;
                        duToReplace(tInClusterLogicalIdx, :) = du;
                    end

                    %if the last break is not in a cluster but it is a velocity zero
                    if any(t == breaks(end)) && i > 1 && ~lastClusterIncludesBreak
                        idxLastBreak = find(t==breaks(end));
                        [u, du] = obj.calcUdU(pp1, pp2, t(idxLastBreak)-obj.TimeOffsetForLastBreak, zFlag);
                        if flagToFlip
                            u = u.*-1;
                            du = du.*-1;
                        end
                        uToReplace(idxLastBreak, :) = u;
                        duToReplace(idxLastBreak, :) = du;
                    end
                    uOut(idxToReplace, :) = uToReplace;
                    duOut(idxToReplace, :) = duToReplace;
                end

                if any(any(isnan(uOut), 2))
                    pp1 = pp2;
                    continue;
                else
                    break
                end
            end
        end

        function [clusterRoots, clusterTimesToUse, lastClusterIncludesBreak] = getClusterRoots(obj, breaks)
        %getClusterRoots Find cluster of roots
        %Cluster of roots is defined as roots that are within 1e-3 of each
        %other. If a set of consecutive roots satisfy this above criteria,
        %the entire set is considered a cluster. A cluster of roots means that
        %the velocity changes direction between these roots. In such cases,
        %if the user tries to evaluate the orientation inside a cluster,
        %the orientation at the last root of the cluster is returned to
        %avoid any sudden changes in orientation. Clustered roots can be
        %seen when using polynomials generated from methods like
        %minjerkpolytraj and minsnappolytraj.
        % If the last break point is part of a cluster or if it is a root
        % of the velocity, then a value 1e-4 before the first root of that
        % cluster or before the last break is used to fetch the orientation.
        %For example: Consider the velocity roots [1 1.00001 1.99995 2 3] and
        %the breaks [1 2 3]. If the user evaluates at
        % t=[1.000005 1.99996 3], then the orientation will be returned at
        % these values [1.00001 2 2.9999]

        %Calculate diff to find roots within 1e-3 of each other

            vRootsList = obj.Roots;
            clusterTimesToUse = [];

            %Flag to track if the last cluster has the last break in it
            lastClusterIncludesBreak = false;

            rDiff = diff(vRootsList);
            rDiffCluster = rDiff < obj.RangeBetweenRootsOfCluster;

            if any(rDiffCluster)
                % Points where a cluster starts
                rise = find(rDiffCluster(2:end) & ~rDiffCluster(1:end-1));

                %points where cluster ends
                drop = find(~rDiffCluster(2:end) & rDiffCluster(1:end-1));

                %clustersIdx stores the index of the start and end roots of each
                %cluster
                clustersIdx = nan(numel(vRootsList), 2);

                startIdx = 1;
                dropStartIdx = 1;
                riseEndIdx = numel(rise);
                lastClusterWithBreak = [nan nan];

                if isempty(drop)
                    %If there is no end to a cluster, then the last break is the end of
                    %the cluster
                    clustersIdx(1,1) = rise(1)+1;
                    clustersIdx(1, 2) = numel(vRootsList);
                    startIdx = 2;
                elseif isempty(rise)
                    %If there is no start to cluster, then cluster starts at the
                    %first break point
                    clustersIdx(1,1) = 1;
                    clustersIdx(1,2) = drop(1)+1;
                    startIdx = 2;
                else
                    %Cluster at start if the first drop idx is less than the first
                    %rise idx
                    if drop(1) < rise(1)
                        dropStartIdx = 2;
                        clustersIdx(1,1) = 1;
                        clustersIdx(1, 2) = drop(1)+1;
                        startIdx = 2;
                    end

                    %Cluster at end
                    if rise(end) > drop(end)
                        riseEndIdx = riseEndIdx -1;
                        lastClusterWithBreak = [rise(end)+1 numel(vRootsList)];
                    end
                end

                if ~isempty(drop) && ~isempty(rise)
                    riseIdx = 1;
                    dropIdx = dropStartIdx;
                    %Loop through the remaining indices and populate the start and
                    %end of the remaining clusters
                    for i=startIdx:startIdx+riseEndIdx-1
                        clustersIdx(i, 1) = rise(riseIdx)+1;
                        clustersIdx(i, 2) = drop(dropIdx)+1;
                        riseIdx = riseIdx+1;
                        dropIdx = dropIdx+1;
                    end
                    if all(~isnan(lastClusterWithBreak))
                        clustersIdx(startIdx+riseEndIdx, :) = lastClusterWithBreak;
                    end
                end

                clustersIdx = clustersIdx(all(~isnan(clustersIdx), 2), :)';
                % Cluster start and end roots(times) in pairs
                clusterRoots = vRootsList(clustersIdx(:));

                clusterTimesToUse = nan(1, numel(clusterRoots)/2);
                %For timepoints within the cluster, the time to use for orientation calculation is the last root of
                %that cluster
                clusterTimesToUse(1:end) = clusterRoots(2:2:end);

                %If the last cluster contains the last break at its end, we will use the
                %orientation just before entering this cluster
                if clusterRoots(end) == breaks(end)
                    clusterTimesToUse(end) = clusterRoots(end-1) - obj.TimeOffsetForLastBreak;
                    lastClusterIncludesBreak = true;
                end
            else
                clusterRoots = [];
            end
        end
    end

    methods(Static, Access = private)
        function dpp = derivpp(pp)
            [breaks,coefs,npieces, order, dim] = unmkpp(pp);

            % take the derivative of each polynomial
            newCoefs = reshape(coefs(:), npieces*dim, order);
            newCoefs = repmat([0, order-1:-1:1],dim*npieces,1).*circshift(newCoefs, 1, 2);
            dpp = mkpp(breaks,newCoefs,dim);
        end

        function [u, du] = calcUdU(pp1, pp2, tpts, zFlag)
            v = pagetranspose(ppval(pp1, tpts));
            dv = pagetranspose(ppval(pp2, tpts));
            %Set z component values to 0 when flag is false
            if ~zFlag
                v(:,3) = 0;
                dv(:,3) = 0;
            end
            v(abs(v)<1e-12) = 0;
            vmag = vecnorm(v,2,2);
            u = bsxfun(@rdivide, v, vmag);
            du = bsxfun(@rdivide, dv, vmag) - bsxfun(@times, v, dot(v, dv, 2) ./ vmag.^3);
        end

        function vRootsList = getVelocityRoots(dpp)
        %coefs of the velocity polynomial
            [breaks, vCoefs, nPieces, order] = unmkpp(dpp);
            vRootsList = nan(1, 3*(order-1)*nPieces);
            vRootsList(1) = breaks(1);
            %Analyze only the positive breaks
            nonNegativeBreakIdx = find(breaks>=0, 1, "first");
            %Add the first positive break point to the list of roots
            vRootsList(1) = breaks(nonNegativeBreakIdx(1));
            %Loop through all the polynomials and get the real roots that lie
            %within that piece
            for i=nonNegativeBreakIdx(1):nPieces
                coder.varsize('coefs', [1, 15], [0, 1])
                %Loop through all coefs
                for j=1:3
                    coefs = vCoefs(3*(i-1)+j, :);
                    r = roots(coefs);
                    realRoots = r(imag(r)==0);
                    realRootsWithinBreaks = realRoots(realRoots>=0 & realRoots<breaks(i+1)-breaks(i));
                    startIdx = find(isnan(vRootsList), 1,'first');
                    vRootsList(startIdx(1):startIdx(1)+numel(realRootsWithinBreaks)-1) = real(realRootsWithinBreaks) + breaks(i);
                end
            end
            startIdx = find(isnan(vRootsList), 1,'first');
            %Add the last break point to the list of roots
            vRootsList(startIdx(1)) = breaks(end);
            vRootsList = vRootsList(~isnan(vRootsList));
            vRootsList = unique(vRootsList);
            vRootsList = sort(vRootsList);
        end
    end
end
