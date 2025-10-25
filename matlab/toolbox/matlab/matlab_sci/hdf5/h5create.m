function h5create(Filename,Dataset,Size,varargin)
%H5CREATE  Create HDF5 dataset.
%   H5CREATE(FILENAME,DATASETNAME,SIZE,Param1,Value1, ...) creates an HDF5
%   dataset with name DATASETNAME and with extents given by SIZE in the
%   file given by FILENAME.  If DATASETNAME is a full path name, all
%   intermediate groups are created if they don't already exist.  If
%   FILENAME does not already exist, it is created.
%
%   H5CREATE(URL,DATASETNAME,SIZE,Param1,Value1, ...) creates an HDF5
%   dataset with name DATASETNAME in an HDF5 file at a remote location and
%   with extents given by SIZE in the file given by FILENAME. When writing
%   data to remote locations, you must specify the full path using a
%   uniform resource locator (URL). For example, to write a data set to an
%   HDF5 file in Amazon S3 cloud specify the full URL for the file:
%       s3://bucketname/path_to_file/example.h5
%   For more information on accessing remote data, see "Work with Remote Data"
%   in the documentation.
%
%   Elements of SIZE should be Inf in order to specify an unlimited extent.
%
%   Parameter Value Pairs
%   ---------------------
%       'Datatype'               - May be one of 'double', 'single', 'uint64',
%                                  'int64', 'uint32', 'int32', 'uint16', 'int16',  
%                                  'uint8', 'int8', or 'string'  Defaults to 'double'.
%       'ChunkSize'              - Defines chunking layout. Default is not chunked.
%       'Deflate'                - Defines gzip compression level (0-9). Default is 
%                                  no compression.
%       'SZIPEncodingMethod'     - Defines the encoding method for SZIP compression.
%                                  Valid values are 'entropy' for entropy encoding,
%                                  'nearestneighbor' for nearest neighbor encoding,
%                                  or 'none' for no compression. Default value is
%                                  'none'.
%        SZIPPixelsPerBlock      - Defines the maximum value for the number of pixels
%                                  (HDF5 data elements) in each data block for SZIP
%                                  compression. This value must be even, greater than
%                                  zero, and less than or equal to 32; typical values
%                                  are 8, 10, 16, or 32. This parameter affects compression
%                                  ratio - the more pixel values vary, the smaller this
%                                  number should be to achieve better performance.
%                                  If SZIPEncodingMethod is specified as 'entropy' or
%                                  'nearestneighbor' but SZIPPixelsPerBlock is not
%                                  specified, h5create will use the SZIP default value
%                                  of 16 for SZIPPixelsPerBlock.
%       'FillValue'              - Defines the fill value for numeric datasets. Not
%                                  supported for 'string' datatype.
%       'Fletcher32'             - Turns on the Fletcher32 checksum filter. Default 
%                                  value is false.
%       'Shuffle'                - Turns on the Shuffle filter. Default value is
%                                  false.
%       'CustomFilterID'         - Defines filter id for third-party filter plugin.
%                                  Default value is empty indicating no filter.
%       'CustomFilterParameters' - Defines auxiliary data for third-party
%                                  filter plugin. Default value is empty
%                                  indicating no data.
%       'TextEncoding'           - Defines the character encoding to be used for the
%                                  dataset name. It takes values 'system' or 'UTF-8'.
%                                  Default value is 'UTF-8'. 
%
%   Example:  create a fixed-size 100x200 dataset.
%       h5create('myfile.h5','/myDataset1',[100 200]);
%       h5disp('myfile.h5');
%
%   Example:  create a single precision 1000x2000 dataset with a chunk size
%   of 50x80.  Apply the highest level of compression possible.
%       h5create('myfile.h5','/myDataset2',[1000 2000], 'Datatype','single', ...
%                'ChunkSize',[50 80],'Deflate',9);
%       h5disp('myfile.h5');
%
%   Example:  create a two-dimensional dataset that is unlimited along the
%   second extent.
%       h5create('myfile.h5','/myDataset3',[200 Inf],'ChunkSize',[20 20]);
%       h5disp('myfile.h5');
%
%   Example:  create a fixed-size 100x200 dataset in an h5 file in Amazon
%   S3
%       h5create('s3://bucketname/path_to_file/myfile.h5','/myDataset1',[100 200]);
%       h5disp('s3://bucketname/path_to_file/myfile.h5');
%   See also:  h5read, h5write, h5info, h5disp.

