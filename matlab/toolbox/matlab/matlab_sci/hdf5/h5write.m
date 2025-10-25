function h5write(Filename,Dataset,Data,varargin)
%H5WRITE Write to HDF5 dataset.  
%   H5WRITE(FILENAME,DATASETNAME,DATA) writes to an entire dataset. 
%
%   H5WRITE(FILENAME,DATASETNAME,DATA,START,COUNT) writes a subset of
%   data.  START is the index of the first element to be written and is
%   one-based.  COUNT defines how many elements to write along each
%   dimension.  An extendible dataset will be extended along any unlimited
%   dimensions if necessary.
%
%   H5WRITE(FILENAME,DATASETNAME,DATA,START,COUNT,STRIDE) writes a
%   hyperslab of data.  STRIDE is the inter-element spacing along each
%   dimension.   STRIDE always defaults to a vector of ones if not
%   supplied.  
%
%   H5WRITE(URL,DATASETNAME,DATA) writes to an entire dataset to an HDF5
%   file at a remote location. 
%
%   H5WRITE(URL,DATASETNAME,DATA,START,COUNT) writes a subset of
%   data to an HDF5 file at a remote location.
%
%   H5WRITE(URL,DATASETNAME,DATA,START,COUNT,STRIDE) writes a
%   hyperslab of data to an HDF5 file at a remote location.
%
%   When writing data to remote locations, you
%   must specify the full path using a uniform resource locator
%   (URL). For example, to write a data set to an HDF5 file from
%   Amazon S3 cloud specify the full URL for the file:
%       s3://bucketname/path_to_file/example.h5
%   For more information on accessing remote data, see "Work with Remote Data"
%   in the documentation.
%
%   Only floating point and integer datasets are supported.  To write to
%   string datasets, you must use the H5D package.
%
%   Example:  Write to an entire dataset.
%       h5create('myfile.h5','/DS1',[10 20]);
%       h5disp('myfile.h5');
%       mydata = rand(10,20);
%       h5write('myfile.h5', '/DS1', mydata);
%
%   Example:  Write a hyperslab to the last 5-by-7 block of a dataset.
%       h5create('myfile.h5','/DS2',[10 20]);
%       h5disp('myfile.h5');
%       mydata = rand(5,7);
%       h5write('myfile.h5','/DS2',mydata,[6 14],[5 7]);
%
%   Example:  Append to an unlimited dataset.
%       h5create('myfile.h5','/DS3',[20 Inf],'ChunkSize',[5 5]);
%       h5disp('myfile.h5');
%       for j = 1:10
%            data = j*ones(20,1);
%            start = [1 j];
%            count = [20 1];
%            h5write('myfile.h5','/DS3',data,start,count);
%       end
%       h5disp('myfile.h5');
%
%   Example:  Write to an entire dataset in an h5 file in Amazon S3
%       h5create('s3://bucketname/path_to_file/myfile.h5','/DS1',[10 20]);
%       h5disp('s3://bucketname/path_to_file/myfile.h5');
%       mydata = rand(10,20);
%       h5write('s3://bucketname/path_to_file/myfile.h5', '/DS1', mydata);
%   
%   See also H5CREATE, H5DISP, H5READ, H5WRITEATT, H5D.create, H5D.write.

%   Copyright 2010-2023 The MathWorks, Inc.

if nargin > 0
    Filename = convertStringsToChars(Filename);
end

if nargin > 1
    Dataset = convertStringsToChars(Dataset);
end

% Convert cellstrs to strings
if iscellstr(Data)
    Data = string(Data);
end

p = inputParser;
p.addRequired('Filename', ...
    @(x)validateattributes(x,{'char', 'string'},{'nonempty', 'scalartext'},'','FILENAME'));
p.addRequired('Dataset', ...
    @(x)validateattributes(x,{'char', 'string'},{'nonempty', 'scalartext'},'','DATASETNAME'));
p.addRequired('Data', ...
    @(x)validateattributes(x,{'numeric', 'string'},{'nonempty'},'','DATA'));
p.addOptional('start',[], ...
    @(x)validateattributes(x,{'double'},{'row','positive'},'','START'));
p.addOptional('count',[], ...
    @(x)validateattributes(x,{'double'},{'row','positive'},'','COUNT'));
p.addOptional('stride',[], ...
    @(x)validateattributes(x,{'double'},{'row','positive'},'','STRIDE'));

p.parse(Filename,Dataset,Data,varargin{:});



