function timeVec = breakdownTT2000(timeVal)
%cdflib.breakdownTT2000 Decompose a TT2000 value
%   timeVec = cdflib.breakdownTT2000(timeVal) decomposes a CDF_TIME_TT2000 
%   value into individual components.  timeVec will have 9xn elements,
%   where n is the number of TT2000 values.
%
%     timeVec(1,:)  = year AD, e.g. 1994
%     timeVec(2,:)  = month, 1-12
%     timeVec(3,:)  = day, 1-31
%     timeVec(4,:)  = hour, 0-23
%     timeVec(5,:)  = minute, 0-59
%     timeVec(6,:)  = second, 0-59
%     timeVec(7,:)  = msec, 0-999
%     timeVec(8,:)  = usec, 0-999
%     timeVec(9,:)  = nsec, 0-999
%
%   This function corresponds to the CDF library C API routine 
%   breakdownTT2000.
%
%   Example:
%       timeVec = [1999 12 31 23 59 59 0 0 0];
%       tt2000 = cdflib.computeTT2000(timeVec);
%       timeVec = cdflib.breakdownTT2000(tt2000);
%
%   See also cdflib.computeTT2000, cdflib.computeEpoch, cdflib.epochBreakdown, 
%       cdflib.computeEpoch16, cdflib.epoch16Breakdown.

%   Copyright 2022 The MathWorks, Inc.

validateattributes(timeVal,{'int64'},{'nonempty'});

timeVec = matlab.internal.imagesci.cdflib('breakdownTT2000',timeVal);
