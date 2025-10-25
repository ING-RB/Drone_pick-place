function [data,info] = cdfread(filename,varargin)
%CDFREAD Read the data from a CDF file.
%   DATA = CDFREAD(FILE) reads all of the variables from each record of
%   FILE.  DATA is a cell array, where each row is a record and each
%   column a variable.  Every piece of data from the CDF file is read
%   and returned.
%
%   Note:  When working with large data files, use of the
%   'CombineRecords' option can significantly improve performance.
%
%   DATA = CDFREAD(FILE,'Records',RECNUMS, ...) reads particular
%   records from a CDF file.  RECNUMS is a vector of one or more
%   zero-based record numbers to read.  DATA is a cell array with
%   length(RECNUM) number of rows.  There are as many columns as
%   variables.
%
%   DATA = CDFREAD(FILE,'Variables',VARNAMES, ...) reads the variables
%   in the cell array VARNAMES from a CDF file.  DATA is a cell array
%   with length(VARNAMES) number of columns.  There is a row for each
%   record requested.
%
%   DATA = CDFREAD(FILE,'Slices',DIMENSIONVALUES, ...) reads specified
%   values from one variable in the CDF file.  The matrix DIMENSIONVALUES
%   is an m-by-3 array of "start", "interval", and "count" values.  The
%   "start" values are zero-based.
%
%   The number of rows in DIMENSIONVALUES must be less than or equal to
%   the number dimensions of the variable.  Unspecified rows are filled
%   with the values [0 1 N] to read every value from those dimensions.
%
%   When using the 'Slices' parameter, only one variable can be read at a
%   time, so the 'Variables' parameter must be used.
%
%   DATA = CDFREAD(FILE,'DatetimeType',DTYPE,...) speficies return type for
%   CDF_EPOCH and CDF_TIME_TT2000 datatypes.  If DTYPE is 'datetime'
%   (the default for CDF_TIME_TT2000), values will be read as datetime.
%   If DTYPE is 'native', CDF_TIME_TT2000 will be read as int64 and
%   CDF_EPOCH will be read as double. 
%
%   DATA = CDFREAD(FILE,'CombineRecords',TF, ...) combines all of the
%   records into a cell array with only one row if TF is true.  Because
%   variables in CDF files can contain nonscalar data, the default value
%   (false) causes the data to be read into an M-by-N cell array, where M
%   is the number of records and N is the number of variables requested.
%
%   When TF is true, all records for each variable are combined into one
%   cell in the output cell array.  The data of scalar variables is
%   imported into a column array.  Importing nonscalar and string data
%   extends the dimensionality of the imported variable.  For example,
%   importing 1000 records of a 1-byte variable with dimensions 20-by-30
%   yields a cell containing a 1000-by-20-by-30 UINT8 array.
%
%   When using the 'Variables' parameters to read one variable, if the
%   'CombineRecords' parameter is true, the result is an M-by-N numeric
%   or character array; the data is not put into a cell array.
%
%   Specifying the 'CombineRecords' parameter with a true value of TF can
%   greatly improve the speed of importing large CDF datasets and reduce
%   the size of the MATLAB cell array containing the data.
%
%   [DATA, INF0] = CDFREAD(FILE, ...) also returns details about the CDF
%   file in the INFO structure.
%
%   Notes:
%
%     CDFREAD creates temporary files when accessing CDF files.  The
%     current working directory must be writeable.
%
%     To maximize performance, provide the 'CombineRecords' parameter 
%     with true (nonzero) value.
%
%     It is currently not possible to provide a set of records to read
%     (using the 'Records' parameter) and to combine records (using the
%     'CombineRecords' parameter).
%
%     CDFREAD performance can be noticeably influenced by the file
%     validation done by default by the CDF library.  Please consult
%     the CDFLIB package documentation for information on controlling
%     the validation process.
%
%   Examples:
%
%   % Read all of the data from the file.
%
%   data = cdfread('example.cdf');
%
%   % Read just the data from variable "Time".
%
%   data = cdfread('example.cdf', ...
%                    'Variables', {'Time'});
%
%   % Read the first value in the first dimension, the second value in
%   % the second dimension, the first and third values in the third
%   % dimension, and all of the values in the remaining dimension of
%   % the variable "multidimensional".
%
%   data = cdfread('example.cdf', ...
%                  'Variables', {'multidimensional'}, ...
%                  'Slices', [0 1 1; 1 1 1; 0 2 2]);
%
%   % The example above is analogous to reading the whole variable
%   % into a variable called "data" and then using matrix indexing,
%   % as follows:
%
%   data = cdfread('example.cdf', ...
%                  'Variables', {'multidimensional'});
%   data{1}(1, 2, [1 3], :)
%
%   % Collapse the records from a dataset and read CDF epoch datatypes
%   % as MATLAB datetimes.
%
%   data = cdfread('example.cdf', ...
%                  'CombineRecords', true, ...
%                  'DatetimeType', 'datetime');
%
%   See also CDFEPOCH, CDFINFO, CDFWRITE, CDFLIB.GETVALIDATE,
%   CDFLIB.SETVALIDATE.

