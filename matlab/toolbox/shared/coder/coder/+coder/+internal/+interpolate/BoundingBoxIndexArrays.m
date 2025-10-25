function [idx,stride] = BoundingBoxIndexArrays(V)
% Construct the index vectors needed to extract the elements of V for a
% bounding box. For example, if the bounding box starts at the V(2,5,1,3),
% then the value array for the bounding box defined by the points with
% coodinates x1(2:3),x2(5:6),x3(1:2),x4(3:4) is V(2:3,5:6,1:2,3:4). These
% values can be obtained in the form of a column vector as V(idx + offset),
% where offset = sub2ind(size(V),2,5,1,3) = 1 +
% (2-1)*stride(1) + (5-1)*stride(2) + (1-1)*stride(3) + (3-1)*stride(4).

%#codegen
ONE = coder.internal.indexInt(1);
ND = coder.internal.indexInt(coder.internal.ndims(V));
n = coder.const(eml_lshift(ONE,ND));
idx = ones(n,1,coder.internal.indexIntClass);
stride = zeros(ND,1,coder.internal.indexIntClass);
s = ONE;
stride(1) = ONE;
for j = 2:2:n
    idx(j) = idx(j) + 1;
end
for k = 2:ND
    s = s*coder.internal.indexInt(size(V,k - 1));
    stride(k) = s;
    period = eml_lshift(ONE,k);
    halfperiod = eml_rshift(period,ONE);
    nperiods = eml_rshift(n,k);
    for j = 1:nperiods
        offset = (j - 1)*period + halfperiod;
        for i = 1:halfperiod
            idx(offset + i) = idx(offset + i) + s;
        end
    end
end