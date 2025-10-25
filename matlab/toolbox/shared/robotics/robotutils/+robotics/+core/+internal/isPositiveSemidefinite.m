function [isPDorPSD, isPSD] = isPositiveSemidefinite(B)
%This function is for internal use only. It may be removed in the future.

%ISPOSITIVESEMIDEFINITE Indicates whether B is a positive semi-definite 
%   matrix (returns true or false). Expecting the input B to be an n-by-n 
%   symmetric, non-singular matrix.

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

n = size(B,1);

eigVals = eig(B);
smallestEigVal = min(eigVals);
largestEigVal = max(eigVals);

% The rank tolerance below is set for singular values. when B is symmetric, 
% singular values have the same magnitude as eigenvalues.
normB = abs(largestEigVal);
rankTol = n*eps(normB);

% if the eigen values has apparent negative values 
if smallestEigVal < 0 && abs(smallestEigVal) > rankTol
    isPDorPSD = false;
    isPSD = false;
    return
end

% if eigen
if eigVals(1) < rankTol && rank(B) < n
    isPDorPSD = true;
    isPSD = true;
    return    
end

isPDorPSD = true;    
isPSD = false;

end


%% Alternative solution: testing ALL the principal minors
%
%   Example implementation:
%   NOTE: it might be too slow if the size of the matrix is large. 
%   Also if the matrix is (close to) singular, the result may be incorrect
%
%    sequence = 1:n;
%    for k = 0:n-1
%        idxToKeep = nchoosek(sequence, n-k);
%        for j = 1:size(idxToKeep, 1)
%           if det(B(idxToKeep(j, :), idxToKeep(j,:))) < 0  % det is not reliable if the matrix is singular
%                isPDorPSD = false;
%                return
%           end
%        end
%    end