%   Copyright 1984-2023 The MathWorks, Inc.

if nargin > 0
    filename = convertStringsToChars(filename);
end

if nargin > 1
    [varargin{:}] = convertStringsToChars(varargin{:});
end

% Determine the input argument values
options = parse_inputs(filename,varargin{:});

% Get full filename.
fid = fopen(filename);

if (fid == -1)

    % Look for filename with extensions.
    fid = fopen([filename '.cdf']);

    if (fid == -1)
        fid = fopen([filename '.CDF']);
    end

end

if (fid == -1)
    error(message('MATLAB:imagesci:cdflib:fileOpenError'))
else
    original_filename = filename;
    filename = fopen(fid);
    fclose(fid);
end

% Open the file
try
    cdfid = cdflib.open(filename);
catch me
    try
        ncid = netcdf.open(original_filename);
    catch me2
        % No, it was not.
        rethrow(me);
    end
    % Yes it was a netcdf file.
    netcdf.close(ncid);
    error(message('MATLAB:imagesci:cdf:isNetCDF'));
end
c = onCleanup(@() cdflib.close(cdfid));

% read and post-process the data
data = read_data(cdfid,options);

if nargout == 2
    info = cdfinfo(filename);
end


%--------------------------------------------------------------------------
function args = parse_inputs(filename,varargin)

% This function parses and validates the input arguments. 

% Fix the input parameter pairs to not rely upon completion.
names = {'variables','records','slices','convertepochtodatenum','datetimetype','combinerecords'};
for j = 1:2:numel(varargin)
    if ischar(varargin{j})
        varargin{j} = validatestring(varargin{j}, names);
    end
end

p = inputParser;
p.addRequired('filename', ...
    @(x) validateattributes(x,{'char','string'},{'scalartext','nonempty'},'','FILENAME'));
p.addParameter('variables', {}, ...
    @(x) validateattributes(x,{'cell','char','string'},{'nonempty'},'','VARIABLES'));
p.addParameter('records',[], ...
    @(x) validateattributes(x,{'double'},{'integer','vector','nonnegative'},'','RECORDS'));
p.addParameter('slices',[], ...
    @(x) validateattributes(x,{'double'},{'integer','2d','ncols',3},'','SLICES'));
p.addParameter('convertepochtodatenum',false, ...
    @(x) validateattributes(x,{'double','logical'},{'scalar'},'','CONVERTEPOCHTODATENUM'));
p.addParameter('datetimetype','datetime', ...
    @(x) validateattributes(x,{'char','string'},{'scalartext','nonempty'},'','DATETIMETYPE'));
