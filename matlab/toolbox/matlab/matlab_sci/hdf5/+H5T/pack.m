function pack(type_id)
%H5T.pack  Recursively remove padding from compound datatype.
%   H5T.pack(TYPE_ID) recursively removes padding from within a compound 
%   datatype to make it more efficient (space-wise) to store that data. 
%   TYPE_ID is a datatype identifier.
%
%   See also H5T.

%   Copyright 2006-2024 The MathWorks, Inc.

matlab.internal.sci.hdf5lib2('H5Tpack',type_id);
