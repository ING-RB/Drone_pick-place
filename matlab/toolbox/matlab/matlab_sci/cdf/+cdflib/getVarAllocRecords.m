function numrecs = getVarAllocRecords(cdfId,varNum)
%cdflib.getVarAllocRecords Return number of allocated records
%   numrecs = cdflib.getVarAllocRecords(cdfId,varNum) returns the number of 
%   records allocated for the variable identified by varNum in the file
%   specified by cdfId.
%
%   This function corresponds to the CDF library C API routine 
%   CDFgetzVarAllocRecords.  
%
%   Example:
%       cdfId = cdflib.open('example.cdf');
%       varNum = 0;
%       numRecs = cdflib.getVarAllocRecords(cdfId,varNum);
%       cdflib.close(cdfId);
%   
%   Please read the file cdfcopyright.txt for more information.
%
%   See also cdflib, cdflib.setVarAllocBlockRecords.

%   Copyright 2009-2022 The MathWorks, Inc.

numrecs = matlab.internal.imagesci.cdflib('getVarAllocRecords',cdfId,varNum);
