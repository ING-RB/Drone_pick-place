function b = isInside(boundaries, bdIdx, qX, qY)
%

%   Copyright 2022 The MathWorks, Inc.

%#codegen
bndBbox = getBbox(boundaries, bdIdx);

if (~coder.internal.polyshapeHelper.isInsideBbox(bndBbox, qX, qY))
    b = false;
    return;
end

[bdIdx_st, bdIdx_en] = boundaries.getBoundary(bdIdx);
npts = bdIdx_en - bdIdx_st + 1;

% Pnt = struct('X',0,'Y',0);
% myPts = repmat(Pnt,1,npts);
myPtsX = coder.nullcopy(zeros(1,npts));
myPtsY = coder.nullcopy(zeros(1,npts));
crossSign = coder.nullcopy(zeros(1,npts,'int8'));

for i = 1:npts
    [cX,cY] = boundaries.getCoordAtIdx(bdIdx,i);
    myPtsX(i) = cX - qX;
    myPtsY(i) = cY - qY;
end

onboundary = false;
for i = 1:coder.internal.indexInt(npts-1)
    j = i + 1;
    xp = myPtsX(i) * myPtsY(j) - myPtsX(j) * myPtsY(i);

    if (xp > 1.0e-300)
        crossSign(i) = 1;
    elseif (xp < -1.0e-300)
        crossSign(i) = -1;
    else
        crossSign(i) = 0;
    end

    dp = myPtsX(i) * myPtsX(j) + myPtsY(j) * myPtsY(i);

    onboundary = (onboundary || (crossSign(i) == 0 && dp <= 0.));
end

quad = coder.nullcopy(zeros(1,npts,'int8')); % 0 1 2 3
diffQuad = coder.nullcopy(zeros(1,npts,'int8'));
for i=1:coder.internal.indexInt(npts)
    if (myPtsX(i) > 0.)
        if (myPtsY(i) > 0.)
            quad(i) = 0;
        else
            quad(i) = 3;
        end
    else
        if (myPtsY(i) > 0.)
            quad(i) = 1;
        else
            quad(i) = 2;
        end
    end

    if (i == 1)
        continue;
    end

    j = i - 1;
    d = quad(i) - quad(j);
    % Fix up the quadrant differences.  Replace 3 by -1 and -3 by 1.
    % Any quadrant difference with an absolute value of 2 should have
    % the same sign as the cross product.

    if (d == 3)
        d = int8(-1);
    elseif (d == -3)
        d = int8(1);
    elseif (d == 2 || d == -2)
        d = crossSign(j) * 2;
    end
    diffQuad(j) = d;

    if (i == npts)
        diffQuad(i) = 0;
    end
end

sum = 0;
for i = 1:npts-1
    sum = sum + double(diffQuad(i));
end

b = (sum ~= 0) || onboundary;

end
