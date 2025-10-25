function file_id = open(filename,flags,fapl)
%H5F.open  Open HDF5 file.
%   file_id = H5F.open(filename) opens the file specified by 
%   filename for read-only access and returns the file identifier, file_id.
%
%   file_id = H5F.open(name,flags,fapl_id) opens the file specified by 
%   name, returning the file identifier, file_id. flags specifies file 
%   access flags and can be specified by one of the following strings
%   or their numeric equivalents:
%  
%       'H5F_ACC_RDWR'   - read-write mode
%       'H5F_ACC_RDONLY' - read-only mode
%       'H5F_ACC_RDWR|H5F_ACC_SWMR_WRITE'  - SWMR write mode
%       'H5F_ACC_RDONLY|H5F_ACC_SWMR_READ' - SWMR read mode
%  
%   The file access property list,fapl_id, may be specified as
%   'H5P_DEFAULT', in which case the default I/O settings are used.
%
%   file_id = H5F.open(URL) opens the hdf5 file at a remote location 
%   for read-only access and returns the file identifier, file_id.
%
%   file_id = H5F.open(URL,flags,fapl_id) opens the file at the remote
%   location specified by URL, returning the file identifier, file_id.
%   flags specifies file access flags.
%  
%   Example:  Open a file in read-only mode with default file access
%   properties.
%       fid = H5F.open('example.h5');
%       H5F.close(fid);
%
%   Example:  Open a file in read-write mode.
%       srcFile = which('example.h5');
%       copyfile(srcFile,'myfile.h5');
%       fileattrib('myfile.h5','+w');
%       fid = H5F.open('myfile.h5','H5F_ACC_RDWR','H5P_DEFAULT');
%       H5F.close(fid);
%
%   Example:  Open a file in Amazon S3 in read-only mode with
%   default file access properties.
%       fid = H5F.open('s3://bucketname/path_to_file/example.h5');
%       H5F.close(fid);
%
%   See also H5F, H5F.close, H5ML.get_constant_value.
%
%   Note: SWMR access is not available for files hosted in remote locations
%   (S3, Azure, HDFS).

%   Copyright 2006-2024 The MathWorks, Inc.

% Get the full path name.
if nargin > 0
    filename = convertStringsToChars(filename);
end

if nargin > 1
    flags = convertStringsToChars(flags);
end

if nargin > 2
    fapl = convertStringsToChars(fapl);
end

% Validate the flag
% The flag can be a character vector, string scalar or a numeric value
if nargin >2
    % check if the flag is a cell array with a single element
    if isa(flags, 'cell')
        validateattributes(flags, {'cell'}, {'nonempty','scalar'});
        flags = flags{1};
    end

    % check if the flag is a scalar numeric value
    if isa(flags, 'numeric')
        validateattributes(flags, {'numeric'}, {'nonempty','scalar','finite'});
    % check if the flag is a char vector or a string
    else
        validateattributes(flags, {'string', 'char'}, {'scalartext'});
    end  
end

% If the Filename is not a URI, use fopen to get the actual location on
% disk. Otherwise directly pass the Filename as it is.
if ~matlab.io.internal.vfs.validators.hasIriPrefix(filename)
    fid = fopen(filename,'r');
    if fid ~= -1
        % It may be ok for FOPEN to fail if the file is to be opened with
        % a non-default driver such as the family driver.
        filename = fopen(fid);
        fclose(fid);
    end
end

% Set default values if necessary.
if nargin == 1
    flags = 'H5F_ACC_RDONLY';
    fapl = 'H5P_DEFAULT';
end


% SWMR is not allowed for files at remote locations
is_remote = matlab.io.internal.vfs.validators.hasIriPrefix(filename);
if (is_remote)
    if (ischar(flags) && any(strcmp(flags, {'H5F_ACC_RDONLY|H5F_ACC_SWMR_READ',...
                                            'H5F_ACC_RDWR|H5F_ACC_SWMR_WRITE'})))
        error(message('MATLAB:imagesci:hdf5lib:SWMRremotefile'));
    end

    % Check if numeric equivalents passed in instead of chars 
    % 33 is the numeric equivalent of 'H5F_ACC_RDWR|H5F_ACC_SWMR_WRITE'
    % 64 is the numeric equivalent of 'H5F_ACC_RDONLY|H5F_ACC_SWMR_READ'
    if (isnumeric(flags) && ismember(flags, [33, 64]))
        error(message('MATLAB:imagesci:hdf5lib:SWMRremotefile'));
    end
end

% Check the library version of the file if flag is SWMR_WRITE (or numerical
% equivalent) as it is only supported by 1.10 and above.
if (strcmp(flags, 'H5F_ACC_RDWR|H5F_ACC_SWMR_WRITE') || all(flags == 33))
    file_id_temp = matlab.internal.sci.hdf5lib2('H5Fopen', filename, ...
        'H5F_ACC_RDONLY', fapl, is_remote);
    fapl_temp = H5F.get_access_plist(file_id_temp);
    [low,high] = H5P.get_libver_bounds(fapl_temp);
    H5F.close(file_id_temp);
    if ((low<2) || (high<2))
        ME = MException('MATLAB:imagesci:hdf5lib:SWMRincorrectlibverbounds', ...
            getString(message('MATLAB:imagesci:hdf5lib:SWMRincorrectlibverbounds')));
        throw(ME)
    end
end

file_id = matlab.internal.sci.hdf5lib2('H5Fopen', filename, flags, fapl, is_remote); 
file_id = H5ML.id(file_id,'H5Fclose');
