function free_space = get_freespace(file_id)
%H5F.get_freespace  Return amount of free space in file.
%   free_space = H5F.get_freespace(file_id) returns the amount of space 
%   that is unused by any objects in the file specified by file_id.
%
%   See also H5F.

%   Copyright 2006-2024 The MathWorks, Inc.

free_space = matlab.internal.sci.hdf5lib2('H5Fget_freespace', file_id);            
