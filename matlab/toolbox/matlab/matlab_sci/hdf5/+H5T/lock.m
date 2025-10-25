function lock(type_id)
%H5T.lock  Lock specified datatype.
%   H5T.lock(TYPE_ID) locks the datatype specified by TYPE_ID, making it 
%   read-only and non-destructible.
%
%   See also H5T.

%   Copyright 2006-2024 The MathWorks, Inc.

matlab.internal.sci.hdf5lib2('H5Tlock',type_id); 
