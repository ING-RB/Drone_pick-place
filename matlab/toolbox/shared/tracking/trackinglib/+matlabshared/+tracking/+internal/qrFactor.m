%#codegen
function [S] = qrFactor(A,S,Ns)
    %-----------------------------------------------
    % Author: Debraj Bhattacharjee
    % Copyright 2019 The MathWorks, Inc.
    %
    % Inputs:
    % A,S,Ns -  Any three input matrices which can form the 
    %           following matrix: M = [S.' * A.' ; Ns.'];
    %           M is the square root of a Positive Semi Definite
    %           Matrix such that P = M.'*M
    %
    % Outputs:
    %     S  -   Lower triangular Square root of matrix P 
    %            such that P = S*S.'
    %------------------------------------------------
    M = [S.' * A.' ; Ns.'];
    if coder.internal.isConst(size(M)) % Always true in MATLAB
        % fixed-size M, coder can infer right size for R
        [~,R] = qr(M,0);
    else
        % Variable-sized M, coder cannot infer the size of R. If number of
        % columns are constant, assume that it is the smaller dimension.
        % This is true for all calls made by filters.
        if coder.internal.isConst(size(M,2))
            % Assume variable-sized dimension > fixed-size dimension.
            % qrFactor "econ" will always produce a size(M,2) matrix.
            R = zeros(size(M,2),'like',M);
            [~,R(:)] = qr(M,0);
        else
            [~,R] = qr(M,0);
        end
    end
    S = R.';
end