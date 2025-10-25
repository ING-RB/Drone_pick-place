%#codegen
function [R] = svdPSD(A)
    %-----------------------------------------------
    % Author: Debraj Bhattacharjee
    % Copyright 2019 The MathWorks, Inc.
    %
    % Inputs:
    %     A  -  Any Positive Semi Definite Matrix
    %
    % Outputs:
    %     R  -   Square root of matrix A such that A = R*R'
    %------------------------------------------------
    
    % Compute Eigendecomposition/SVD/Schur Decomposition of A
    [~,S,V] = svd(A);

    Ss = sqrt(S);
    
    R = V*Ss;             
end