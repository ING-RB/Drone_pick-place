function tf = isFullAssignment(access)
% Check whether assignment assigns to the full property. Full assignment 
% must be in one of the following forms:
%    type.prop = value;
%    type.prop(1) = value;

% Copyright 2020 The MathWorks, Inc.

tf = isempty(access) || (isscalar(access) && isequal(access.type,'()') && ...
    isequal(access.subs, {1}));
