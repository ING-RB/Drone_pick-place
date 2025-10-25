function indices = translateRowLabels(t, var, indices)
%

% TRANSLATEROWLABELS Translate row labels into numeric indices.

% Copyright 2021-2024 The MathWorks, Inc.

% Here var would either be a variable or a subset of a variable obtained from
% dot subscripting on a parent table or it is a homogeneous array spanning over
% multiple rows and variables obtained from brace subscripting on a parent
% table.

rowLabels = indices{1};
if ~iscolumn(var) && isscalar(indices)
    % Linear indexing using row labels is not allowed on non-column vector
    % variables.
    error(message('MATLAB:table:InvalidLinearIndexing'));
end
% Use the parent table's subs2inds method to do the translation.
% Subscripting on a table variable should follow usual reshaping rules. So call
% subs2inds with subsType forwarding to preserve the subscript's original shape
% if possible.
indices{1} = t.subs2inds(rowLabels,'rowDim',matlab.internal.tabular.private.tabularDimension.subsType_forwardedReference); % (leaves ':' alone)
