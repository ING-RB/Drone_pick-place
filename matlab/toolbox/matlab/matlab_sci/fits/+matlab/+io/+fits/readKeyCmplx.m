function [value,comment] = readKeyCmplx(fptr,keyname)
%readKeyCmplx return the specified keyword as complex scalar value
%   [VALUE,COMMENT] = readKeyCmplx(FPTR,KEYNAME) returns the specified key 
%   and comment.  VALUE is returned as a double precision complex scalar
%   value.
%
%   This function corresponds to the "fits_read_key_dblcmp" (ffgkym) 
%   function in the CFITSIO library C API.
%
%   See also fits, readKey, readKeyDbl, readKeyLongLong

%   Copyright 2011-2020 The MathWorks, Inc.
                                                                                                                 
if nargin > 1
    keyname = convertStringsToChars(keyname);
end

validateattributes(fptr,{'uint64'},{'scalar'},'','FPTR');
validateattributes(keyname,{'char'},{'nonempty'},'','KEYNAME');
[value,comment] = matlab.internal.imagesci.fitsiolib('read_key_dblcmp',fptr,keyname);
