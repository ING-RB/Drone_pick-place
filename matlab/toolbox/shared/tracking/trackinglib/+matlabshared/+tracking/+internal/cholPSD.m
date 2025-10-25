%#codegen
function value = cholPSD(A)
    %-----------------------------------------------
    % Author: Debraj Bhattacharjee
    % Copyright 2019 The MathWorks, Inc.
    %
    % Inputs:
    %     A  -  Any Positive Semi Definite Matrix
    %
    % Outputs:
    %     value  -   Square root of matrix A such that A = value*value.'
    %------------------------------------------------

    % Check if Cholesky Factorization can be computed
    [~, flag] = chol(A);
    
    if (flag == 0)
        value = (chol(A)).';
    else
        value = matlabshared.tracking.internal.svdPSD(A);
    end
end