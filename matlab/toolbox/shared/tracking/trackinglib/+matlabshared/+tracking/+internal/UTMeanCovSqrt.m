function [Ymean, Sy, Pxy] = UTMeanCovSqrt(meanWeights, covWeights, OOM, Y1, Y2, X1, X2)
    % This function calculates the mean (Ymean), square-root covariance (Sy) and
    % cross-covariance (Pxy) of the unscented transformation.
    %
    % Input arguments:
    %   meanWeights: ([2 1] vector) The weights needed to calculate the
    %                mean of the transformed sigma points Y1 and Y2. The first
    %                element is used for Y1, the second element is used for the
    %                whole matrix Y2 which have the save weight.
    %   covWeights:  ([2 1] vector) The weights needed to calculate
    %                the covariance Pxy and square-root covariance Sy.
    %                The first element is used for Y1,
    %                the second element is used for the whole matrix Y2
    %                which have the save weight.
    %   OOM:         (Scalar) Order of magnitude associated with meanWeights and
    %                covWeights, which is required for numerical stability of the
    %                unscented transformation.
    %   Y1:          ([n 1] vector) The result of propagation of the first sigma
    %                point, the state estimate X1, through the nonlinear
    %                function.
    %   Y2:          ([n m] matrix) The result of the propagation of the sigma
    %                points X2 through the nonlinear function if we have
    %                additive noise. In this case m=h. With non-addditive
    %                noise, Y2 also contains propagated sigma points that are
    %                formed at the mean state, and distributed around zero-mean
    %                noise. Then m>h.
    %   X1:          ([k 1] vector) The first sigma point, the center of the
    %                rest of the sigma points X2
    %   X2:          ([k h] vector) The rest of the sigma points, which are 
    %                distributed around X1
    %
    % Output arguments:
    %   Ymean:       ([n m] matrix) The weighted average of Y1 and Y2.
    %                Calculated by an equivalent of:
    %                OOM*(Y1*meanWeights(1)+sum(Y2*meanWeights(2),2))
    %    Sy:         ([n n] matrix) Square-root of the Covariance matrix of Y1 and Y2. Calculated
    %                by an equivalent of:
    %                OOM*( ([Y1 Y2]-Ymean) * diag([covWeights(1) covWeights(2)*ones(1,m)]) * ([Y1 Y2]-Ymean)' )
    %   Pxy:         ([k n] matrix) The cross-covariance matrix of [X1 X2] and 
    %                [Y1 Y2]. Calculated by an equivalent of:
    %                OOM*( ([X1 X2]-X1) * diag([covWeights(1) covWeights(2)*ones(1,h)]) * ([Y1 Y2(:,1:h)]-Ymean)' )
    %                Pxy is used for calculating the Kalman gain and updating
    %                the states. We only need the first h columns of Y2 for
    %                this, as we do not need to estimate the evolution of the
    %                noise terms.

    % Notes:
    % 1. Since this is an internal function, no validation is done at this
    %    level. Any additional input validation should be done in a function or
    %    object that use this function.
    % 2. The type of the output depends on the type of the inputs. If all the
    %    inputs are single precision, the outputs will be single precision as
    %    well.

    %   Copyright 2016-2021 The MathWorks, Inc.

    %#codegen
    %#ok<*EMCLS>
    %#ok<*EMCA>
    %#ok<*MCSUP>

    % The following calculation replaces:
    % Ymean   = Y * meanWeights; % because codegen fails tolerance test on the vectorized version.
    Ymean = Y1 * meanWeights(1);
    for kk = 1:size(Y2,2)
        Ymean = Ymean + Y2(:, kk) * meanWeights(2);
    end
    Ymean   = Ymean * OOM; % Rescale to the correct order of magnitude

    Y1 = Y1 - Ymean;

    %loop is faster than bsxfun
    %Y2  = bsxfun(@minus, Y2, Ymean); % Codegen errors out on Y - Ymean when Ymean is 1
    for kk = 1:size(Y2,2)
        Y2(:,kk) = Y2(:,kk) - Ymean;
    end

    % Pyy     = Ytilde * covWeightsMat * Ytilde';
    % Pyy     = Pyy * OOM; % Rescale to the correct order of magnitude
    %
    % Partition Ytilde=[Y1 Y2], and make use of the facts that covWeightsMat is
    % a diagonal matrix, and its diagonals (2:end) has the same value
    % Compute sign of OOM
    signOOM = sign(OOM);
    covWeights = signOOM*covWeights;
    OOM = signOOM*OOM;
    sqrtOOM = sqrt(OOM);

    % Maintain positive sign for covWeights(2)
    W2 = sqrt(covWeights(2));

    % Compute Sy
    M = W2*Y2.';
    [~,R] = qr(M,0);

    % If the number of measurements are greater than the number of sigma
    % points, M becomes a fat matrix and as a result, economy QR
    % does not produce a square R. This will cause cholupdate to fail.
    % Therefore, we pad R with the appropriate number of zeros so that Sy 
    % is a square matrix.
    Sy = [R; zeros(size(R,2) - size(R,1) , size(R,2), 'like', R)];
  
    % Determine sign of cholupdate and compute Sy
    if(sign(covWeights(1)) == 1)
        Sy = sqrtOOM*matlabshared.tracking.internal.cholUpdateFactor(Sy,Y1,'+');
    else
        Sy = sqrtOOM*matlabshared.tracking.internal.cholUpdateFactor(Sy,Y1,'-');
    end     

    if nargout==3
        % Pxy is required
        %
        %   The way we use this function, the dimensions of Y2 is based on
        %   if the noise term entering the function linearly or not (f(x,v) vs
        %   f(x)+v). But regardless, we only need to calculate the first Ns
        %   rows of Pxy where Ns is the number of state

        % Perform calculations in-place to save memory and avoiding creating Xtilde
        % Xtilde  = bsxfun(@minus, Xs, Xs(:,1));
        % Pxy = Xs * covWeightsMat * Ytilde';

        %loop is faster than bsxfun
        %X2 = bsxfun(@minus, X2, X1); % X1 is the original state
        for kk=1:size(X2,2)
            X2(:,kk) = X2(:,kk) - X1;
        end

        Pxy = X2 * Y2(:,1:size(X2,2))';
        % Rescale to the correct order of magnitude
        Pxy = Pxy * (covWeights(2) * OOM);
    end
end 
