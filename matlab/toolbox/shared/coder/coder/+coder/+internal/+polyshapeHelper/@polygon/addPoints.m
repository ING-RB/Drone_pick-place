function pg = addPoints(pg, Xarray, Yarray, nPts, btype)
%MATLAB Code Generation Library Function
% Add the vertices to polyshape

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

bdStIdx = zeros(1,0,'double');
bdEnIdx = zeros(1,0,'double');
coder.varsize('bdStIdx',[1 Inf]);
coder.varsize('bdEnIdx',[1 Inf]);
xPtArr = zeros(1,0,'double');
yPtArr = zeros(1,0,'double');
coder.varsize('xPtArr',[1 Inf]);
coder.varsize('yPtArr',[1 Inf]);

dropped = 0;
stIdx = 1;

for ip = 1:nPts
    x = Xarray(ip);
    y = Yarray(ip);
    coder.internal.errorIf(isinf(x) || isinf(y), ...
                           'MATLAB:polyshape:infNotAllowed');

    if (isnan(x))
        if (ip == 1)
            stIdx = ip+1;
            continue;
        end
        [b,cl] = finalize(stIdx,ip-1,Xarray,Yarray);
        if (b)
            cBdSt = numel(xPtArr)+1;
            bdStIdx = horzcat(bdStIdx, cBdSt); %#ok<AGROW>
            xPtArr = horzcat(xPtArr, Xarray(stIdx:ip-1)); %#ok<AGROW>
            yPtArr = horzcat(yPtArr, Yarray(stIdx:ip-1)); %#ok<AGROW>
            if(~cl)
                xPtArr = horzcat(xPtArr, Xarray(stIdx)); %#ok<AGROW>
                yPtArr = horzcat(yPtArr, Yarray(stIdx)); %#ok<AGROW>
            end
            bdEnIdx = horzcat(bdEnIdx, numel(xPtArr)); %#ok<AGROW>

            stIdx = ip+1;
        else
            stIdx = ip+1;
            dropped=dropped+1;
        end
    end

end

if (nPts >= stIdx)
    [b,cl] = finalize(stIdx,nPts,Xarray,Yarray);
    if (b)
        cBdSt = numel(xPtArr)+1;
        bdStIdx = horzcat(bdStIdx, cBdSt);
        xPtArr = horzcat(xPtArr, Xarray(stIdx:nPts));
        yPtArr = horzcat(yPtArr, Yarray(stIdx:nPts));
        if(~cl)
            xPtArr = horzcat(xPtArr, Xarray(stIdx));
            yPtArr = horzcat(yPtArr, Yarray(stIdx));
        end
        bdEnIdx = horzcat(bdEnIdx, numel(xPtArr));
    else
        dropped=dropped+1;
    end
end

if (dropped > 0)
    coder.internal.warning('MATLAB:polyshape:boundary3Points');
end

if ~isempty(xPtArr)
    % call append only for non empty boundaries
    pg = appendBoundaries(pg, xPtArr, yPtArr, bdStIdx, bdEnIdx, btype);
    % add elements to the accessOrder
    pg.accessOrder = updateAccessOnAdd(pg.accessOrder, coder.internal.indexInt(numel(bdStIdx)));
end

% Replace this with an internal flag 'all'
for i = 1:pg.numBoundaries
    pg.boundaries = pg.boundaries.updateDerived(i);
end

pg.polyClean = false;
pg = pg.resolveNesting();

pg = pg.updateDerived();

%-----------------------------------------------------------------------
function [b,cl] = finalize(fIdx, lIdx, X, Y)
cl = true;
if ((lIdx-fIdx+1) < 3)
    b = false;
    return
end

if (X(fIdx) == X(lIdx)) && (Y(fIdx) == Y(lIdx))
    if ((lIdx-fIdx+1) >= 4)
        b = true;
        return
    else
        b = false;
        return
    end
end

cl = false;
b = true;