%   Copyright 2010-2024 The MathWorks, Inc.


if nargin > 0
    Filename = convertStringsToChars(Filename);
end

if nargin > 1
    Dataset = convertStringsToChars(Dataset);
end

if nargin > 3
    [varargin{:}] = convertStringsToChars(varargin{:});
end

p = inputParser;
p.addRequired('Filename', ...
    @(x) validateattributes(x,{'char', 'string'},{'nonempty', 'scalartext'},'','FILENAME'));
p.addRequired('Dataset', ...
    @(x) validateattributes(x,{'char', 'string'},{'nonempty', 'scalartext'},'','DATASET'));
p.addRequired('Size', ...
    @(x) validateattributes(x,{'double'},{'row','nonnegative'},'','SIZE'));
p.addParameter('Datatype','double', ...
    @(x) validateattributes(x,{'char', 'string'},{'nonempty', 'scalartext'},'','DATATYPE'));
p.addParameter('ChunkSize', [], ...
    @(x) validateattributes(x,{'double'},{'row','finite','nonnegative'},'','CHUNKSIZE'));
p.addParameter('Deflate', [], ...
    @(x) validateattributes(x,{'double'},{'scalar','nonnegative','<=',9},'','DEFLATE'));                                     
p.addParameter('SZIPEncodingMethod','none', ...
    @(x) validateattributes(x,{'char','string'},{'nonempty','scalartext'},'','SZIPENCODINGMETHOD'));
p.addParameter('SZIPPixelsPerBlock',[], ...
    @(x) validateattributes(x,{'numeric'},{'integer','scalar','positive','even','<=',32}, ...
    '','SZIPPIXELSPERBLOCK'));
p.addParameter('FillValue',[], ...
    @(x) validateattributes(x,{'numeric'},{'scalar'},'','FILLVALUE'));
p.addParameter('Fletcher32',false, ...
    @(x) validateattributes(x,{'double','logical'},{'scalar'},'','FLETCHER32'));
p.addParameter('Shuffle',false, ...
    @(x) validateattributes(x,{'double','logical'},{'scalar'},'','FLETCHER32'));
p.addParameter('CustomFilterID',[], ...
    @(x) validateattributes(x,{'numeric'},{'integer','scalar','nonnegative'},'','CUSTOMFILTERID'));
p.addParameter('CustomFilterParameters',[], ...
    @(x) validateattributes(x,{'numeric'},{'vector'},'','CUSTOMFILTERPARAMETERS'));
p.addParameter('TextEncoding', 'UTF-8', ...
    @(x) ismember(lower(x), {'system', 'utf-8'}));

p.parse(Filename,Dataset,Size,varargin{:});

options.SZIPEncodingMethod = validatestring(p.Results.SZIPEncodingMethod, ...
    {'entropy','nearestneighbor','none'},'','SZIPENCODINGMETHOD');

options = validate_options(p.Results);
create_dataset(options);

return


%--------------------------------------------------------------------------
function options = validate_options(options)

% h5create creates string datatypes as HDF5 variable-length strings. Since
% HDF5 does not support variable-length types with third-party filters,
% combining custom filter with string datatype throws an HDF5 error. 
% So in this case, give a more user-friendly error.
if ~isempty(options.CustomFilterID) && isequal(options.Datatype,'string') 
    error(message('MATLAB:imagesci:h5create:vlenStringsNotSupported'));
end

% Applying compression to a dataset requires said dataset to be chunked.
% If compression is selected but not chunk size, give a better error message 
% than the low-level library would.
if (~isempty(options.Deflate) || ~strcmpi(options.SZIPEncodingMethod,'none') || ...
    ~isempty(options.CustomFilterID)) && isempty(options.ChunkSize)
    error(message('MATLAB:imagesci:h5create:filterRequiresChunking'));
end

% If both deflate and SZIP compression are specified, issue error that this
% combination of compression filters is not allowed in h5create, but can
% be set via our low-level functions. 
if ~isempty(options.Deflate) && ~strcmpi(options.SZIPEncodingMethod,'none')
    error(message('MATLAB:imagesci:h5create:cannotCombineDeflateAndSZIP'));
end

% If SZIPPixelsPerBlock is specified but not SZIPEncodingMethod, issue error.
if ~isempty(options.SZIPPixelsPerBlock) && strcmpi(options.SZIPEncodingMethod,'none')
    error(message('MATLAB:imagesci:h5create:SZIPEncodingMethodNotSpecified'));
