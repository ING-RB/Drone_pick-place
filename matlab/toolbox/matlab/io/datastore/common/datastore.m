function ds = datastore(location, varargin)
%DATASTORE Create a datastore for working with collections of data.
%   DS = DATASTORE(LOCATION) creates a datastore DS based on the LOCATION
%   of the data. For example, if LOCATION is a collection of
%   comma-separated value (CSV) files, then DS is a TabularTextDatastore.
% 
%   DS = DATASTORE(LOCATION,'Type',TYPE) specifies the type of
%   the datastore. The supported types are:
%  
%     'tabulartext'   -    For tabular text files
%     'image'         -    For image files
%     'spreadsheet'   -    For spreadsheet files
%     'file'          -    For custom format files
%     'tall'          -    For tall data files from tall/write
%     'keyvalue'      -    For use with key-value data from mapreduce
%     'database'      -    For use with Database Toolbox
% 
%   DS = DATASTORE(__,'Name1',Value1,'Name2',Value2, ...) specifies the
%   properties of DS using optional name-value pairs. Please refer to the
%   documentation for a list of supported Name-Value pairs.
% 
%   All datastores support the following functions:
%         
%   preview   -    Read a small amount of data from the start of the datastore.
%   read      -    Read some data from the datastore.
%   readall   -    Read all of the data from the datastore.
%   hasdata   -    Returns true if there is more data in the datastore.
%   reset     -    Reset the datastore to the start of the data.
%   transform -    Create an altered form of the current datastore by
%                  specifying a function handle that will execute after 
%                  read on the current datastore.
%   combine   -    Create a new datastore that horizontally concatenates
%                  the result of read from two or more input datastores.
% 
%   Example:
%      % Create a TabularTextDatastore
%      tabds = datastore('airlinesmall.csv')
%      % Treat 'NA' as a missing numeric value
%      tabds.TreatAsMissing = 'NA';
%      % Read missing data as 0
%      tabds.MissingValue = 0;
%      % We are only interested in the Arrival Delay data
%      tabds.SelectedVariableNames = 'ArrDelay'       
%      % Preview the data as a table
%      tab = preview(tabds)
%      % Sum the Arrival Delays
%      sumAD = 0;
%      while hasdata(tabds)
%         tab = read(tabds);
%         sumAD = sumAD + sum(tab.ArrDelay);
%      end
%      sumAD
% 
%   See also tall, matlab.io.datastore.TabularTextDatastore,
%            matlab.io.datastore.ImageDatastore,
%            matlab.io.datastore.SpreadsheetDatastore,
%            matlab.io.datastore.FileDatastore,
%            matlab.io.datastore.KeyValueDatastore,
%            matlab.io.datastore.TallDatastore,
%            matlab.io.datastore.DatabaseDatastore, mapreduce.
% 
%   Note: matlab.io.datastore.DatabaseDatastore is in the Database Toolbox.

%   Copyright 2014-2020 The MathWorks, Inc.

if nargin < 1
    error(message('MATLAB:minrhs'));
end

if isstring(location)
    location = convertStringsToChars(location);
elseif isa(location,'matlab.io.datastore.DsFileSet')
    location = matlab.io.datastore.FileBasedDatastore.convertFileSetToFiles(location);
end

if nargin > 1
    [varargin{:}] = convertStringsToChars(varargin{:});
end

% see if 'Type' is provided as an input.
dsTypeArr = strcmpi(varargin,'Type');
% see if aliased 'DatastoreType' is provided as an input.
dsAliasTypeArr = strcmpi(varargin,'DatastoreType');

numDatastoreTypesSpecified = nnz(dsTypeArr);
numAliasTypesSpecified = nnz(dsAliasTypeArr);

if numAliasTypesSpecified > 0
    % If both 'DatastoreType' and 'Type' are provided, error
    if numDatastoreTypesSpecified > 0
        error(message('MATLAB:datastoreio:datastore:typeAndDatastoreType'));
    end
    % Assign aliased 'DatastoreType' to 'Type'.
    numDatastoreTypesSpecified = numAliasTypesSpecified;
    dsTypeArr = dsAliasTypeArr;
end

[dsNames, fileBased, additionalParams] = matlab.io.datastore.internal.getAvailableDatastores();

if numDatastoreTypesSpecified == 0
    % try to introspect
    supportsLocationMethods = matlab.io.datastore.internal.getSupportsLocationMethods(dsNames);
    match = -1;
    for i = find(~fileBased)
        % Check non FileBased datastores if they support location
        % Validation for non file based locations are at
        % matlab.io.datastore.internal.validators.<DatastoreType>.supportsLocation
        
        if suppLocCheck(supportsLocationMethods{i}, 0, location, additionalParams{i})
            match = i;
            break;
        end
    end
    if match == -1
        % Parse FileBased Name-Value pairs
        fileBasedNV = parseFileBasedNVPairs(varargin{:});
        if ~ismember('FileExtensions', fileBasedNV.UsingDefaults)
            error(message('MATLAB:datastoreio:datastore:fileExtsWithDatastoreType'));
        end
        for i = find(fileBased)
            % Check FileBased datastores if they support location
            if suppLocCheck(supportsLocationMethods{i}, 1, location, additionalParams{i}, fileBasedNV)
                match = i;
                break;
            end
        end
        if match == -1
            throwAutoDetectErrorForLocation(location, fileBasedNV.IncludeSubfolders);
        end
    end