p.addParameter('combinerecords',false, ...
    @(x) validateattributes(x,{'double','logical'},{'scalar'},'','COMBINERECORDS'));

p.parse(filename,varargin{:});
args.CombineRecords = logical(p.Results.combinerecords);
args.ConvertEpochToDatenum = logical(p.Results.convertepochtodatenum);
args.Records = p.Results.records;

% Ensure we get valid values for DatetimeType param
dtype = validatestring(p.Results.datetimetype,{'datetime','native'});
args.DatetimeType = lower(dtype);

% We need to track if the user passed in values for ConvertEpochToDatenum and DatetimeType
if ((~ismember('convertepochtodatenum',p.UsingDefaults)) && (~ismember('datetimetype',p.UsingDefaults)))
    % This means they were both explicitly passed in  
    error(message('MATLAB:imagesci:cdf:combineEpochAndDatetime'));
else 
    if ismember('convertepochtodatenum',p.UsingDefaults)
        args.unspecifiedEpochConv = true;
    else
        args.unspecifiedEpochConv = false;
    end

    if ismember('datetimetype',p.UsingDefaults)
        args.unspecifiedDatetimeType = true;
    else
        args.unspecifiedDatetimeType = false;
    end
end

slices = p.Results.slices;
if ~isempty(slices)
    validateattributes(slices(:,1),{'double'},{'nonnegative'},'','SLICES(:,1)');
    validateattributes(slices(:,2),{'double'},{'positive'},'','SLICES(:,2)');
    validateattributes(slices(:,3),{'double'},{'positive'},'','SLICES(:,3)');
end
args.Slices = slices;

if ischar(p.Results.variables)
    args.Variables = {p.Results.variables};
else
    variables = matlab.io.internal.imagesci.convertStringsInCell(p.Results.variables);
    for j = 1:numel(variables)
        validateattributes(variables{j},{'char','string'},{'scalartext','nonempty'},'',sprintf('Variables{%d}',j));
    end
    args.Variables = variables;
end

% Ensure that the mutually exclusive options weren't provided.
% CombineRecords is valid only when not selected specific records 
if ((args.CombineRecords) && (~isempty(args.Records)))
    error(message('MATLAB:imagesci:cdf:combineRecordSubset'))
end

% Slices only works on individual variables
if (numel(args.Variables)>1) && ~isempty(args.Slices)
    error(message('MATLAB:imagesci:cdf:oneVariableRequired'));
end

% Need a variable when requesting slices
if ~isempty(args.Slices) && isempty(args.Variables)
    error(message('MATLAB:imagesci:cdf:oneVariableRequired'));
end


%--------------------------------------------------------------------------
function data = read_data(cdfid,options)

% This function reads the raw data and performs any necessary post-processing.

% Get the metadata/structure of the file
fileinfo = cdflib.inquire(cdfid);

% Store away the variable numbers before attempting to read.
% Also need to figure out how many records we will retrieve.
if isempty(options.Variables)
    options.varnum = 0:fileinfo.numVars-1;
    options.maxrec = fileinfo.maxRec+1;
else
    % If specific variables were requested that have less than the file
    % maximum, then use the largest of them.
    options.varnum = zeros(1,numel(options.Variables));
    maxrec = zeros(numel(options.Variables),1);
    for j = 1:numel(options.Variables)
        options.varnum(j) = cdflib.getVarNum(cdfid,options.Variables{j});
        maxrec(j) = cdflib.getVarMaxWrittenRecNum(cdfid,options.varnum(j));
    end
    options.maxrec = max(maxrec)+1;
end

% If no records specified, read in all of them
if isempty(options.Records)
    options.numrecs = options.maxrec;
else
    options.numrecs = numel(options.Records);
end

% Read in the data
data = read_data_by_hyperslab(cdfid,options);

% Perform any necessary post-processing
data = post_process(data,cdfid,options);


%--------------------------------------------------------------------------
function data = read_data_by_hyperslab(cdfid,options)
% This function reads the data into an MxN cell array where M is the number
% of records in the file and N is the number of variables.

