function [idxes,cmbs] = combos(counts,variables)
% COMBOS: Generate element combinations of variables
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2022 The MathWorks, Inc.

% Inputs
%     COUNTS: the number of elements in each of the input variables
%     VARIABLES (optional): cell array containing variables to be combined
% Outputs
%     IDXES: an array of indices used to index into the variables in a
%            future step. 
%     CMBS:  a cell array of variables that contain combinations of the
%            input variables (must specify VARIABLES)

% Get sizes
prods = [1 cumprod(counts)];
m = prods(end);
n = numel(counts);

[~,maxsize] = computer;
if m*n > maxsize
    % Gracefully error like in perms()
    error(message('MATLAB:pmaxsize'))
end

% Preallocate outputs
idxes = zeros(m,n);
cmbs = cell(1,n);

% Do combinations
for j=1:n
    if m == 0
        idx = zeros(0,1);
    else
        idx = repmat(repelem((1:counts(j))',m/prods(j+1),1),prods(j),1);
    end
    idxes(:,j) = idx;
    if nargin > 1
        cmbs{1,j} = variables{1,j}(idx);
    end
end