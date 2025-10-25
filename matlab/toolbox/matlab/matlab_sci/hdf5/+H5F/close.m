function close(fileId)
%H5F.close  Close HDF5 file.
%   H5F.close(file_id) terminates access to HDF5 file identified by file_id,
%   flushing all data to storage.
%
%   See also H5F, H5F.open.

%   Copyright 2006-2024 The MathWorks, Inc.

if isa(fileId, 'H5ML.id')
    id = fileId.identifier;
    fileId.identifier = -1;
else
    id = fileId;
end
matlab.internal.sci.hdf5lib2('H5Fclose', id);
