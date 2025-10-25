function edges = generateBinEdgesFromDuration(dur,xmin,xmax,hardlimits,maxnbins)
%GENERATEBINEDGESFROMDURATION Generate bin edges from duration.
%   EDGES = GENERATEBINEDGESFROMDURATION(DUR,XMIN,XMAX,HARDLIMITS,MAXNBINS)
%   returns a vector of duration edges of uniform width DUR (where DUR is a
%   scalar duration) generated using the duration limits XMIN and XMAX. If
%   HARDLIMITS is true, then XMIN and XMAX are forced to be the first and
%   last edges. Otherwise, the first and last edges are calculated and may
%   be different than XMIN and XMAX. If the number of bins would exceed
%   MAXNBINS, then DUR is ignored and EDGES is equivalent to
%   generateBinEdgesFromNumBins(MAXNBINS,XMIN,XMAX,HARDLIMITS).

%   Copyright 2016-2020 The MathWorks, Inc.

if hardlimits
    leftedge = dur*ceil(xmin/dur);
    if leftedge == xmin
        leftedge = leftedge + dur;
    end
    rightedge = dur*floor(xmax/dur);
    if rightedge == xmax
        rightedge = rightedge - dur;
    end    
    if (rightedge - leftedge)/dur + 2 <= maxnbins
        edges = [xmin leftedge:dur:rightedge xmax];
    else
        edges = generateBinEdgesFromNumBins(maxnbins,xmin,xmax,hardlimits);
    end
else
    leftedge = dur*floor(xmin/dur);
    rightedge = max(dur*ceil(xmax/dur),leftedge+dur); % ensure at least one bin    
    if (rightedge - leftedge)/dur <= maxnbins
        edges = leftedge:dur:rightedge;
    else
        edges = generateBinEdgesFromNumBins(maxnbins,xmin,xmax,hardlimits);
    end
end
end

