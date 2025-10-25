function value = is_hdf5(filename)
%H5F.is_hdf5  Determine if file is HDF5.
%   value = H5F.is_hdf5(name) returns a positive number if the file or the
%   URL specified by name is in the HDF5 format, and zero if it is not. A
%   negative return value indicates failure. When reading data from remote
%   locations, you must specify the full path using a uniform resource
%   locator (URL). For example, to read a dataset in an HDF5 file from
%   Amazon S3 cloud, specify the full URL for the file:
%       s3://bucketname/path_to_file/example.h5
%   For more information on accessing remote data, see "Work with Remote Data"
%   in the documentation.
%
%   Example:
%       value = H5F.is_hdf5('example.tif');
%       if value > 0
%           fprintf('example.tif is an HDF5 file\n');
%       else
%           fprintf('example.tif is not an HDF5 file\n');
%       end
%
%   Example:
%       value = H5F.is_hdf5('s3://bucketname/path_to_file/example.h5');
%       if value > 0
%           fprintf('example.tif is an HDF5 file\n');
%       else
%           fprintf('example.tif is not an HDF5 file\n');
%       end
%   See also H5F.

%   Copyright 2006-2024 The MathWorks, Inc.

if nargin > 0
    filename = convertStringsToChars(filename);
end

value = matlab.internal.sci.hdf5lib2('H5Fis_hdf5', filename);            
