function file_id = create(varargin)
%H5F.create  Create HDF5 file.
%   file_id = H5F.create(filename) creates the file specified by filename
%   with default library properties if the file does not already exist.
%
%   file_id = H5F.create(name,flags,fcpl_id,fapl_id) creates the file
%   specified by name. flags specifies whether to truncate the file, if it 
%   already exists, or to fail if the file already exists.   flags can be
%   specified by one of the following strings or the numeric equivalent.
%
%       'H5F_ACC_TRUNC' - overwrite any existing file by the same name
%       'H5F_ACC_EXCL'  - do not overwrite an existing file
%
%   fcpl_id is the file creation property list identifier. fapl_id is
%   the file access property list identifier.  A value of 'H5P_DEFAULT' for
%   either property list indicates that the library should use default
%   values for the appropriate property list.
%
%   file_id = H5F.create(URL) creates the HDF5 file at the remote location
%   specified by URL with default library properties if the file does not
%   already exist.
%
%   file_id = H5F.create(URL,flags,fcpl_id,fapl_id) creates the file at the
%   remote location specified by URL. flags specifies whether to truncate
%   the file, if it already exists, or to fail if the file already exists.
%   fcpl_id is the file creation property list identifier. fapl_id is the
%   file access property list identifier.
%
%   Example:  Create an HDF5 file called 'myfile.h5'.
%       fid = H5F.create('myfile.h5');
%       H5F.close(fid);
%
%   Example:  Create an HDF5 file called 'myfile.h5', overwriting any 
%   existing file by the same name.  Default file access and file creation 
%   properties shall apply.
%       fcpl = H5P.create('H5P_FILE_CREATE');
%       fapl = H5P.create('H5P_FILE_ACCESS');
%       fid = H5F.create('myfile.h5','H5F_ACC_TRUNC',fcpl,fapl);
%       H5F.close(fid);
%
%   Example:  Create an HDF5 file called 'myfile.h5' in Amazon S3
%       fid = H5F.create('s3://bucketname/path_to_file/myfile.h5');
%       H5F.close(fid);
%
%   See also:  H5F, H5F.close, H5P.create, H5ML.get_constant_value.

%   Copyright 2006-2024 The MathWorks, Inc.

% supply defaults if necessary.
if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

if nargin < 2
    varargin = [varargin {'H5F_ACC_EXCL','H5P_DEFAULT','H5P_DEFAULT'}];
end

% Validate the flag
% The flag can be a character vector, string scalar or a numeric value
if nargin >2
    flags = varargin{2};
    % check if the flag is a cell array with a single element
    if isa(flags, 'cell')
        validateattributes(flags, {'cell'}, {'scalar'});
        flags = flags{1};
    end

    % check if the flag is a scalar numeric value
    if isa(flags, 'numeric')
        validateattributes(flags, {'numeric'}, {'scalar','finite'});
    % check if the flag is a char vector or a string
    else
        validateattributes(flags, {'string', 'char'}, {'scalartext'});
    end  
    varargin{2} = flags;
end
% check if the file location is an IRI
is_remote = matlab.io.internal.vfs.validators.hasIriPrefix(varargin{1});
varargin{end+1} = is_remote;
file_id = matlab.internal.sci.hdf5lib2('H5Fcreate', varargin{:});
file_id = H5ML.id(file_id,'H5Fclose');