flags = 'H5F_ACC_RDWR';
fapl = 'H5P_DEFAULT';
dapl = 'H5P_DEFAULT';
dxpl = 'H5P_DEFAULT';



try
    file_id    = H5F.open(Filename,flags,fapl);
catch me
    if ~exist(Filename,'file')
        error(message('MATLAB:imagesci:h5write:fileDoesNotExist', Filename, Dataset));   
    elseif ~H5F.is_hdf5(Filename)
        error(message('MATLAB:imagesci:h5write:notHDF5', Filename));
    else
        rethrow(me);
    end
end


if Dataset(1) ~= '/'
    error(message('MATLAB:imagesci:h5write:notFullPathName'));
end
try
    dataset_id = H5D.open(file_id,Dataset,dapl);
catch me
    error(message('MATLAB:imagesci:h5write:datasetDoesNotExist', Dataset));
end

space_id   = H5D.get_space(dataset_id);

if isempty(p.Results.start)
    
    % Assumption is that we are writing to the entire dataset.
    % We can supply these default memory and file space identifiers.
    memspace_id = 'H5S_ALL';
    filespace_id = 'H5S_ALL';
    
    % Get the dataset dimensions
    [ndims,dims] = H5S.get_simple_extent_dims(space_id);
    dims = fliplr(dims);

    % Check if there's at least one unlimited dimension. In this case,
    % prod(dims) will be zero. If so, issue error to specify start and count 
    % (and optionally stride) to write data.
    if prod(dims) == 0
        error(message('MATLAB:imagesci:h5write:unlimMissingStartCount'));
    end

    % Verify that the size of the data matches up with the size advertized
    % by the file's dataset.
    if numel(Data) ~= prod(dims)
        error(message('MATLAB:imagesci:h5write:fullDatasetDataMismatch'));
    end
    
    if ndims > 1
        % 1D datasets get a free pass.
        sz = size(Data);
        % Ignore any trailing singleton dimensions.
        if any(sz - dims(1:numel(sz)))
            error(message('MATLAB:imagesci:h5write:fullDatasetDimsMismatch'));
        end
    end

else  
    % Case of partial write.  We need to create specific file and
    % memory space identifiers.
    [offset,count,stride] = determine_indexing(space_id,p.Results); 
    [filespace_id, Data]  = get_filespace(dataset_id,offset,count,stride,Data);
    count = size(Data);
    memspace_id           = H5S.create_simple(numel(count),fliplr(count),[]);
end




H5D.write(dataset_id,'H5ML_DEFAULT',memspace_id,filespace_id,dxpl,Data);

end







%--------------------------------------------------------------------------
function [offset,count,stride] = determine_indexing(space_id,options)
% This function determines how the hyperslab is to be set up.


[offset,count,stride] = deal(options.start,options.count,options.stride);


% Make sure that the lengths of the index arguments make sense.
if (numel(offset) ~= numel(count)) ...
        || (~isempty(stride) && (numel(count) ~= numel(stride)))
    error(message('MATLAB:imagesci:h5write:invalidSubsetting'));
end


ndims = H5S.get_simple_extent_ndims(space_id);

sz = size(options.Data);
% Check the length of the size vector against the rank of the dataset's
% dataspace.  If the size vector lags, it is probably because of trailing
% singletons that MATLAB automatically trims.  We want to augment the size
% vector in that case.
if numel(sz) < ndims
    sz = [sz ones(1,(ndims-numel(sz)))];
end
    
    
if isempty(stride)
    
    % The low-level interface requires zero-based indexing.
    offset = offset-1;
    
    % Supply a default stride.
    stride = ones(1,numel(offset));
    
else
    
    % Stride was provided.
    % The low-level interface requires zero-based indexing.
    offset = offset-1;    
    
end

% Special error checking if START and COUNT are provided.
if (numel(options.Data) ~= prod(count))
    error(message('MATLAB:imagesci:h5write:datasetCountMismatch'));
end
if ndims > 1
    if any(sz - count)     
        error(message('MATLAB:imagesci:h5write:datasetDimsMismatch'));
    end
end


end


%--------------------------------------------------------------------------
function [filespace_id, Data] = get_filespace(dataset_id,start,count,stride,Data)


filespace_id = H5D.get_space(dataset_id);

dcpl = H5D.get_create_plist(dataset_id);
layout =  H5P.get_layout(dcpl);
% Determine is space has been allocated for the dataset. Returns 0 if not
% allocated.
space_status = H5D.get_space_status(dataset_id);

