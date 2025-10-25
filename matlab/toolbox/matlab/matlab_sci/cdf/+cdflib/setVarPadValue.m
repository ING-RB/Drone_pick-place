function setVarPadValue(cdfId,varNum,padvalue)
%cdflib.setVarPadValue Specify pad value
%   cdflib.setVarPadValue(cdfId,varNum,padvalue) specifies the pad value of
%   the variable identified by varNum in the CDF identified by cdfId.
%
%   This function corresponds to the CDF library C API routine 
%   CDFsetzVarPadValue.  
%
%   Example:
%       cdfid = cdflib.create('myfile.cdf');
%       varnum = cdflib.createVar(cdfid,'Time','cdf_int1',1,[],true,[]);
%       cdflib.setVarPadValue(cdfid,varnum,int8(1));
%       cdflib.close(cdfid);
%
%   Please read the file cdfcopyright.txt for more information.
%
%   See also cdflib, cdflib.getVarPadValue.

%   Copyright 2009-2022 The MathWorks, Inc.

if nargin > 2
    padvalue = convertStringsToChars(padvalue);
end

matlab.internal.imagesci.cdflib('setVarPadValue',cdfId,varNum,padvalue);
