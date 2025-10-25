function data = h5read(Filename,Dataset,start,count,stride)
%H5READ  Read data from HDF5 dataset.
%   DATA = H5READ(FILENAME,DATASETNAME) retrieves all of the data from the
%   HDF5 dataset DATASETNAME in the file FILENAME.
%
%   DATA = H5READ(FILENAME,DATASETNAME,START,COUNT) reads a subset of
%   data.  START is the one-based index of the first element to be read.
%   COUNT defines how many elements to read along each dimension.  If a
%   particular element of COUNT is Inf, data is read until the end of the
%   corresponding dimension.
%
%   DATA = H5READ(FILENAME,DATASETNAME,START,COUNT,STRIDE) reads a
%   strided subset of data.  STRIDE is the inter-element spacing along each
%   data set extent and defaults to one along each extent.
%
%   DATA = H5READ(URL,DATASETNAME) retrieves all of the data from the
%   HDF5 dataset DATASETNAME from an HDF5 file at a remote location.
%
%   DATA = H5READ(URL,DATASETNAME,START,COUNT) reads a subset of
%   data from an HDF5 file at a remote location.
%
%   DATA = H5READ(URL,DATASETNAME,START,COUNT,STRIDE) reads a
%   strided subset of data from an HDF5 file at a remote location.
%
%   When reading data from remote locations, you must specify the full path
%   using aa uniform resource locator (URL). For example, to
%   read a dataset in an HDF5 file from Amazon S3 cloud specify the full
%   URL for the file:
%       s3://bucketname/path_to_file/example.h5
%   For more information on accessing remote data, see "Work with Remote Data"
%   in the documentation.
%
% 
%   Example: Read an entire data set.
%       h5disp('example.h5','/g4/lat');
%       data = h5read('example.h5','/g4/lat');
%
%   Example:  Read the first 5-by-3 subset of a data set.
%       h5disp('example.h5','/g4/world');
%       data = h5read('example.h5','/g4/world',[1 1],[5 3]);
%
%   Example:  Read a data set of references to other datasets.
%       h5disp('example.h5','/g3/reference');
%       data = h5read('example.h5','/g3/reference');
%
%   Example: Read a datasat from an h5 file in Amazon S3.
%       h5disp('s3://bucketname/path_to_file/example.h5','/g4/lat');
%       data = h5read('s3://bucketname/path_to_file/example.h5','/g4/lat');
%       
%
%   See also H5DISP, H5READATT, H5WRITE, H5WRITEATT.

%   Copyright 2010-2024 The MathWorks, Inc.

if nargin > 0
    Filename = convertStringsToChars(Filename);
end

if nargin > 1
    Dataset = convertStringsToChars(Dataset);
end

switch(nargin)
	case 2
		start = [];
		count = [];
		stride = [];
	case 4
		stride = [];
	case 5    
		%
	otherwise
        error(message('MATLAB:imagesci:validate:wrongNumberOfInputs'));	   
end

validateattributes(Filename,{'char', 'string'},{'nonempty', 'scalartext'},'','FILENAME');
validateattributes(Dataset,{'char', 'string'},{'nonempty', 'scalartext'},'','DATASETNAME');

% Try to get a full pathname.  If FOPEN fails, it may be because we need to
% use the family driver, in which case the filename string does not 
% identify an actual location on disk.

% If the Filename is not a URI, use fopen to get the actual location on
% disk. Otherwise directly pass the Filename as it is.
isRemote = matlab.io.internal.vfs.validators.hasIriPrefix(Filename);
if ~isRemote
    fid = fopen(Filename);
    if fid ~= -1
        Filename = fopen(fid);
        fclose(fid);
    end
end

try
    [data,var_class] = matlab.internal.sci.h5readc(Filename,Dataset,start,count,stride);
catch ME
    if isRemote && ...
            strcmp(ME.identifier, 'MATLAB:imagesci:h5read:fileOpenErr') && ...
            contains(... % content type is HTML (will be empty for non-HTTP links)
            matlab.io.internal.filesystem.getContentType(Filename), "text/html", ...
            IgnoreCase=true)
        % if we are reading a remote HDF5 file from an HTTP link and the
        % content type is HTML, this error is because we are trying to read
        % HTML file as HDF5. This can happen when authentication is
        % required and we get a login page back.
        error(message('MATLAB:imagesci:hdf5io:readHTML', Filename));
    else
        rethrow(ME);
    end
end


% Get some constant values and make them persistent to avoid duplicated 
% mex-calls in subsequent invocations.
persistent H5T_ENUM H5T_OPAQUE H5T_REFERENCE H5T_STRING H5T_INTEGER H5T_FLOAT;
persistent H5S_NULL H5S_SCALAR
if isempty(H5T_ENUM)
    H5T_INTEGER   = H5ML.get_constant_value('H5T_INTEGER');
    H5T_FLOAT     = H5ML.get_constant_value('H5T_FLOAT');
    H5T_ENUM      = H5ML.get_constant_value('H5T_ENUM');
    H5T_OPAQUE    = H5ML.get_constant_value('H5T_OPAQUE');
    H5T_REFERENCE = H5ML.get_constant_value('H5T_REFERENCE');
    H5T_STRING    = H5ML.get_constant_value('H5T_STRING');
    H5S_NULL      = H5ML.get_constant_value('H5S_NULL');
    H5S_SCALAR    = H5ML.get_constant_value('H5S_SCALAR');
end


if (var_class == H5T_INTEGER) || (var_class == H5T_FLOAT)
    % Simplest case. No post processing needs to be done.
    return
end

% retrieve the identifiers needed for post processing.
fid = H5F.open(Filename);
dataset_id = H5D.open(fid,Dataset);
datatype_id = H5D.get_type(dataset_id);
space_id = H5D.get_space(dataset_id);
space_type = H5S.get_simple_extent_type(space_id);

% Construct the memory space needed for post processing.
switch(space_type)
    case {H5S_NULL,H5S_SCALAR}
        memspace = H5S.copy(space_id);

    otherwise 
        if nargin == 2
            memspace = H5D.get_space(dataset_id);
        else
            memspace = H5S.create_simple(numel(start), fliplr(count),fliplr(count));
        end
end

switch var_class
    
    case H5T_ENUM
        data = h5postprocessenums(datatype_id,memspace,data);
      
     case H5T_OPAQUE
        data = h5postprocessopaques(datatype_id,memspace,data);
             
    case H5T_REFERENCE
        data = h5postprocessreferences(dataset_id,memspace,data);
  
    case H5T_STRING
        data = h5postprocessstrings(datatype_id,memspace,data);

end


return
