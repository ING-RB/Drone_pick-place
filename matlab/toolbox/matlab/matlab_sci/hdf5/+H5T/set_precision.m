function set_precision(type_id, prec)
%H5T.set_precision  Set precision of atomic datatype.
%   H5T.set_precision(type_id, prec) sets the precision of an atomic datatype.
%   type_id is a datatype identifier. prec specifies the number of bits of
%   precision for the datatype.
%
%   See also H5T.

%   Copyright 2006-2024 The MathWorks, Inc.

matlab.internal.sci.hdf5lib2('H5Tset_precision', type_id, prec); 