end

% If custom filter parameters are specified without a custom filter id, issue error.
if isempty(options.CustomFilterID) && ~isempty(options.CustomFilterParameters)
    error(message('MATLAB:imagesci:h5create:filterParamsRequiresFilterID'));
end

% Setup Extendable.
options.Extendable = false(1,numel(options.Size));
options.Extendable(isinf(options.Size)) = true;
options.Extendable(options.Size == 0) = true;

% Force Shuffle and Fletcher32 options to be logical.
if isnumeric(options.Fletcher32)
    options.Fletcher32 = logical(options.Fletcher32);
end  
if isnumeric(options.Shuffle)
    options.Shuffle = logical(options.Shuffle);
end  
if (options.Fletcher32 || options.Shuffle) && isempty(options.ChunkSize)
     error(message('MATLAB:imagesci:h5create:filterRequiresChunking')); 
end
  
if ~isempty(options.FillValue) && ~strcmp(options.Datatype,class(options.FillValue))
    error(message('MATLAB:imagesci:h5create:datasetFillValueMismatch', class( options.FillValue ), options.Datatype));
end

% Make sure that chunk size does not exceed dataset size.  After that,
% reset any Infs to zero before continuing.  The initial size of an
% unlimited extent must be zero to begin with.

if ~isempty(options.ChunkSize)
    if numel(options.ChunkSize) ~= numel(options.Size)
        error(message('MATLAB:imagesci:h5create:chunkSizeDatasetSizeMismatch'));
    end
    if any((options.ChunkSize - options.Size) > 0)
        error(message('MATLAB:imagesci:h5create:chunkSizeLargerThanDataset'));
    end
end
options.Size(isinf(options.Size)) = 0;

if ( ~isempty(options.Extendable) ) 
    if any(options.Extendable) && isempty(options.ChunkSize)
        error(message('MATLAB:imagesci:h5create:extendibleRequiresChunking'));   
    end
end

% Obtain the full path to the file before calling "exist" so that "exist" 
% only returns true if there is an existing file at the intended write
% location
if ~matlab.io.internal.vfs.validators.hasIriPrefix(options.Filename)
    [pathstr, filename, ext] = fileparts(options.Filename);
    if isempty(pathstr)
        pathstr = pwd;
    end
    options.Filename = fullfile(pathstr, [filename, ext]);
    % If the file exists, check that it is an HDF5 file.
    
    if exist(options.Filename,'file')
        if ~H5F.is_hdf5(options.Filename)
            error(message('MATLAB:imagesci:h5create:notHDF5', options.Filename));
        end
    end
end

if options.Dataset(1) ~= '/'
    error(message('MATLAB:imagesci:h5create:notFullPathName'));
end

%--------------------------------------------------------------------------
function create_dataset(options)

if exist(options.Filename,'file')
    fid = H5F.open(options.Filename,'H5F_ACC_RDWR','H5P_DEFAULT');
    file_was_created = false;
else
    fid = H5F.create(options.Filename,'H5F_ACC_TRUNC','H5P_DEFAULT', ...
        'H5P_DEFAULT');
    file_was_created = true;
end

% Does the dataset already exist?
try
    dset = H5D.open(fid, options.Dataset);
    H5D.close(dset);
    error(message('MATLAB:imagesci:h5create:datasetAlreadyExists', options.Dataset));
catch me
    if strcmp(me.identifier,'MATLAB:imagesci:h5create:datasetAlreadyExists')
        rethrow(me)
    end
end

