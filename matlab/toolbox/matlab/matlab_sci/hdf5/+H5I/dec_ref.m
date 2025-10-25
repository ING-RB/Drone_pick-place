function ref_count = dec_ref(obj_id)
%H5I.dec_ref  Decrement reference count.
%   ref_count = H5I.dec_ref(obj_id) decrements the reference count of the 
%   object identified by obj_id and returns the new count.
%
%   See also H5I, H5I.get_ref, H5I.inc_ref.

%   Copyright 2006-2024 The MathWorks, Inc.

ref_count = matlab.internal.sci.hdf5lib2('H5Idec_ref', obj_id);            
