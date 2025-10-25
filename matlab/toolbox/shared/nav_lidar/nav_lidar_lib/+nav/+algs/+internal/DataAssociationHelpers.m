classdef DataAssociationHelpers < nav.algs.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%DATAASSOCIATIONHELPERS Provide utilities to associate features extracted
%   from different lidar scan observations

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen

    
    methods (Static)
        
        function [bestHypothesis, bestJointComp] = modifiedFastJCBB(featuresA, featureCompactCovariancesA, scanSegMasksA, ...
                                      observationsB, observationCompactCovariancesB, scanSegMasksB, ...
                                      odomAB, odomABCov, compScale)
            %modifiedFastJCBB A modified version of fast
            %   Joint-Compatibility Branch-n-Bound algorithm to find the 
            %   best hypothesis for the feature match
            
            numObservations = size(observationsB, 1);
            
            sharedInfo = struct(...
                         'FeaturesA', featuresA, ...
                         'FeatureCompactCovariancesA', featureCompactCovariancesA, ...
                         'ScanSegMasksA', scanSegMasksA, ...
                         'ObservationsB', observationsB, ...
                         'ObservationCompactCovariancesB', observationCompactCovariancesB, ...
                         'ScanSegMasksB', scanSegMasksB, ...
                         'OdomAB', odomAB, ...
                         'OdomABCov', odomABCov, ...     
                         'CompThresholdScale', compScale, ...
                         'ThreshIndividualComp', nav.algs.internal.getChiSqCriticalValue(2, 1, compScale), ...
                         'OdomABCovInv', inv(odomABCov), ...
                         'NumObservations', numObservations, ...
                         'NumFeatures', size(featuresA, 1) );
            
            bestHypothesis = zeros(1, numObservations);
            bestJointComp = 1e9;

            [bestHypothesis, bestJointComp] = ...
                fastJCBBRecursive( zeros(1, numObservations), ...
                                   bestHypothesis, ...
                                   bestJointComp, ...
                                   coder.ignoreConst(sharedInfo), ...
                                   coder.ignoreConst(1), ...
                                   coder.ignoreConst(0), ...
                                   coder.ignoreConst(0), ...
                                   coder.ignoreConst(zeros(3,1)), ...
                                   coder.ignoreConst(zeros(3)), ...
                                   coder.ignoreConst(nan) );

        end
        
        
        function [g, C, distSq, u, v, Jac1, Jac2] = innovate(fA, fACov, odomAB, odomABCov, eB, eBCov)
            %innovate
            [g, C, distSq, u, v, Jac1, Jac2] = innovateLineFeature(fA, fACov, odomAB, odomABCov, eB, eBCov);
        end
        
        
        function [relPose, cov] = estimateRobotMotionAPosteriori(optHypothesis, ...
                                                  featuresA, ...
                                                  observationsB, weights)
            %estimateRobotMotionAPosteriori Estimate the relative pose and
            %   the corresponding covariance from the previously identified
            %   line feature pairs.
            
            W = diag(weights(logical(optHypothesis)));

            dRho = zeros(nnz(optHypothesis),1);
            dA = zeros(nnz(optHypothesis),1);
            HRho = zeros(nnz(optHypothesis),2);
            HAlpha = ones(nnz(optHypothesis),1);

            k = 1;
            for i = 1:numel(optHypothesis)
                ji = optHypothesis(i);
                if ji > 0
                    fA = featuresA(ji, :);
                    rhoA = fA(1);
                    alphaA = fA(2);

                    eB = observationsB(i, :);
                    rhoB = eB(1);
                    alphaB = eB(2);

                    dRho(k) = rhoA - rhoB;
                    dA(k) = alphaA - alphaB;
                    HRho(k,:) = [cos(alphaA), sin(alphaA)];
                    k = k + 1;
                end

            end

            xy = (HRho'*W*HRho)\ ( (HRho')*W*dRho );
            covXY = inv((HRho'*W*HRho));

            a = (HAlpha'*W*HAlpha)\( (HAlpha')*W*dA );
            covA = inv(HAlpha'*W*HAlpha);

            relPose = [xy; a]';
            cov = blkdiag(covXY, covA);

        end
        
        
    end
    
end

%% Recursive function

function [bestHypothesis, bestJointComp] = fastJCBBRecursive(H, bestHypothesis, bestJointComp, info, i, d, t, s, M, HJointComp)
    %fastJCBBRecursive

    if i > info.NumObservations % i.e. if already leaf node
        
        if pairings(H) >= pairings(bestHypothesis)
            bestHypothesis = H;
            bestJointComp = HJointComp;
        end
    else
        eB = info.ObservationsB(i, :);
        eBCov = diag([info.ObservationCompactCovariancesB(i, 1), info.ObservationCompactCovariancesB(i, 2)]);
        for j = 1:info.NumFeatures
            fA = info.FeaturesA(j, :);

            fACov = diag([info.FeatureCompactCovariancesA(j, 1), info.FeatureCompactCovariancesA(j, 2)]);
            [g, ~, distSq, u, v] = nav.algs.internal.DataAssociationHelpers.innovate(fA, fACov, info.OdomAB, info.OdomABCov, eB, eBCov);

            if distSq < info.ThreshIndividualComp % if pass the individual compatibility check
                invug = u\g;
                invuv = u\v;
                tBar = t + g' * invug;
                sBar = s + v' * invug;
                MBar = M + v' * invuv;
                dBar = d + 2; % dimension
                threshJointComp = nav.algs.internal.getChiSqCriticalValue(dBar, 1, info.CompThresholdScale);
                DSq = tBar - sBar' * ((info.OdomABCovInv + MBar) \ sBar);% this is the quick way to compute mahalanobis dist sq
                if DSq < threshJointComp  
                    % if the joint compatibility test pass, move down
                    % next level in interpretation tree
                    H(i) = j;
                    [bestHypothesis, bestJointComp] = fastJCBBRecursive(H, bestHypothesis, bestJointComp, coder.ignoreConst(info), coder.ignoreConst(i+1), coder.ignoreConst(dBar), coder.ignoreConst(tBar), coder.ignoreConst(sBar), coder.ignoreConst(MBar), coder.ignoreConst(DSq));
                end
            end

        end

        if pairings(H) + info.NumObservations - i > pairings(bestHypothesis) 
            % if the best pairing result current "H" can achieve still cannot
            % beat the existing bestHypothesis, don't even bother to
            % explore the no match case for observation i
            H(i) = 0;
            [bestHypothesis, bestJointComp] = fastJCBBRecursive(H, bestHypothesis, bestJointComp, coder.ignoreConst(info), coder.ignoreConst(i+1), coder.ignoreConst(d), coder.ignoreConst(t), coder.ignoreConst(s), coder.ignoreConst(M), coder.ignoreConst(HJointComp) );

        end
    end

end



%% utility functions

function N = pairings(hypo)
    %pairings
    N = nnz(unique(hypo));
end



function [g, C, distSq, u, v, Jac1, Jac2] = innovateLineFeature(lnA, lnACov, odomAB, odomABCov, lnB, lnBCov)
%INNOVATELINEFEATURE Take measurement (compute pre-filtered residual) using line features

    rhoA = lnA(1);
    thetaA = lnA(2);
    x2 = odomAB(1);
    y2 = odomAB(2);
    phi2 = odomAB(3); 
    g = [ rhoA - x2 * cos(thetaA) + y2 * sin(thetaA); thetaA - phi2] - lnB(:);
    Jac1 = eye(2);
    Jac2 = [ -cos(thetaA), sin(thetaA), 0;
              0, 0, -1];
    u = lnACov + lnBCov;
    C = Jac2 * odomABCov * Jac2' + u; % propagate uncertainty
    distSq = g'*(C\g);
    v = Jac2;
end




