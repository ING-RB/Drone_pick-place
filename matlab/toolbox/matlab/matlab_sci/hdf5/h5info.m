function hinfo = h5info(filename, varargin)
%H5INFO  Return information about HDF5 file.
%   INFO = H5INFO(FILENAME) returns information about the entire HDF5 file
%   H5FILE.
%
%   INFO = H5INFO(FILENAME,LOCATION) returns information about the group,
%   dataset, or named datatype specified by location in the HDF5 file 
%   FILENAME.
%
%   INFO = H5INFO(__, 'TextEncoding', 'UTF-8') returns information about
%   the entire file or a specific group, dataset or named datatype in
%   the HDF5 file FILENAME while ensuring names of objects and attributes
%   present in the HDF5 file are handled as UTF-8 encoded text.  This
%   usage is unnecessary if the HDF5 file accurately specifies the use
%   of UTF-8 encoding.
%
%   INFO = H5INFO(URL) returns information about the entire HDF5 file
%   stored at a remote location. When reading data from remote locations,
%   you must specify the full path using an internationalized resource
%   identifier (URL). For example, to read a dataset in an HDF5 file from
%   Amazon S3 cloud specify the full URL for the file:
%       s3://bucketname/path_to_file/example.h5
%   For more information on accessing remote data, see "Work with Remote Data"
%   in the documentation.
%
%   The set of fields in INFO depends on the LOCATION parameter.  Fields
%   that may be present in the INFO structure are:
%   
%   File and groups:
%       Name:       Name of the group.  This is '/' if only a filename is
%                   provided, as this is the name of the root group.
%       Groups:     An array of structures describing subgroups.
%       Datasets:   An array of structures describing datasets.
%       Datatypes:  An array of structures describing named datatypes.
%       Links:      An array of structures describing soft, external,
%                   user-defined, and certain hard links.
%       Attributes: An array of structures describing group attributes.
%
%   Datasets:
%       Name:       Name of the dataset.
%       Datatype:   A struct describing the datatype.
%       Dataspace:  A struct describing the size of the dataset.
%       ChunkSize:  The extents of the dataset's chunk size, if defined.
%       FillValue:  The dataset's fill value, if defined.
%       Filter:     An array of structures describing any defined filters 
%                   such as compression.
%       Attributes: An array of structures describing dataset attributes.
%
%   Named Datatypes:
%       Name:       Name of the datatype object.
%       Class:      HDF5 class of the named datatype.
%       Type:       A string or struct further describing the datatype.
%       Size:       Size of the named datatype in bytes.
%       
%   In each case, INFO will also include 'Filename' as the first field of
%   the top-level struct.
%
%   Example:  Return all information.
%       info = h5info('example.h5');
%
%   Example:  Return information about a group and all data sets contained
%   within the group.
%       info = h5info('example.h5','/g4');
%
%   Example:  Return information about a specific dataset.
%       info = h5info('example.h5','/g4/time');
%
%   Example:  Return all information from an h5 file in Amazon S3.
%       info = h5info('s3://bucketname/path_to_file/example.h5');
%
%   See also H5DISP.

%   Copyright 2010-2024 The MathWorks, Inc.

if nargin > 0
    filename = convertStringsToChars(filename);
end

if nargin > 1
    [varargin{:}] = convertStringsToChars(varargin{:});
end

narginchk(1, 4);

switch(nargin)
    case 1
        location = '/';
        useUtf8 = false;

    case 2
        location = varargin{1};
        useUtf8 = false;
        
    case 3
        location  = '/';
        useUtf8 = matlab.io.internal.imagesci.h5ParseEncoding(varargin);
        
    case 4
        location = varargin{1};
        varargin = varargin(end-1:end);
        useUtf8 = matlab.io.internal.imagesci.h5ParseEncoding(varargin);
end
    

validateattributes( filename,{'char', 'string'},{'nonempty', 'scalartext'}, ...
                                                    'h5info','FILENAME' );
validateattributes( location,{'char', 'string'},{'nonempty', 'scalartext'}, ...
                                                    'h5info','LOCATION' );

% Try to get a full pathname.  If FOPEN fails, it may be because we need to
% use the family driver, in which case the filename string does not 
% identify an actual location on disk.

% If the Filename is not a URI, use fopen to get the actual location on
% disk. Otherwise directly pass the Filename as it is.
isRemote = matlab.io.internal.vfs.validators.hasIriPrefix(filename);
if ~isRemote
    fid = fopen(filename,'r');
    if ( fid ~= -1 )
        filename = fopen(fid);  % get full pathname
        fclose(fid);
    end
end

try
    hinfo = matlab.internal.sci.h5infoc(filename, location, useUtf8);
catch ME
    if isRemote && ...
            strcmp(ME.identifier, 'MATLAB:imagesci:h5info:fileOpenErr') && ...
            contains(... % content type is HTML (will be empty for non-HTTP links)
            matlab.io.internal.filesystem.getContentType(filename), "text/html", ...
            IgnoreCase=true)
        % if we are reading a remote HDF5 file from an HTTP link and the
        % content type is HTML, this error is because we are trying to read
        % HTML file as HDF5. This can happen when authentication is
        % required and we get a login page back.
        error(message('MATLAB:imagesci:hdf5io:readHTML', filename));
    else
        rethrow(ME);
    end
end

hinfo.Filename = filename;

% If it is a dataset, remove the leading directory paths.
if isfield(hinfo,'ChunkSize')
    parts = regexp(hinfo.Name,'/','split');
    hinfo.Name = parts{end};
end

% Reorder the fields such that Filename is on top.
n = numel(fieldnames(hinfo));
hinfo = orderfields(hinfo, [n 1:n-1]);

return
