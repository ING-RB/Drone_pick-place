function [X1, X2] = calcSigmaPointsSqrt(sqrtP, X1, c)
    % Calculates the Unscented Transformation sigma points around the state X1,
    % distributed according to covariance.
    %
    % The set of outputs [X1 X2] are the set of sigma points.

    % Notes:
    % 1. Since this is an internal function, no validation is done at this
    %    level. Any additional input validation should be done in a function or
    %    object that use this function.
    % 2. The output from the function will have the same type as the covariance
    %    matrix.

    %   Copyright 2016-2019 The MathWorks, Inc.

    %#codegen
    %#ok<*EMCLS>
    %#ok<*EMCA>
    %#ok<*MCSUP>

    % Scale the covariance
    sqrtP = sqrt(c) * sqrtP;
    % Create sigma points
    X2 = [sqrtP -sqrtP];
    for kkC=1:size(X2,2)
        X2(:,kkC) =  X2(:,kkC) + X1;
    end
end