fileinfo = cdflib.inquire(cdfid);
data = cell(1,numel(options.varnum));

% Loop through the variables
for j = 1:numel(options.varnum)

    varnum = options.varnum(j);
    varinfo = cdflib.inquireVar(cdfid,varnum);

    % Determine the record variance
    recspec = compute_rec_spec(varinfo,options);

    % If no records, then it's just empty.
    if recspec(2) == 0
        warning(message('MATLAB:imagesci:cdf:emptyRecordVariable',varinfo.name));
        data{1,j} = [];
        % Proceed to next variable 
        continue;
    end

    % Determine the dimension variance
    dimspec = compute_dim_spec(varinfo,fileinfo,options);

    if isempty(dimspec)
        % If no dim variance, then we should only provide the recspec.
        x = cdflib.hyperGetVarData(cdfid,varnum,recspec);
    else
        x = cdflib.hyperGetVarData(cdfid,varnum,recspec,dimspec);
    end

    % Replicate across number of specified records if no record variance.
    % Now we have the same number of records no matter what.
    if ~varinfo.recVariance
        x = repmat(x,1,options.numrecs);
    end

    % EPOCH data is columnar when final, and this is easier to handle than
    % the raw form, so post process it now.
    if strncmp(varinfo.datatype,'cdf_epoch',9)
        x = post_process_epoch(x,varinfo,options);
    end

    % TT2000 data is columnar when final, and this is easier to handle than
    % the raw form, so post process it now.
    if strcmp(varinfo.datatype,'cdf_time_tt2000')
        x = post_process_tt2000(x,options);
    end

    if ~varinfo.recVariance
        % We're done with this variable, no need to subset.
        data{1,j} = x;
        continue
    end

    if ~isempty(options.Records)
        % Subset to specified records.
        if strncmp(varinfo.datatype,'cdf_epoch',9) || isempty(varinfo.dimVariance)
            idx = options.Records - recspec(1) + 1;
            x = x(idx);
        elseif numel(options.Records) > 1
            n = ndims(x);
            % index for trailing dimension.
            I = options.Records+1; %#ok<NASGU>
            cmd = sprintf('x = x(%sI);', repmat(':,',[1 n-1]));
            eval(cmd);
        end
    end

    data{1,j} = x;

end

%--------------------------------------------------------------------------
function data = post_process(data,cdfid,options)

fileinfo = cdflib.inquire(cdfid);

numrecs = options.numrecs;

if options.CombineRecords
    % OK, we have combined records.

    % Do we need to transpose?
    if strcmp(fileinfo.majority,'ROW_MAJOR')
        for j = 1:numel(data)
            n = ndims(data{j});
            pdims = n:-1:1;
            data{j} = permute(data{j},pdims);
        end
    end

    % Vector entries are always columns.
    for j = 1:numel(data)
        if isrow(data{j})
            data{j} = data{j}';
        end
    end

    if numel(options.Variables) == 1
        % If only a single variable was specified, then the output is NOT a
        % cell array.
        data = data{1};
    end

    return

end

% DO NOT combine records.  This is the default.
numvars = numel(options.varnum);
outdata = cell(numrecs, numvars);

