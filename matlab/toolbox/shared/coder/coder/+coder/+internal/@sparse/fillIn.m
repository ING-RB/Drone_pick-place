function this = fillIn(this,skipDuplCheck)
%MATLAB Code Generation Private Method

% Remove zero entries and sum duplicates
%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen
if nargin < 2
    skipDuplCheck = true;
else
    coder.internal.prefer_const(skipDuplCheck);
    coder.const(skipDuplCheck);
end
idx = ONE;
for c = 1:coder.internal.indexInt(numel(this.colidx))-1
    ridx = this.colidx(c);
    this.colidx(c) = idx;


    while ridx < this.colidx(c+1)
        val = zeros('like',this.d);
        currRowIdx = this.rowidx(ridx);
        if skipDuplCheck
            val = this.d(ridx);
            ridx = ridx+1;
        else
            while ridx < this.colidx(c+1) &&  this.rowidx(ridx) == currRowIdx
                if islogical(val)
                    val = val || this.d(ridx);
                else
                    val = val + this.d(ridx);
                end
                ridx = ridx+1;
            end
        end
        if val ~= zeros('like',val)
            this.d(idx) = val;
            this.rowidx(idx) = currRowIdx;
            idx = idx+1;
        end
    end
end
this.colidx(end) = idx;

%--------------------------------------------------------------------------