else
    % this input must not be provided multiple times.(just one unique match)
    if numDatastoreTypesSpecified > 1
        error(message('MATLAB:datastoreio:datastore:duplicateType'));
    end

    % find the type and set that N-V pair to empty, so that subclasses don't
    % need to worry about it.
    dsTypeLoc = find(dsTypeArr, 1);
    
    if dsTypeLoc+1 > numel(varargin)
        error(message('MATLAB:datastoreio:datastore:missingDatastoreTypeValue'));
    end
    
    dsTypeValue = varargin{dsTypeLoc + 1};
    varargin(dsTypeLoc:dsTypeLoc + 1) = [];

    if ~matlab.io.internal.validators.isCharVector(dsTypeValue) || isempty(dsTypeValue)
        error(message('MATLAB:datastoreio:datastore:invalidDatastoreTypeInput'));
    end
    
    % partial match for DatastoreType value.
    matches = matchDatastoreTypeValue(dsNames, dsTypeValue);
    numMatches = nnz(matches);

    if numMatches == 0
        error(message( ...
            'MATLAB:datastoreio:datastore:datastoreTypeNotFound', ...
            dsTypeValue ...
        ));
    end

    % ensure that we get only one match
    if numMatches > 1
        % Verify that the matches have different names.
        matchedDsNames = dsNames(matches);
        if any(~strcmp(matchedDsNames, matchedDsNames(1)))
            error(message( ...
                'MATLAB:datastoreio:datastore:ambiguousTypeSpecified', ...
                dsTypeValue ...
            ));
        end
    end
    match = find(matches, 1);
end
dsName = dsNames{match};
% call the constructor
ds = feval(dsName, location, varargin{:});
end

% L O C A L   H E L P E R S %
function tf = suppLocCheck(funName, isFileBased, loc, additionalParams, nvStruct)
    if ~isempty(which(funName)) % found function
        try
            if isFileBased
                tf = feval(funName, loc, nvStruct, additionalParams{:});
            else
                tf = feval(funName, loc, additionalParams{:});
            end
        catch
            tf = false;
            return;
        end
    else
        tf = false;
    end
end

function throwAutoDetectErrorForLocation(location, includeSubFolders)
    exc = MException(message(...
                'MATLAB:datastoreio:datastore:noSupportedDatastoreForLocation'));
    % imports
    import matlab.io.internal.validators.isCharVector;
    import matlab.io.internal.validators.isCellOfCharVectors;
    import matlab.io.datastore.internal.pathLookup
    
    if isCharVector(location) || isCellOfCharVectors(location)
        % may be paths
        ioExc = [];
        
        % try to reproduce the error for paths
        if ~isempty(location)
            try
                files = pathLookup(location); %#ok<NASGU>
            catch ioExc
            end
        end

        if nargin > 1 && includeSubFolders == true
            throw(exc);
        elseif ~isempty(ioExc)
            throwAsCaller(ioExc);
        end
    end
    % if location wasn't string or cellstrings or the files exist, something else
    % went wrong. Throw the generic error message.
    throwAsCaller(exc);
end

% function used to partial match the DatastoreType value specified.
function matches = matchDatastoreTypeValue(dsNames, dsTypeValue)
    % to be looked up by the datastore gateway, all datastores must live 
    % matlab.io.datastore package.
    supportedDsTypeValues = strrep(dsNames, 'matlab.io.datastore.', '');
    matches = strncmpi(dsTypeValue, supportedDsTypeValues, length(dsTypeValue));
end

function fileBasedNVPairs = parseFileBasedNVPairs(varargin)
    % Parse only the file based Name-Value pairs. 
    % We use inputParser ONCE irrespective of datastores. inputParser takes care of 
    % the clashes between NV pairs:
    % 'IncludeS', true, 'Include', '':
    %     * Default for IncludeFileTypes
    %     * true for IncludeSubfolders.
    % We are passing the parsed struct only to the file based datastores.
    % If some other new non-file-based datastore has a NV pair called 'IncludeSomething'
    % it would be parsed but it will not be passed to the
    % new non-file-based datastore's supportsLocation.
    % The below NV pairs are applicable for all file based datastores.
    % If we are to introduce a new NV pair or a user creates one for a file based datastore,
    % we are going to be aware of it just the way we have to deal with
    % 'IncludeFileTypes' and 'IncludeSubfolders' now.
    persistent inpP;
    if isempty(inpP)
        inpP = inputParser;
        addParameter(inpP, 'IncludeSubfolders', false);
        addParameter(inpP, 'FileExtensions', -1);
        inpP.FunctionName = 'datastore';
        inpP.KeepUnmatched = true;
    end
    parse(inpP, varargin{:});
    fileBasedNVPairs = inpP.Results;
    % Incase if a file based datastore wants to decide supportsLocation
    % based on user-specified or default NV pairs.
    fileBasedNVPairs.UsingDefaults = inpP.UsingDefaults;
    fileBasedNVPairs.Unmatched = inpP.Unmatched;
end
