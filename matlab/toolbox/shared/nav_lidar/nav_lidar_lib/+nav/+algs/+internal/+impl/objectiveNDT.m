function [score, gradient, hessian] = objectiveNDT(laserScan, laserTrans, xgridcoords, ygridcoords, meanq, covar, covarInv)
%This function is for internal use only. It may be removed in the future.

%objectiveNDT Calculate objective function for NDT-based scan matching
%   [SCORE, GRADIENT, HESSIAN] = objectiveNDT(LASERSCAN, LASERTRANS,
%   XGRIDCOORDS, YGRIDCOORDS, MEANQ, COVAR, COVARINV) calculates the NDT
%   objective function by matching the LASERSCAN transformed by LASERTRANS
%   to the NDT described by XGRIDCOORDS, YGRIDCOORDS, MEANQ, COVAR, and
%   COVARINV. The NDT score is returned in SCORE, along with the optionally
%   calculated score GRADIENT, and score HESSIAN.

%   Copyright 2016-2021 The MathWorks, Inc.
%
%   References:
%
%   [1] P. Biber, W. Strasser, "The normal distributions transform: A
%       new approach to laser scan matching," in Proceedings of IEEE/RSJ
%       International Conference on Intelligent Robots and Systems (IROS),
%       2003, pp. 2743-2748

%#codegen

    % Create rotation matrix
    theta = laserTrans(3);
    sintheta = sin(theta);
    costheta = cos(theta);

    rotm = [costheta -sintheta;
            sintheta costheta];

    % Create 2D homogeneous transform
    trvec = [laserTrans(1); laserTrans(2)];
    tform = [rotm, trvec
             0 0 1];

    % Create homogeneous points for laser scan
    hom = [laserScan, ones(size(laserScan,1),1)];

    % Apply homogeneous transform
    trPts = hom * tform';

    % Convert back to Cartesian points
    laserTransformed = trPts(:,1:2);

    hessian = zeros(3,3);
    gradient = zeros(3,1);
    score = 0;
    
    % Eqn (11)
    jacobian3C = laserScan*[-sintheta costheta;
        -costheta -sintheta];

    % Eqn (13)
    qp3p3 = - rotm * laserScan';
    ny = size(ygridcoords,2);

    % Below 3 matrices holds data required for further computation to
    % generate same results as of old code
    validPts = zeros(size(laserTransformed,1), 2, 4);
    validCovInvMatrix = zeros(2, 2, size(laserTransformed,1), 4);
    validIdx = false(size(laserTransformed,1),4);

    % Perform correspondence estimation according to NDT paper
    for cellShiftMode = 1:4
        % Determine the corresponding NDT for each mapped point
        [~, indx] = histc(laserTransformed(:,1), xgridcoords(cellShiftMode,:)); %#ok<HISTC>
        [~, indy] = histc(laserTransformed(:,2), ygridcoords(cellShiftMode,:)); %#ok<HISTC>
        validIds = find(indx~=0 & indy~=0);
        ind = (indx(validIds)-1) *ny + indy(validIds);
        validCovId = false(size(ind));
        for i= 1:length(ind)
            cr = covar(:,:,ind(i),cellShiftMode);
            validCovId(i) = any(cr,'all');
        end
        
        % Ignore cells that contained less than 3 points
        validPtInds = any([any(meanq(:, ind, cellShiftMode), 1); ...
            validCovId'], 1);
        
        normIds = ind(validPtInds);
        validMean = meanq(:, normIds, cellShiftMode);
        validIdx(validIds(validPtInds),cellShiftMode) = true;
        ptIds = validIdx(:,cellShiftMode);

        % Eqn (3)
        validPts(ptIds, :, cellShiftMode) = laserTransformed(ptIds, :) - validMean';
        validCovInvMatrix(:, :, ptIds, cellShiftMode) = covarInv(:, :, normIds, cellShiftMode);
    end

    % Compute the score, gradient and Hessian according to the NDT paper
    for i = 1:size(laserTransformed,1)
        for j=1:4
            if validIdx(i,j)
                % Eqn (11)
                jacobianT = [1 0 jacobian3C(i, 1);
                    0 1  jacobian3C(i, 2)];
                qc = validPts(i, :, j)*validCovInvMatrix(:, :, i, j);
                % As per the paper, this term should represent the probability of
                % the match of the point with the specific cell
                gaussianValue = exp(-qc*validPts(i, :, j)'/2);
                score = score - gaussianValue;
                % Eqn (10)
                gradient = gradient + (qc*jacobianT*gaussianValue)';
            
                for l = 1:3              
                    % Eqn (12)
                    qpj = jacobianT(:,l);
                    for k = l:3
                        qpk = jacobianT(:,k);
                        if l == 3 && k == 3
                            hessian(l,k) = hessian(l,k) + gaussianValue*(-(qc*qpj)*(qc*qpk) +(qc*qp3p3(:,i)) + (qpk'*validCovInvMatrix(:, :, i, j)*qpj));
                        else
                            hessian(l,k) = hessian(l,k) + gaussianValue*(-(qc*qpj)*(qc*qpk) + (qpk'*validCovInvMatrix(:, :, i, j)*qpj));
                        end
                    end
                end
            end
        end
    end
    
    for j = 1:3
        for k = 1:j-1
            hessian(j,k) = hessian(k,j);
        end
    end

    score = double(score);
    gradient = double(gradient);
    hessian = double(hessian);
end