try
    
    switch(options.Datatype)
        case 'double'
            datatype = 'H5T_NATIVE_DOUBLE';
        case 'single'
            datatype = 'H5T_NATIVE_FLOAT';
        case 'uint64'
            datatype = 'H5T_NATIVE_UINT64';
        case 'int64'
            datatype = 'H5T_NATIVE_INT64';
        case 'uint32'
            datatype = 'H5T_NATIVE_UINT';
        case 'int32'
            datatype = 'H5T_NATIVE_INT';
        case 'uint16'
            datatype = 'H5T_NATIVE_USHORT';
        case 'int16'
            datatype = 'H5T_NATIVE_SHORT';
        case 'uint8'
            datatype = 'H5T_NATIVE_UCHAR';
        case 'int8'
            datatype = 'H5T_NATIVE_CHAR';
        case 'string'
            datatype = H5T.copy('H5T_C_S1');
            H5T.set_cset(datatype, H5ML.get_constant_value('H5T_CSET_UTF8'));
            H5T.set_size(datatype, 'H5T_VARIABLE');
            H5T.set_strpad(datatype,'H5T_STR_NULLTERM');
        otherwise
            error(message('MATLAB:imagesci:h5create:unrecognizedDatatypeString', options.Datatype));
    end
    
    % Set the maxdims parameter to take into account any extendable
    % dimensions.
    maxdims = options.Size;
    if any(options.Extendable)
        unlimited = H5ML.get_constant_value('H5S_UNLIMITED');
        maxdims(options.Extendable) = unlimited;
    end
    
    % Create the dataspace.
    space_id = H5S.create_simple(numel(options.Size), ...
            fliplr(options.Size), fliplr(maxdims));
    cspace_id = onCleanup(@()H5S.close(space_id));
    
    lcpl = H5P.create('H5P_LINK_CREATE');
    clcpl = onCleanup(@()H5P.close(lcpl));
    
    if strcmpi(options.TextEncoding, 'UTF-8')
        H5P.set_char_encoding(lcpl, H5ML.get_constant_value('H5T_CSET_UTF8'));
        % When using UTF-8 names, the HDF5 library appears to create the
        % intermediate groups with their link encoding to be ASCII. Only
        % the final link to the dataset is marked as UTF-8. Hence, all the
        % groups that are not present have to be created manually.
        create_intermediate_groups_for_utf8(fid, lcpl, options.Dataset);
    else
        % If the dataset is buried a few groups down, then we want to create 
        % all intermediate groups.
        H5P.set_create_intermediate_group(lcpl,1);
    end
    
    dcpl = construct_dataset_creation_property_list(options);
    cdcpl = onCleanup(@()H5P.close(dcpl));
    dapl = 'H5P_DEFAULT';
    
    dset_id = H5D.create(fid,options.Dataset,datatype,space_id,lcpl,dcpl,dapl);
    
catch me
    H5F.close(fid);
    if file_was_created
        delete(options.Filename);
    end
    rethrow(me);       
end

H5D.close(dset_id);
return

%--------------------------------------------------------------------------
function dcpl = construct_dataset_creation_property_list(options)
% Setup the DCPL - dataset create property list.

dcpl = H5P.create('H5P_DATASET_CREATE');

% Modify the dataset creation property list for the shuffle filter if
% so ordered.
if options.Shuffle
    H5P.set_shuffle(dcpl);
end

% Modify the dataset creation property list for possible chunking and
% deflation.
if ~isempty(options.ChunkSize)
    H5P.set_chunk(dcpl,fliplr(options.ChunkSize));
end

if ~isempty(options.Deflate)
    H5P.set_deflate(dcpl,options.Deflate);
end

% Modify the dataset creation property list for SZIP compression if defined.
if ~strcmpi(options.SZIPEncodingMethod,'none')
    if strcmpi(options.SZIPEncodingMethod,'entropy')
        encodingMethod = H5ML.get_constant_value('H5_SZIP_EC_OPTION_MASK');    
    else
        encodingMethod = H5ML.get_constant_value('H5_SZIP_NN_OPTION_MASK');    
    end

    % If SZIPPixelsPerBlock was specified, use specified value. Otherwise
    % use SZIP default value of 16.
    if isempty(options.SZIPPixelsPerBlock)
        options.SZIPPixelsPerBlock = 16; % default value
    end

    % Ensure SZIPPixelsPerBlock is not greater than total number of elements in
    % the dataset chunk. If it is, throw a nicer error than the HDF5 library does.
    numElemInChunk = prod(options.ChunkSize(:));
    if options.SZIPPixelsPerBlock > numElemInChunk
        error(message('MATLAB:imagesci:h5create:SZIPPixelsPerBlockTooLarge',...
            options.SZIPPixelsPerBlock,numElemInChunk));
    end
         
    H5P.set_szip(dcpl,encodingMethod,options.SZIPPixelsPerBlock);
end

