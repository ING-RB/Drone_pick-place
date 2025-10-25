function h5disp(filename,varargin)
%H5DISP  Display HDF5 metadata.
%
%   H5DISP(FILENAME) displays the entire HDF5 file's metadata.
%
%   H5DISP(FILENAME,LOCATION) displays the metadata for the specified
%   location. If LOCATION is a group, all objects below the group will be
%   described.
%
%   H5DISP(FILENAME,LOCATION,MODE) displays metadata according to the value
%   of MODE.  LOCATION must be given as '/' to print metadata for the
%   entire file.  MODE may be one of the following strings:
%
%       'min'     - minimal, print only group and dataset names
%       'simple' -  print full dataset metadata and print attribute values
%                   if the attribute is integer, floating point, or a
%                   scalar string.
%
%   H5DISP(__, 'TextEncoding', 'UTF-8') displays metadata information
%   about either the entire HD5 file or for a specified location
%   while ensuring names of objects and attributes present in the HDF5
%   file are handled as UTF-8 encoded text.  This usage is unnecessary
%   if the HDF5 file accurately specifies the use of UTF-8 encoding.
%
%   H5DISP(URL) displays the metadata for the entire HDF5 file stored at a
%   remote location.
%
%   H5DISP(URL,LOCATION) displays the metadata for the specified
%   location for an HDF5 file stored at a remote location.
%
%   H5DISP(URL,LOCATION,MODE) displays metadata according to the value
%   of MODE for an HDF5 file stored at a remote location.
%
%   H5DISP(URL, 'TextEncoding', 'UTF-8') displays metadata information
%   about the entire HD5 file stored at a remote location.
%
%   When reading data from remote locations, you must
%   specify the full path using a uniform resource locator (URL).
%   For example, to read a dataset in an HDF5 file from Amazon S3
%   cloud specify the full URL for the file:
%       s3://bucketname/path_to_file/example.h5
%   For more information on accessing remote data, see "Work with Remote Data"
%   in the documentation.
%
%   Example:
%       h5disp('example.h5');
%
%   Example:  Print metadata for just one data set.
%       h5disp('example.h5','/g4/world');
%
%   Example:  Print metadata for an h5 file in Amazon S3.
%       h5disp('s3://bucketname/path_to_file/example.h5');
%
%   See also H5INFO.

%   Copyright 2010-2024 The MathWorks, Inc.

if nargin > 0
    filename = convertStringsToChars(filename);
end

if nargin > 1
    [varargin{:}] = convertStringsToChars(varargin{:});
end

narginchk(1, 5);

options.Filename = filename;
switch(nargin)
    case 1
        options.Location = '/';
        options.Mode = 'simple';
        options.UseUtf8 = false;

    case 2
        options.Location = varargin{1};
        options.Mode = 'simple';
        options.UseUtf8 = false;

    case 3
        % This indicates that either of the following calls are possible:
        % h5disp(filename, location, mode) OR
        % h5disp(filename, 'Name', 'Value')
        % This logic needs to be revisited.
        try
            options.Location = '/';
            options.Mode = 'simple';
            options.UseUtf8 = matlab.io.internal.imagesci.h5ParseEncoding(varargin);
        catch ME
            if strcmpi(varargin{1}, 'TextEncoding')
                throw(ME);
            end
            options.Location = varargin{1};
            options.Mode = varargin{2};
            options.UseUtf8 = false;
        end

    case 4
        options.Location = varargin{1};
        options.Mode = 'simple';
        varargin = varargin(end-1:end);
        options.UseUtf8 = matlab.io.internal.imagesci.h5ParseEncoding(varargin);

    case 5
        options.Location = varargin{1};
        options.Mode = varargin{2};
        varargin = varargin(end-1:end);
        options.UseUtf8 = matlab.io.internal.imagesci.h5ParseEncoding(varargin);
end

if (nargin == 2) && (options.Location(1) ~= '/')
    error(message('MATLAB:imagesci:h5disp:notFullPathName'));
end

validateattributes( options.Filename, {'char', 'string'}, ...
    {'nonempty', 'scalartext'},'h5disp','FILENAME' );
validateattributes( options.Location, {'char', 'string'}, ...
    {'nonempty', 'scalartext'},'h5disp','LOCATION' );

options.Mode = validatestring(options.Mode,{'simple','min'});

% construct the display string
dispTxt = matlab.io.internal.imagesci.HDF5DisplayUtils.displayHDF5(options);

% print the constructed display string
% (using %s ensures the string is printed as-is)
fprintf("%s", dispTxt)

