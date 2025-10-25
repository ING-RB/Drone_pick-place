function edges = generateBinEdgesFromBinMethod(binmethod,xmin,xmax,hardlimits,maxnbins)
%GENERATEBINEDGESFROMBINMETHOD Generate bin edges from bin method.
%   EDGES = GENERATEBINEDGESFROMBINMETHOD(BINMETHOD,XMIN,XMAX,HARDLIMITS,MAXNBINS)
%   returns a vector of duration edges of uniform width BINMETHOD (where
%   BINMETHOD is a char array indicating a unit of time, e.g. 'hour')
%   generated using the duration limits XMIN and XMAX. If HARDLIMITS is
%   true, then XMIN and XMAX are forced to be the first and last edges.
%   Otherwise, the first and last edges are calculated and may be different
%   than XMIN and XMAX. If the number of bins would exceed MAXNBINS, then
%   BINMETHOD is ignored and EDGES is equivalent to
%   generateBinEdgesFromNumBins(MAXNBINS,XMIN,XMAX,HARDLIMITS).

%   Copyright 2016-2020 The MathWorks, Inc.

switch binmethod
    case 'year'
        binwidth = years(1);
    case 'day'
        binwidth = days(1);        
    case 'hour'
        binwidth = hours(1);        
    case 'minute'
        binwidth = minutes(1);        
    case 'second'
        binwidth = seconds(1);
end
if hardlimits
    leftedge = ceil(xmin,binmethod);
    if leftedge == xmin
        leftedge = leftedge + binwidth;
    end
    rightedge = floor(xmax,binmethod);
    if rightedge == xmax
        rightedge = rightedge - binwidth;
    end
    if (rightedge - leftedge)/binwidth + 2 <= maxnbins
        edges = [xmin leftedge:binwidth:rightedge xmax];
    else
        edges = generateBinEdgesFromNumBins(maxnbins,xmin,xmax,hardlimits);
    end
else
    leftedge = floor(xmin,binmethod);
    rightedge = max(ceil(xmax,binmethod),leftedge+binwidth);
    if (rightedge - leftedge)/binwidth <= maxnbins
        edges = leftedge:binwidth:rightedge;
    else
        edges = generateBinEdgesFromNumBins(maxnbins,xmin,xmax,hardlimits);
    end
end
end

