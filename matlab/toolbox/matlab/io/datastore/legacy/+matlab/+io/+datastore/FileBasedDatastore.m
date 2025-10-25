classdef (Hidden = true, AllowedSubclasses = {?matlab.io.datastore.TabularTextDatastore, ?matlab.io.datastore.KeyValueDatastore, ?matlab.io.datastore.CustomReadDatastore, ?matlab.io.datastore.SpreadsheetDatastore, ?matlab.io.datastore.MatSeqDatastore, ?matlab.io.datastore.MDFDatastore}) ...
        FileBasedDatastore < matlab.io.datastore.internal.HandleUnwantedHideable &...
        matlab.io.datastore.SplittableDatastore

%FileBasedDatastore  Super class for splittable file based datastores. 
%   This class inherits from SplittableDatastore and is the super class for
%   all file based datastores. It requires all its subclasses to implement
%   the property ReadSize which control the size of the data returned by
%   the read method. It also provides default implementations for hasdata,
%   reset and loadobj methods.

%   Copyright 2014-2024 The MathWorks, Inc.

    properties (Transient, Access = 'private')
        %ISVALIDDATASTORE Boolean to indicate a valid datastore.
        %   IsValidDatastore indicates if a datastore is valid to read
        %   from. A datastore becomes invalid once it has been loaded from
        %   a mat file. This property is used to make the datastore valid
        %   by setting the property in the public methods (hasdata)
        IsValidDatastore = true;
    end
    
    properties (Abstract)
        %FILES included in datastore.
        %   This class requires access to the Files property, however the
        %   actual definition will come from children of this class.
        Files;
    end

    properties(SetAccess = 'private', Transient, Hidden)
        ReadFailures;
    end

    properties (Hidden)
        PrivateReadFailuresList;
        PrivateMaxFailures = Inf;
        PrivateReadFailureRule = 'error';
        PrivateReadCounter = false;
    end

    properties(Access='protected')
        %TOTALFILES Total number of files included in the datastore
        TotalFiles;
        PreviewCall(1,1) logical = false;
    end

    methods (Access = protected)
        function tf = isEmptyFiles(ds)
            tf = ds.Splitter.NumSplits == 0;
        end

        function setTransformedFiles(ds, files)
            %SETTRANSFORMEDFILES Needs to be implemented for CrossPlatformFileRoots
            % In order to support AlternateFileSystemRoots, which can change the roots of the file paths
            % in the datastore, we need to set the changed file paths on to the splits.
            ds.Splitter.setFilesOnSplits(files);
        end

        function files = getFilesForTransform(ds)
            %GETFILESFORTRANSFORM Needs to be implemented for CrossPlatformFileRoots
            %   In order to support AlternateFileSystemRoots, which can change the roots
            %   of the file paths in the datastore, we need to get the file paths
            %   from the splits that could be changed based upon AlternateFileSytemRoots.
            if isEmptyFiles(ds)
                files = {};
                return;
            end
            files = getFilesForTransform(ds.Splitter);
        end

        function [diffIndexes, currIndexes, files, fileSizes, diffPaths] = setNewFilesAndFileSizes(ds, files)
            import matlab.io.datastore.internal.util.getIndicesForFilesAndFileSizes;

            getFilesFcn = @()ds.Files;
            getFileSizesFcn = @(indexes)getFileSizes(ds.Splitter, indexes);
            [diffIndexes, currIndexes, files, fileSizes, diffPaths] =...
                getIndicesForFilesAndFileSizes(getFilesFcn, getFileSizesFcn, files);
            ds.TotalFiles = size(files, 1);
        end

        function validateReadFailureRule(ds, readfailrule)
        %VALIDATEREADFAILURERULE Validates the ReadFailureRule
            res = validatestring(readfailrule,{'error'});
            orig = ds.PrivateReadFailureRule;
            ds.PrivateReadFailureRule = res;
            if ~isempty(orig) && ~strcmpi(orig,res)
                reset(ds);
                ds.PrivateReadFailuresList = zeros(ds.TotalFiles,1);
            end
        end

        function validateMaxFailures(ds, maxfails)
        %VALIDATEMAXFAILURES Validates MaxFailures
            if isscalar(maxfails) && isa(maxfails,'numeric') && ~isnan(maxfails)
                if maxfails > 1
                    if ~isinf(maxfails)
                        validateattributes(maxfails,{'numeric'},{'integer','positive','scalar'},'','MaxFailures');
                    end
                else
                    validateattributes(maxfails,{'numeric'},{'scalar','positive','<=',1},'','MaxFailures');
                end
            else
                error(message('MATLAB:datastoreio:filebaseddatastore:invalidMaxFailures'));
            end
            ds.PrivateMaxFailures = double(maxfails);
        end
    end
        
    methods        
        function tf = hasdata(ds)
            %HASDATA Returns true if there is more data in the Datastore.
            %   TF = hasdata(DS) returns true if there is more data in the
            %   Datastore, TDS, and false otherwise. read(DS) issues an
            %   error when hasdata(DS) returns false.
            %
            %   Example:
            %   --------
            %      % Create a TabularTextDatastore
            %      tabds = tabularTextDatastore('airlinesmall.csv')
            %      % Handle erroneous data
            %      tabds.TreatAsMissing = 'NA'
            %      tabds.MissingValue = 0;
            %      % We are only interested in the Arrival Delay data
            %      tabds.SelectedVariableNames = 'ArrDelay'
            %      % Preview the first 8 rows of the data as a table
            %      tab8 = preview(tabds)
            %      % Sum the Arrival Delays
            %      sumAD = 0;
            %      while hasdata(tabds)
            %         tab = read(tabds);
            %         sumAD = sumAD + sum(tab.ArrDelay);
            %      end
            %      sumAD
            %
            %     See also matlab.io.datastore.TabularTextDatastore, read, readall, preview, reset.
        
            try
                % reset the datastore if invalid
                %
                % if reset() throws an error, keep the datastore in an
                % invalid state so that this action is retried.
                if ~ds.IsValidDatastore
                    reset(ds);
                    ds.IsValidDatastore = true;
                end
                
                tf = hasdata@matlab.io.datastore.SplittableDatastore(ds);
            catch ME
                if strcmpi(ds.ReadFailureRule,'error') || ...
                        isempty(ds.ReadFailureRule)
                    throwAsCaller(ME);
                else
                    tf = true;
                end
            end
        end
        
        function reset(ds)
        %RESET   Reset to the start of the data.
        %   This method is responsible for setting the state of the
        %   datastore to a valid state before resetting to the start of the
        %   data.
        %
        %   See also READ, READALL, PREVIEW, RESET,
        %   matlab.io.datastore.TabularTextDatastore
        
            try
                reset@matlab.io.datastore.SplittableDatastore(ds);
                ds.PrivateReadCounter = false;
                if ~isa(ds,'matlab.io.datastore.ImageDatastore')
                    ds.PrivateReadFailuresList = zeros(ds.TotalFiles,1);
                end
            catch ME
                throw(ME);
            end
            
            % when reset is called, the datastore needs to be set to a
            % valid state. unnecessary to check if it is false here.
            ds.IsValidDatastore = true;
        end
    end
    
    methods
        function subds = partition(ds, partitionStrategy, index)
            %PARTITION Return a partitioned part of the Datastore.
            %
            %   SUBDS = PARTITION(DS,NUMPARTITIONS,INDEX) partitions DS into
            %   NUMPARTITIONS parts and returns the partitioned DATASTORE,
            %   SUBDS, corresponding to INDEX. An estimate for a reasonable value for the
            %   NUMPARTITIONS input can be obtained by using the NUMPARTITIONS function.
            %
            %   SUBDS = PARTITION(DS,'Files',INDEX) partitions DS by files in the
            %   Files property and returns the partition corresponding to INDEX.
            %
            %   SUBDS = PARTITION(DS,'Files',FILENAME) partitions DS by files and
            %   returns the partition corresponding to FILENAME.
            %
            %   Example:
            %      % A datastore that contains 10 copies of the 'airlinesmall.csv'
            %      % example dataset.
            %      files = repmat({'airlinesmall.csv'},1,10);
            %      ds = tabularTextDatastore(files,'TreatAsMissing','NA','MissingValue',0);
            %      ds.SelectedVariableNames = 'ArrDelay';
            %
            %      % This will parse approximately the first third of the example data.
            %      subds = partition(ds,3,1);
            %
            %      totalSum = 0;
            %      while hasdata(subds)
            %         data = read(subds);
            %         totalSum = totalSum + sum(data.ArrDelay);
            %      end
            %      totalSum
            %
            %   See also matlab.io.datastore.TabularTextDatastore, numpartitions.

            import matlab.io.datastore.internal.validators.validatePartitionFilesStrategy
            if nargin > 1
                partitionStrategy = convertStringsToChars(partitionStrategy);
            end

            if nargin > 2
                index = convertStringsToChars(index);
            end

            try
                if ~ischar(partitionStrategy) || ~strcmpi(partitionStrategy, 'Files')
                    subds = partition@matlab.io.datastore.SplittableDatastore(ds, partitionStrategy, index);
                    partitionFolders(subds, partitionStrategy, index);
                    return;
                end

                [~, index] = validatePartitionFilesStrategy(partitionStrategy, index, @()ds.Files, ds.TotalFiles);

                % The actual partitioning.
                subds = copy(ds);

                % FileIndices of the split always have a 1-1 mapping with the
                % Files contained by the datastore. This is ensured in the
                % createFromSplits method of the splitter. set the splitter and
                % reset.
                splits = ds.Splitter.Splits;
                subds.Splitter = ds.Splitter.createCopyWithSplits(splits([splits.FileIndex]== index));
                reset(subds);
                % avoid reset on the workers since we already reset it above
                subds.IsValidDatastore = true;

                partitionFolders(subds, partitionStrategy, index);
            catch ME
                throwAsCaller(ME);
            end
        end

        function files = get.ReadFailures(ds)
            files = matlab.io.datastore.DsFileSet(ds.Files(ds.PrivateReadFailuresList == 1));
        end
    end
    
    methods (Static, Hidden)
        function outds = loadobj(ds)
        %LOADOBJ controls custom loading from a mat file.
        %   loadobj implementation sets a boolean flag to true to indicate
        %   that a datastore loaded from a mat file is in a invalid state
        %   (does not have a file handle open to the first file). This flag
        %   is used in our pulic methods (specifically hasdata()) to reset
        %   the datastore to make the datastore valid.
        
            ds.IsValidDatastore = false;
            outds = ds;
        end

        function [tf, loc, fileSizes, fileExts] = supportsLocation(loc, nvStruct, defaultExtensions, filterExtensions)
            % This function is responsible for determining whether a given
            % location is supported by a FileBasedDatastore. It also returns a
            % resolved filelist and the corresponding file sizes.

            %imports
            import matlab.io.datastore.internal.validators.validateFileExtensions;
            import matlab.io.internal.vfs.validators.validatePaths;
            import matlab.io.datastore.internal.pathLookup;

            if isa(loc, "matlab.io.datastore.FileSet")
                exts = categorical(lower(extractAfter(loc.FileInfo.Filename, ".")));
                tf = true;
                fileSizes = loc.FileInfo.FileSize;
                loc = cellstr(loc.FileInfo.Filename);
                fileExts = cellstr(exts);
                return;
            end
            % validate file extensions, include subfolders is validated in
            % pathlookup
            isDefaultExts = validateFileExtensions(nvStruct.FileExtensions, nvStruct.UsingDefaults);

            % setup the allowed extensions
            if isDefaultExts
                allowedExts = defaultExtensions;
            else
                allowedExts = nvStruct.FileExtensions;
            end

            % If IncludeSubfolders is already provided, then we do not want to suggest
            % IncludeSubfolders option when erroring for an empty folder
            noSuggestionInEmptyFolderErr = ~ismember('IncludeSubfolders', nvStruct.UsingDefaults);
            if ~noSuggestionInEmptyFolderErr && isfield(nvStruct, 'ValuesOnly')
                % ValuesOnly exists for MatSeqDatastore and is true only for TallDatastore
                % We do not want to suggest IncludeSubfolders option when erroring for an empty folder
                noSuggestionInEmptyFolderErr = nvStruct.ValuesOnly;
            end
            origFiles = loc;
            % validate and lookup paths
            loc = validatePaths(loc);
            if nargout > 2
                [loc, fileSizes] = pathLookup(loc, nvStruct.IncludeSubfolders, noSuggestionInEmptyFolderErr);
            else
                loc = pathLookup(loc, nvStruct.IncludeSubfolders, noSuggestionInEmptyFolderErr);
            end

            szLoc = size(loc);
            % filter based on extensions
            filterExts = true(szLoc);
            fileExts = cell(szLoc);
            isFiltered = false;
            if nargin < 4 || filterExtensions
                for ii = 1:max(szLoc)
                    if matlab.io.internal.common.validators.isGoogleSheet(loc{ii})
                        fileExts{ii} = '';
                        filterExts(ii) = true;
                    else
                        [~, ~, ext] = fileparts(loc{ii});
                        if ~any(strcmpi(allowedExts, ext))
                            filterExts(ii) = false;
                            isFiltered = true;
                        end
                        fileExts{ii} = ext;
                    end
                end
                loc = loc(filterExts);
            end
            tf = true;
            switch nargout
                case 1
                    if isempty(loc) || isFiltered
                        % mixed types are not supported during construction
                        tf = false;
                    end
                case 3
                    fileSizes = fileSizes(filterExts);
                case 4
                    fileSizes = fileSizes(filterExts);
                    fileExts = fileExts(filterExts);
            end
            if isempty(loc) && ~isempty(origFiles)
                % if input files are non-empty but Files resolved are empty,
                % we need to error - we don't want to generate an empty datastore
                if ~ismember('FileExtensions', nvStruct.UsingDefaults)
                    % If FileExtensions is already provided, then none of the files
                    % contain the specified file extensions.
                    givenExts = nvStruct.FileExtensions;
                    if iscell(givenExts)
                        givenExts = strjoin(givenExts, ',');
                    end
                    error(message('MATLAB:datastoreio:filebaseddatastore:fileExtensionsNotPresent',  givenExts));
                end
                error(message('MATLAB:datastoreio:filebaseddatastore:allNonstandardExtensions'));
            end
        end

        function files = convertFileSetToFiles(files)
            if isa(files,'matlab.io.datastore.DsFileSet')
                files = matlab.io.datastore.internal.getFileNamesFromFileSet(files);
            end
        end

        function [data, info] = errorHandlerRoutine(ds, ME, varargin)
            isReadAll = false;

            % call from preview should error
            if ds.PreviewCall
                ds.PreviewCall = false;
                throwAsCaller(ME);
            end
            if nargin == 5
                % special handling for ImageDatastore which passes in filename and whether the
                % call came from readall
                splitIdx = varargin{2};
                isReadAll = varargin{3};
            elseif isempty(varargin) || ischar(varargin{1}) || isstring(varargin{1})
                if ds.ErrorSplitIdx
                    % special case for TallDatastore
                    splitIdx = ds.ErrorSplitIdx;
                    ds.SplitIdx = splitIdx;
                else
                    % get split index property from datastore
                    splitIdx = ds.SplitIdx;
                end
            else
                % special case for ImageDatastore/readimage
                splitIdx = varargin{1};
            end

            try
                validateattributes(splitIdx,{'numeric'},{'integer','positive','scalar'});
            catch
                throwAsCaller(ME);
            end
            dsClass = class(ds);

            if strcmpi(ds.PrivateReadFailureRule,'skipfile')
                % move to the next file and return an empty data for this file
                if ~isa(ds.Splitter.Files,'matlab.io.datastore.DsFileSet')
                    fileIdx = ds.Splitter.Splits(splitIdx).FileIndex;
                    if fileIdx <= numel(ds.Splitter.Splits) 
                        ds.PrivateReadFailuresList(fileIdx) = 1;
                    else
                        ds.PrivateReadFailuresList(splitIdx) = 1;
                    end
                else
                    ds.PrivateReadFailuresList(splitIdx) = 1;
                end
                if (ds.MaxFailures >= 1 && sum(ds.PrivateReadFailuresList) > ds.MaxFailures) ...
                        || (sum(ds.PrivateReadFailuresList) > numel(ds.Files)*ds.MaxFailures)
                    % restore previous results
                    try
                        % this could fail for TallDatastore, ignore error
                        ds.moveToSplit(splitIdx);
                    catch
                    end
                    error(message('MATLAB:datastoreio:filebaseddatastore:maxErrorsExceeded'));
                end

                if ~isa(ds.Splitter.Files,'matlab.io.datastore.DsFileSet')
                    currFilename = ds.Splitter.Splits(splitIdx).Filename;
                    info = struct('Filename',currFilename,'FileSize',ds.Splitter.Splits(splitIdx).FileSize);
                else
                    currFilename = varargin{1};
                end

                % display read failure warning only for the first read failure
                if ~isReadAll
                    dispFirstFailureWarning(ds,currFilename);
                end

                switch dsClass
                    case 'matlab.io.datastore.SpreadsheetDatastore'
                        data = matlab.io.datastore.TabularDatastore.emptyTabular(ds,ds.SelectedVariableNames);
                        info.SheetNames = {};
                        info.SheetNumbers = [];
                        info.NumDataRows = [];
                    case 'matlab.io.datastore.TabularTextDatastore'
                        data = matlab.io.datastore.TabularDatastore.emptyTabular(ds,ds.SelectedVariableNames);
                        info.NumCharactersRead = 0;
                        info.Offset = 0;
                    case 'matlab.io.datastore.ImageDatastore'
                        data = [];
                        info = struct('Filename',currFilename,'FileSize',[],'Label',{});
                    case 'matlab.io.datastore.KeyValueDatastore'
                        data = matlab.io.datastore.TabularDatastore.emptyTabular(ds,{'Key','Value'});
                        info.Offset = 0;
                        ds.SplitReader.ReadingDone = true;
                    case 'matlab.io.datastore.TallDatastore'
                        prevData = preview(ds);
                        data = matlab.io.datastore.TabularDatastore.emptyTabular(ds,prevData.Properties.VariableNames);
                    case 'matlab.io.datastore.FileDatastore'
                        if ds.UniformRead
                            prevData = preview(ds);
                            data = matlab.io.datastore.TabularDatastore.emptyTabular(ds,prevData.Properties.VariableNames);
                        else
                            data = [];
                        end
                        ds.SplitReader.ReadingDone = true;
                    case 'audioDatastore'
                        data = [];
                        info = struct('Filename',currFilename,'Label',[],'SampleRate',[]);
                    case 'matlab.io.datastore.MDFDatastore'
                        data = matlab.io.datastore.TabularDatastore.emptyTabular(ds,ds.SelectedChannelNames');
                        info = struct('Filename',currFilename, 'FileSize', ds.SplitReader.Split.FileSize, 'MDFFileProperties', []);
                end
                ds.ErrorSplitIdx = 0;
            else
                % move back to the split which errored, not for
                % KeyValueDatastore and TallDatastore since reset/hasdata can fail.
                if ~any(strcmpi(class(ds),{'matlab.io.datastore.KeyValueDatastore', ...
                        'matlab.io.datastore.TallDatastore'}))
                    ds.moveToSplit(splitIdx);
                end
                throwAsCaller(ME);
            end
        end
    end
end

function partitionFolders(partds, partitionStrategy, partitionIndex)
    % Only recompute the Folders property when necessary.
    if isa(partds, "matlab.io.datastore.FoldersPropertyProvider")
        partds.partitionFoldersProperty(partitionStrategy, partitionIndex);
    end
end