% Get the size of the dataset so we know if we have to extend it.
[~, spaceDims,maxDims] = H5S.get_simple_extent_dims(filespace_id);
spaceDims = fliplr(spaceDims);
maxDims = fliplr(maxDims);

boundsEnd = start + (count-1).*stride;
numDims = numel(start);

% Special case: When the conditions below are true, it is more efficient to
% generate the full data/array in MATLAB (by suplementing the provided
% hyperslab with the fill value) and write it whole instead of writing
% using hyperslabs
% 1. The number of elements touched (note: not written) along each
% dimension has to be close to the size of the dataset but the
% written elements shouldn't be too sparse either. In this case, we are
% using an empirical value of 95% as the number of elements that would have
% to be calculated and the condition of sparseness can be
% handled with stride being less than 8.
% 2. The dataset is being written to for the first time, else there is risk
% of unintended overwriting of data. We use H5D.get_space_status to
% determine if space has been allocated for the dataset.
% 3. The dataset layout is chunked.
% 4. All the stride values are <= 8 
writeFullData = (all(((count.*stride) ./ spaceDims) >= 0.95)) && (all(stride <= 8)) && ...
    (space_status == H5ML.get_constant_value('H5D_SPACE_STATUS_NOT_ALLOCATED'))...
    && (layout == H5ML.get_constant_value('H5D_CHUNKED'));

if writeFullData
    % Start and end indices of the array for MATLAB. 1 based start
    % to be used for generating the non hyperslabed dataset
    arrayStart = start + 1; % MATLAB indexing
    arrayEnd = arrayStart + (count-1).*stride;
    typeID = H5D.get_type(dataset_id);
    % Get the fill value for the dataset
    fillValue = H5P.get_fill_value(dcpl,typeID);
    % Datatype of the MATLAB data
    dtype = class(Data); 
    % Calculate the dimensions of the data to be written.
    % The length of the data to be written along any dimension is spaceDims
    % or arrayEnd (whichever is greater)
    spaceDimExceedsArrayEnd = (spaceDims > arrayEnd);
    dataSize = (spaceDimExceedsArrayEnd.*spaceDims) + ((~spaceDimExceedsArrayEnd).*arrayEnd);

    
    try
        % Preallocate with the fill value
        if isscalar(arrayStart)
            DataWithoutHyperslab = ones([1, dataSize], dtype)*fillValue;
        else
            DataWithoutHyperslab = ones(dataSize, dtype)*fillValue;
        end
    
        indexingExprs = cell(1, numDims);
        % Index into the complete array to correctly fill in the provided
        % hyperslabed data (leaving the rest as fill values)
        for dim = 1:numDims
            indexingExprs{dim} = arrayStart(dim):stride(dim):arrayEnd(dim);
        end
        DataWithoutHyperslab(indexingExprs{:}) = Data;
        Data = DataWithoutHyperslab;
    catch
        % If there are any out of memory or other errors while creating the
        % DataNoHyperslab variable, we revert back to the hyperslab writing
        % In this case, 'Data' would not be modified
        writeFullData = false;
        
    end    

end

% Do any of the bounding box dimensions exceed the current dimensions
% of the dataset?
dataset_extents_exceeded = (boundsEnd > (spaceDims-1));
if  any(dataset_extents_exceeded)
    filespace_id = extendFilespace(filespace_id, dataset_id, spaceDims, maxDims, boundsEnd);    
end

% For Hyperslab selection
if ~writeFullData
    H5S.select_hyperslab(filespace_id, 'H5S_SELECT_SET', ...
                     fliplr(start), fliplr(stride), ...
                     fliplr(count), ones(1,numDims));
end

end

function filespace_id = extendFilespace(filespace_id, dataset_id, spaceDims, maxDims, boundsEnd)

% The hyperslab selection does exceed the current dataset size, so now
% we need to figure out if we can extend.
extend_idx = (boundsEnd > (spaceDims-1));
if any(maxDims(extend_idx)>-1)
    H5S.close(filespace_id);
    error(message('MATLAB:imagesci:h5write:cannotExtend', H5I.get_name( dataset_id ), H5I.get_name( dataset_id )));
end

% Figure out the new dimensions, extend the dataset, and return the new
% space ID after selecting the hyperslab.
new_dims = max(spaceDims,boundsEnd+1);
H5S.close(filespace_id);
H5D.extend(dataset_id,fliplr(new_dims));


% Retrieve the new file space ID and make the hyperslab selection.
filespace_id = H5D.get_space(dataset_id);

end

