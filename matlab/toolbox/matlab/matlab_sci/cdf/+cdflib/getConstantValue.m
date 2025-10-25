function cval = getConstantValue(constantName)
%cdflib.getConstantValue Return numeric value corresponding to CDF constant
%   value = cdflib.getConstantValue(constantName) returns the value as 
%   defined by the CDF library corresponding to constantName.  
%
%   Example:  
%       value = cdflib.getConstantValue('NOVARY');
%
%   Please read the file cdfcopyright.txt for more information.
% 
%   See also cdflib, cdflib.getConstantNames

% Copyright 2009-2022 The MathWorks, Inc.

if nargin > 0
    constantName = convertStringsToChars(constantName);
end

validateattributes(constantName,{'char'},{'nonempty'},'','CONSTANTNAME');
cval = matlab.internal.imagesci.cdflib('getConstantValue',upper(constantName));