for k = 1:numvars

    varnum = options.varnum(k);
    varinfo = cdflib.inquireVar(cdfid,varnum);

    coldata = data{k};
    if isempty(coldata)
        % Such as with EPOCH16.
        continue
    end

    dimspec = compute_dim_spec(varinfo,fileinfo,options);

    % Permute the data approriately before splitting into cell entries.
    switch(varinfo.datatype)
        case {'cdf_char', 'cdf_uchar'}
            % numElements is fastest-varying, so it leads off.  But no need
            % to bother unless there actually are dimensions.
            if ~isempty(varinfo.dims)
                r = [varinfo.numElements dimspec{2} options.numrecs];
                coldata = reshape(coldata,r);
            end

            % Permute the numElements dimension into 2nd position for
            % purpose of readability?
            %
            % transpose rest.
            %nr = numel(r);
            nr = ndims(coldata);
            if strcmp(fileinfo.majority,'COLUMN_MAJOR')
                permute_dims = [2 1 3:nr];
            elseif nr > 2
                %permute_dims = [nr 1 (nr-1):-1:2];
                permute_dims = [nr-1 1 (nr-2):-1:2 nr];
            else
                permute_dims = [2 1];
            end

            coldata = permute(coldata,permute_dims);

        otherwise
            %if numel(varinfo.dims) > 1
            if ~isempty(varinfo.dims) && (varinfo.dims(1) > 1)

                if isempty(options.Slices)
                    % reshape according to the size
                    %coldata = reshape(coldata,[varinfo.dims fileinfo.maxRec+1]);
                    rdims = [varinfo.dims options.numrecs];
                    coldata = reshape(coldata,rdims);
                else
                    % Reshape according to the count that was given if data is more
                    % than 1 dimension.
                    dimspec = compute_dim_spec(varinfo,fileinfo,options);
                    if numel(varinfo.dims) > 1
                        coldata = reshape(coldata,dimspec{2});
                    end
                end

                % permute if needed
                if strcmp(fileinfo.majority,'ROW_MAJOR') && ~isvector(coldata)
                    if options.numrecs == 1
                        pdims = numel(varinfo.dims):-1:1;
                    else
                        pdims = [numel(varinfo.dims):-1:1 ndims(coldata)];
                    end
                    coldata = permute(coldata,pdims);
                end

            elseif iscolumn(coldata) && (options.maxrec > 1)
                % rows are easier to work into num2cell
                coldata = coldata';
            end

    end

    n = ndims(coldata);
    %if fileinfo.maxRec == 0
    if options.numrecs == 1
        outdata(:,k) = num2cell(coldata, 1:n);
    else
        n = ndims(coldata);
        coldata = num2cell(coldata, 1:n-1);
        outdata(:,k) = coldata(:);
    end

end

data = outdata;


%--------------------------------------------------------------------------
function recspec = compute_rec_spec(varinfo,options)
% Construct the record specification which will be passed into
% cdflib.hyperGetVarData.
if varinfo.recVariance
    if ~isempty(options.Records)
        % Retrieve all the records between the first and last specified
        % record.  We will get rid of unwanted records later.
        minrec = min(options.Records(:));
        maxrec = max(options.Records(:));
        recspec = [minrec (maxrec-minrec+1) 1];
    else
        recspec = [0 options.maxrec 1];
    end
else
    % No record variance, so we will want to just retrieve the first record
    % and then replicate.
    recspec = [0 1 1];
end


%--------------------------------------------------------------------------
function dimspec = compute_dim_spec(varinfo,fileinfo,options)
% Construct the dimension specification to pass into
% cdflib.hyperGetVarData.
dstart = zeros(1,numel(varinfo.dims));
dcount = varinfo.dims;
dstride = ones(1,numel(varinfo.dims));

if ~isempty(options.Slices)

    num_slice_dims = size(options.Slices,1);

    slice_start = options.Slices(:,1)';
    slice_stride = options.Slices(:,2)';
    slice_count = options.Slices(:,3)';

    if num_slice_dims ~= numel(varinfo.dims)
        % must pad the incompletely specified dim spec
        for j = num_slice_dims+1:numel(varinfo.dims)
            slice_start(j) = 0;
            slice_stride(j) = 1;
            if strcmp(fileinfo.majority,'COLUMN_MAJOR')
                slice_count(j) = varinfo.dims(j);
            else
                slice_count(j) = varinfo.dims(end-j+1);
            end
        end
    end

    % Flip the dimension spec, as the slice argument was assumed to be for
    % a col-major order variable.
    if strcmp(fileinfo.majority,'COLUMN_MAJOR')
        dstart = slice_start;
        dcount = slice_count;
        dstride = slice_stride;
    else
        dstart = fliplr(slice_start);
        dcount = fliplr(slice_count);
        dstride = fliplr(slice_stride);
    end

    dimspec = {dstart dcount dstride};

    %elseif any(varinfo.dimVariance)
