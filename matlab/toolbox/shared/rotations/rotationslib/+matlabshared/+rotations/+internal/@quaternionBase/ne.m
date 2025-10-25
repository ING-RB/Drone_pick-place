function tf = ne(q,p)
% ~=  Not equal.
%    A ~= B does element by element comparisons between A and B and returns
%    an array with elements set to logical 1 (TRUE) where the relation is
%    true and elements set to logical 0 (FALSE) where it is not. A and B
%    must have compatible sizes. In the simplest cases, they can be the same
%    size or one can be a scalar. Two inputs have compatible sizes if, for
%    every dimension, the dimension sizes of the inputs are either the same
%    or one of them is 1.

%   Copyright 2018-2024 The MathWorks, Inc.    

%#codegen 

    coder.internal.assert( ...
        (isa(q, 'matlabshared.rotations.internal.quaternionBase') || isa(q, 'numeric')) && ...
        (isa(p, 'matlabshared.rotations.internal.quaternionBase') || isa(p, 'numeric')), ...
        'shared_rotations:quaternion:QuatOrNumeric');

    if isa(q, 'matlabshared.rotations.internal.quaternionBase') && isa(p, 'matlabshared.rotations.internal.quaternionBase') 
        tf = (q.a ~= p.a) | (q.b ~= p.b) | (q.c ~= p.c) | (q.d ~= p.d);
    elseif isa(q, 'matlabshared.rotations.internal.quaternionBase') && isa(p, 'numeric')
        z = zeros(size(p), "like", p);
        tf = (q.a ~= p) | (q.b ~= z) | (q.c ~= z) | (q.d ~= z);
    elseif isa(p, 'matlabshared.rotations.internal.quaternionBase') && isa(q, 'numeric')
        z = zeros(size(q), "like", q);
        tf = (p.a ~= q) | (p.b ~= z) | (p.c ~= z) | (p.d ~= z);
    else
        % This branch for codegen. Should not be hit.
        % Implicit expansion
        tf = false(size(q)) & false(size(p));
    end
end
