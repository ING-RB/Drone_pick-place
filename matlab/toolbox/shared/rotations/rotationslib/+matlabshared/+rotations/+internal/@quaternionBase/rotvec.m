function rv = rotvec(q)
%ROTVEC Convert quaternion to a rotation vector in radians
%   R = ROTVEC(Q) converts the quaternion array Q to an N-by-3 matrix
%   of equivalent rotation vectors. The rows of R are the [X Y Z]
%   angles of the rotation vectors in radians. The ith row of R
%   corresponds to the element Q(i). The array Q can be of
%   arbitrary dimensions. The elements of Q are normalized prior to
%   conversion.

%   Copyright 2018 The MathWorks, Inc.    

%#codegen 

qn = normalize(q);
m = compact(qn);
ang = 2*acos(m(:,1));
ax = m(:,2:end);
mag = sqrt(sum(ax .^ 2,2));
num = numel(ang);
rv = zeros(num,3,classUnderlying(q));
thresh = eps(class(m))*10;
for ii = 1:num
    mii = mag(ii);
    if (mii>thresh)
        rv(ii,:) = ang(ii) .* ax(ii,:) ./ mag(ii);
    end
end
end