elseif ~isempty(varinfo.dimVariance)

    % Get all data for the provided record specification.
    dimspec = {dstart dcount dstride};

else
    dimspec = [];
end


%--------------------------------------------------------------------------
function outTime = post_process_epoch(timeVal,varinfo,options)

switch(varinfo.datatype)
    case 'cdf_epoch'

        % Get the individual components out of the epoch value
        epochComp = cdflib.epochBreakdown(timeVal);

        % Transpose and get fractional seconds
        epochComp = epochComp';
        epochCompWithFracSec = epochComp(:,1:6);
        epochCompWithFracSec(:,6) = epochCompWithFracSec(:,6) + epochComp(:,7)/1000;

        % For CDF_EPOCH, the return value is cdfepoch by default. 
        % We need to handle the different combinations of specifying ConvertEpochToDatenum 
        % and DatetimeType parameters:
        % 1. Both ConvertEpochToDatenum and DatetimeType are specified:  Errors during input parsing
        % 2. Neither ConvertEpochToDatenum nor DatetimeType are specified:  cdfepoch (default)
        % 3. ConvertEpochToDatenum specified as false:  cdfepoch
        % 4. ConvertEpochToDatenum specified as true:  datenum
        % 5. DatetimeType specified as datetime:  datetime
        % 6. DatetimeType specified as native:  double
        
        if options.unspecifiedDatetimeType
            if (~options.ConvertEpochToDatenum) 
                outTime = cdfepoch(datenum(epochCompWithFracSec));
            else
                outTime = datenum(epochCompWithFracSec);
            end
            
        else
            if strcmp(options.DatetimeType,'datetime')
                outTime = datetime(timeVal,'ConvertFrom','epochtime','Epoch','0000-01-01', ...
                'TicksPerSecond',1000,'Format','dd-MMM-uuuu HH:mm:ss.SSS');
            else
                % No need for post-processing, just return the raw double value
                outTime = timeVal;
            end
        end

    case 'cdf_epoch16'
        % Reading CDF_EPOCH16 is not supported via cdfread, but is supported in the
        % low-level library functions.
        warning(message('MATLAB:imagesci:cdf:epoch16Unsupported',varinfo.name));
        outTime = [];

end


%--------------------------------------------------------------------------
function outTime = post_process_tt2000(timeVal,options)

% For CDF_TIME_TT2000, the return value is dateime by default. 
% We need to handle the different combinations of specifying ConvertEpochToDatenum 
% and DatetimeType parameters:
% 1. Both ConvertEpochToDatenum and DatetimeType are specified:  Errors during input parsing
% 2. Neither ConvertEpochToDatenum nor DatetimeType are specified:  datetime (default)
% 5. DatetimeType specified as datetime:  datetime
% 6. DatetimeType specified as native:  int64
% 3. ConvertEpochToDatenum specified as false:  invalid option for tt2000 
% 4. ConvertEpochToDatenum specified as true:  invalid option for tt2000

if ~options.unspecifiedEpochConv
    error(message('MATLAB:imagesci:cdf:tt2000WithEpochConv'));

elseif strcmp(options.DatetimeType,'datetime')
    % Convert to datetime
    outTime = datetime(int64(timeVal),"ConvertFrom","tt2000","TimeZone","UTCLeapSeconds", ...
        "Format","uuuu-MM-dd'T'HH:mm:ss.SSSSSSSSS'Z'");

elseif strcmp(options.DatetimeType,'native')
    % Return the raw int64 value
    outTime = timeVal;
end