% Modify the dataset creation property list for a possible fill value.
if ~isempty(options.FillValue)
    switch(options.Datatype)
        case 'double'
            filltype = 'H5T_NATIVE_DOUBLE';
            fv = double(options.FillValue);
        case 'single'
            filltype = 'H5T_NATIVE_FLOAT';
            fv = single(options.FillValue);
        case 'uint64'
            filltype = 'H5T_NATIVE_UINT64';
            fv = uint64(options.FillValue);
        case 'int64'
            filltype = 'H5T_NATIVE_INT64';
            fv = int64(options.FillValue);
        case 'uint32'
            filltype = 'H5T_NATIVE_UINT';
            fv = uint32(options.FillValue);
        case 'int32'
            filltype = 'H5T_NATIVE_INT';
            fv = int32(options.FillValue);
        case 'uint16'
            filltype = 'H5T_NATIVE_USHORT';
            fv = uint16(options.FillValue);
        case 'int16'
            filltype = 'H5T_NATIVE_SHORT';
            fv = int16(options.FillValue);
        case 'uint8'
            filltype = 'H5T_NATIVE_UCHAR';
            fv = uint8(options.FillValue);
        case 'int8'
            filltype = 'H5T_NATIVE_CHAR';
            fv = int8(options.FillValue);
        otherwise
            H5P.close(dcpl);
            error(message('MATLAB:imagesci:h5create:badFillValueType'));
    end
    H5P.set_alloc_time(dcpl,'H5D_ALLOC_TIME_EARLY');
    H5P.set_fill_value(dcpl,filltype,fv);
end

% Modify the dataset creation property list for the fletcher32 filter if
% so ordered.
if options.Fletcher32
    H5P.set_fletcher32(dcpl);
end

% Modify the dataset creation property list if custom third-party filter
% is defined. 
if options.CustomFilterID
    % Set the filter flags argument to H5Z_FLAG_OPTIONAL for use with
    % h5create (this is best practice for use with compression filters
    % per The HDF Group).  Low-level function H5P.set_filter can be used
    % to set the filter flag to H5Z_FLAG_OPTIONAL or H5Z_FLAG_MANDATORY.
    % H5Z_FLAG_OPTIONAL instructs the HDF5 library to not error out if
    % it encounters a filter failure during compression.  The data will
    % still be written during the subsequent write operation, just not
    % compressed for the chunk(s) where a filter failure occurred.
    H5P.set_filter(dcpl,options.CustomFilterID,'H5Z_FLAG_OPTIONAL',...
        options.CustomFilterParameters); 
end

%--------------------------------------------------------------------------
function create_intermediate_groups_for_utf8(fid, lcpl_id, full_dataset_name)

split_locs = strfind(full_dataset_name, '/');

% If the dataset is being created in the root group, then the full group
% name is '/'
if split_locs(end) == 1
    full_group_name = full_dataset_name(1);
else
    full_group_name = full_dataset_name(1:split_locs(end)-1);
end

% Determine the groups that are already present in the file
already_present_groups = get_already_present_groups(fid, full_group_name);

% Determine the groups that are not present and must be created
groups_to_create = extractAfter(full_group_name, already_present_groups);
if strlength(groups_to_create) == 0
    return;
end

% Prevent strsplit from returning an empty string for leading delimiter
if groups_to_create(1) == '/'
    groups_to_create(1)= '';
end

groups_to_create = cellstr(strsplit(groups_to_create, '/'));

% Now create the groups that are not present, one at a time
for cnt = 1:numel(groups_to_create)
    gid_already_present = H5G.open(fid, already_present_groups);
    gid = H5G.create(gid_already_present, groups_to_create{cnt}, lcpl_id, 'H5P_DEFAULT', 'H5P_DEFAULT');
    H5G.close(gid);
    H5G.close(gid_already_present);
    if already_present_groups(end) == '/'
        already_present_groups(end) = '';
    end
    % Append the group created to the list of already present ones and use
    % this name in the next iteration.
    already_present_groups = [already_present_groups '/' groups_to_create{cnt}];
end

function group_name = get_already_present_groups(fid, full_group_name)

try
    % If the group creation succeeds, return the group name.
    gid = H5G.open(fid, full_group_name);
    gid_oc = onCleanup( @()H5G.close(gid) );
    
    group_name = full_group_name;
    return;
catch ME
    % If the group creation fails, then strip off the lowest group and then
    % try again until a successful group can be created or until the root
    % group is reached.
    split_locs = strfind(full_group_name, '/');
    if numel(split_locs) == 1 && split_locs(1) == 1
        group_name = '/';
        return;
    end
    full_group_name = full_group_name(1:split_locs(end)-1);
    group_name = get_already_present_groups(fid, full_group_name);
    return;
end
