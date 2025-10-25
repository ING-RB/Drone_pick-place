function pgon = polyRemoveHoles(pgon)
%

% Copyright 2023-2024 The MathWorks, Inc.

%#codegen

nc = pgon.getNumBoundaries();
idxRemoved = coder.nullcopy(zeros(1,pgon.getNumHoles,'like',nc));

pgon = pgon.clearDerived();

k = 1;
for i = nc:-1:1
    if (pgon.boundaries.isHoleIdx(i))
        idxRemoved(k) = i;
        k = k + 1;
    end
end

pgon = pgon.removeBoundary(idxRemoved);
pgon = pgon.resolveNesting();

pgon = pgon.updateDerived();
