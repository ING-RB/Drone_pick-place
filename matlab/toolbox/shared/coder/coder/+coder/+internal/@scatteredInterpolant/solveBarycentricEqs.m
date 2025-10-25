function [isQryVtx, bc] = solveBarycentricEqs(wkspc, bc, nd)

%#codegen

coder.inline('always')
coder.internal.prefer_const(nd);

% Scaling and moving origin to query point. This improves solutions for
% sliver and degenerate triangles.
bc = bc .* 0.5;

for i = 1:nd+1 % Iterate over rows
    isQryVtx = coder.internal.indexInt(1);
    for j = 1:nd % Iterate over columns, i.e each coord in vtx of triangle.
        wkspc(i,j) = wkspc(i,j)*0.5;

        if isQryVtx % IS this better or is cast better ?
            isQryVtx = coder.internal.indexInt(wkspc(i,j) == bc(j));
        end

        wkspc(i,j) = wkspc(i,j) - bc(j);
    end
    wkspc(i,nd+1) = wkspc(i,nd+1)*0.5; % The constant in the system is also scaled by 0.5

    % Early exit if the query point is a vertex of the simplex.
    if isQryVtx
        % The barycentric coordinate will be 1 for the vertex to which the
        % query point is equal, the rest are 0.
        bc = zeros(size(bc));
        bc(i) = 1;
        isQryVtx = i;
        return
    end
end

bc(1:nd) = 0;

% MATLAB writes its own solver with complete pivoting. Is that what
% mrdivide uses ?
% If not, test for numerical accuracy and write our own solver if needed.
bc = mrdivide(bc, wkspc);
