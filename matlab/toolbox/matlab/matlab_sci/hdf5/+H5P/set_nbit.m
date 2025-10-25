function set_nbit(plist_id)
%H5P.set_nbit  Setup use of N-Bit filter.
%   H5P.set_nbit(plist_id) sets the N-Bit filter, H5Z_FILTER_NBIT, in 
%   the dataset creation property list plist_id.
%
%   See also H5P.

%   Copyright 2009-2024 The MathWorks, Inc.

matlab.internal.sci.hdf5lib2('H5Pset_nbit',plist_id);
