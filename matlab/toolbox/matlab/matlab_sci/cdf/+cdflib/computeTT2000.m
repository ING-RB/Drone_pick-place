function timeVal = computeTT2000(timeVec)
%cdflib.computeTT2000 Convert time value to CDF_TIME_TT2000 value
%   timeVal = cdflib.computeTT2000(timeVec) returns a CDF_TIME_TT2000 value given the 
%   individual components in timeVec.  timeVec must have nine components:
%
%     year     - year (AD, e.g., 1994)
%     month    - month (1-12)
%     day      - day (1-31)
%     hour     - hour (0-23)
%     minute   - minute (0-59)
%     second   - second (0-59)
%     msec     - millisecond (0-999)
%     usec     - microsecond (0-999)
%     nsec     - nanosecond (0-999)
%
%   The output is an int64 value.
%
%   This function corresponds to the CDF library C API routine 
%   computeTT2000.
%
%   Example:
%       timeVec = [1999 12 31 23 59 59 0 0 0];
%       tt2000 = cdflib.computeTT2000(timeVec);
%
%   See also cdflib.breakdownTT2000, cdflib.computeEpoch, cdflib.epochBreakdown, 
%       cdflib.epochBreakdown, cdflib.epoch16Breakdown.

%   Copyright 2022 The MathWorks, Inc.

validateattributes(timeVec,{'double'},{'nonempty'});

timeVal = matlab.internal.imagesci.cdflib('computeTT2000',timeVec);
