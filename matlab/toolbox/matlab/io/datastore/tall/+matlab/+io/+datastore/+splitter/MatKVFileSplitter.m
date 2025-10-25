classdef MatKVFileSplitter < matlab.io.datastore.splitter.WholeFileSplitter
%MATKVFILESPLITTER Splitter for splitting key value mat files.
%    A splitter that creates splits from all the mat files provided that
%    contain key value pairs. All the mat files must have two variables,
%    'Key' and 'Value'. 'Key' can either be a cell array of strings or a
%    numeric vector of length equal to number of keys. 'Values' are always
%    a cell array of length equal to number of keys.
%
% See also - matlab.io.datastore.KeyValueDatastore

%   Copyright 2015-2018 The MathWorks, Inc.

    properties (Constant, Access = private)
        % Allowed key and value variable names in the MAT-Files provided.
        MAT_FILE_KEY_VALUE_VARIABLES = {'Key', 'Value'};
        % From 15a we added a SchemaVersion variable to the MAT-Files
        MAT_FILE_THREE_VARIABLES = {'Key', 'SchemaVersion', 'Value'};
        % Allowed value variable names in the MAT-Files provided.
        % This is to support TallDatastore with only Values.
        MAT_FILE_VALUE_VARIABLES = {'SchemaVersion', 'Value'};
        % Filename suffix for TallDatastore MAT-files
        SNAPSHOT_SUFFIX_STR = 'snapshot';
        HEX_PREFIX_STR = '0x';
    end

    properties (Hidden)
        PrivateReadFailuresList;
    end

    methods (Access = protected)
        function splitter = MatKVFileSplitter(splits)
            % This function is the constructor for this class, and calls
            % the constructor for the WholeFileSplitter class.
            splitter@matlab.io.datastore.splitter.WholeFileSplitter(splits);
        end
    end

    properties (Hidden, Transient)
        % Data type of keys
        KeyType = [];
    end

    methods (Static)
        function splitter = create(fileInfo)
            narginchk(1,2);
            files = fileInfo.Files;
            if ischar(files)
                files = { files };
            end
            import matlab.io.datastore.splitter.MatKVFileSplitter
            import matlab.io.datastore.splitter.WholeFileSplitter

            % use WholeFileSplitter to create splits, remove unrequired
            % fields from the "splits" struct.
            splits = WholeFileSplitter.createArgs(fileInfo.Files, fileInfo.FileSizes);
            % Adding additional struct properties
            if ~isempty(splits)
                [splits.ValuesOnly] = deal(fileInfo.ValuesOnly);
                for ii = 1 : numel(splits)
                    splits(ii).SchemaAvailable = fileInfo.SchemaAvailable(ii);
                end     
            end
            splitter = MatKVFileSplitter(splits);
            splitter.PrivateReadFailuresList = zeros(numel(files),1);

            if ~isempty(files)
                if ~iscellstr(files)
                    error(message('MATLAB:datastoreio:filesplitter:invalidFilesInput'));
                end
            end
        end

        function splitter = createFromSplits(splits)
            % Create a splitter from given splits
            import matlab.io.datastore.splitter.MatKVFileSplitter;
            import matlab.io.datastore.splitter.WholeFileSplitter

            % use WholeFileSplitter to create splits
            if ~isempty(splits) && ~any(contains(fieldnames(splits),'FileSize'))
                for ii = 1 : length(splits)
                    splits(ii).FileSize = splits(ii).Size;
                end
            end
            splits = WholeFileSplitter.createFromSplitsArgs(splits);
            splitter = MatKVFileSplitter(splits);            
        end
    end

    methods (Static, Hidden)
        function tf = verifyKeysValues(fileInfo, valuesOnly)
            % Check if all the mat files have MAT_FILE_NUM_VARIABLES number of
            % variables, variable names equal to MAT_FILE_KEY_VALUE_VARIABLES, and
            % they are column vectors of same length.
            import matlab.io.datastore.splitter.MatKVFileSplitter;
            if valuesOnly
                tf = MatKVFileSplitter.verifyValuesOnly(fileInfo);
                return;
            end
            numVars = numel(fileInfo);
            tf = false;
            switch numVars
                % Number of variables must be 2 or 3
                % Variable names must be MAT_FILE_KEY_VALUE_VARIABLES
                % or MAT_FILE_THREE_VARIABLES
                case 2
                    tf = all(strcmp({fileInfo.name}, MatKVFileSplitter.MAT_FILE_KEY_VALUE_VARIABLES));
                case 3
                    tf = all(strcmp({fileInfo.name}, MatKVFileSplitter.MAT_FILE_THREE_VARIABLES));
                otherwise
                   return; 
            end
            if ~tf
                return;
            end
            ks = fileInfo(1).size;
            vs = fileInfo(numVars).size;
            % Variables must be column vectors of same length.
            tf = numel(ks) == 2  && numel(vs) == 2 && ...
                    ks(2) == 1 && vs(2) == 1 && ks(1) == vs(1);
        end

        % Verify the Value shape in the MAT-file 
        function tf = verifyValuesOnly(fileInfo)
            import matlab.io.datastore.splitter.MatKVFileSplitter;
            numVars = numel(fileInfo);
            tf = false;
            if ~all(strcmp({fileInfo.name}, MatKVFileSplitter.MAT_FILE_VALUE_VARIABLES))
                return;
            end
            vs = fileInfo(numVars).size;
            % Variable Value must be a column vector.
            tf = numel(vs) == 2 && vs(2) == 1;
        end

        % Check if a MAT-file is supported
        % matFileInfo is a struct from whos function 
        function [tf, matFileInfo] = isMatSupported(filename, valuesOnly, fileSize)
            % Use whos to introspect size and variable names in a mat file.
            % Constructing a matfile object to find the sizes and the variable
            % names would take double the time, compared to whos.
            import matlab.io.datastore.splitter.MatKVFileSplitter;
            import matlab.io.datastore.internal.filesys.vfsfun;
            
            tf = false;
            matFileInfo = [];
            warningId = 'MATLAB:whos:UnableToRead';
            warning('off', warningId);
            c = onCleanup(@() warning('on', warningId));
            
            try
                s = struct('Filename', filename, 'FileSize', fileSize);
                matFileInfo = vfsfun(@(f) whos('-file', f), s);
                
                if ~isempty(matFileInfo)
                    tf = MatKVFileSplitter.verifyKeysValues(matFileInfo, valuesOnly);
                end
            catch e %#ok<NASGU>
                % swallow the error and return
            end
        end

        % filter MAT-files that are supported
        % FileInfo contains information needed to create splits
        function [fileInfo, tf, idx] = filterMatFiles(files, valuesOnly, fileSizesBytes)
            import matlab.io.datastore.splitter.MatKVFileSplitter;
            fileInfo = [];
            tf = true;
            idx = -1;
            numFiles = numel(files);
            isMat = false(numFiles, 1);
            fileSizes = zeros(numFiles, 1);
            schemaAvailable = false(numFiles, 1);
            valuesOnlyAvailable = false(numFiles, 1);
            for ii = 1:numFiles
                if valuesOnly
                    info = iParseValuesOnlyFilename(files{ii}, fileSizesBytes(ii));
                else
                    [~, info] = MatKVFileSplitter.isMatSupported(files{ii}, valuesOnly, fileSizesBytes(ii));
                end
                if ~isempty(info)
                    isMat(ii) = true;
                    if valuesOnly
                        schemaAvailable(ii) = true;
                        valuesOnlyAvailable(ii) = true;
                        % Get the Value size
                        fileSizes(ii) = info.size;
                    else
                        % Get the Key size
                        fileSizes(ii) = info(1).size(1);
                        if numel(info) == 3
                            % SchemaVersion is available from 15a
                            schemaAvailable(ii) = true;
                        end
                    end
                elseif nargout > 1
                    % No need to fillout the fileInfo
                    % Return with index of the file that's not supported
                    tf = false;
                    idx = ii;
                    return;
                end
            end
            fileInfo.Files = files(isMat);
            fileInfo.FileSizes = fileSizes(isMat);
            fileInfo.SchemaAvailable = schemaAvailable(isMat);
            fileInfo.ValuesOnlyAvailable= valuesOnlyAvailable(isMat);
        end
    end

    properties
        % Sizes of all files
        FileSizes;
        % KeyValueLimit for SplitReaders
        KeyValueLimit;
    end

    methods (Hidden)

        function setFilesOnSplits(splitter, files)
            t = struct2table(splitter.Splits);
            t.Filename = files;
            splitter.Splits = table2struct(t);
        end

        function data = readAllSplits(splitter,readfailrule, maxfails)
            % Read all of the data from all the splits
            % This uses ValuesOnly boolean from the split information
            % to decide if only Values to be read from MAT-Files or not.
            warning('off', 'MATLAB:MatFile:OlderFormat');
            c = onCleanup(@()warning('on', 'MATLAB:MatFile:OlderFormat'));
            data = table;
            if isempty(splitter.Files) || isempty(splitter.Splits)
                return;
            end
            numSplits = splitter.NumSplits;
            datasize = 0;
            splitSizeLimit = splitter.Splits(1).Size;

            datacumsizes = zeros(1, numSplits);
            failFlag = strcmpi(readfailrule,'skipfile');
            for ii = 1:numSplits
                split = splitter.Splits(ii);
                splitSize = split.Size;
                endSize = split.Size - split.Offset + 1;
                if endSize < splitSize
                    splitSize = endSize;
                end
                datasize = datasize + splitSize;
                if ii == 1
                    datacumsizes(ii) = splitSize;
                else
                    datacumsizes(ii) = datacumsizes(ii-1) + splitSize;
                end
            end
            import matlab.io.datastore.splitreader.MatKVFileSplitReader;
            import matlab.io.datastore.splitter.MatKVFileSplitter;
            rdr = MatKVFileSplitReader(numel(splitter.Files), splitSizeLimit);
            rdr.Split = splitter.Splits(1);
            valuesOnly = rdr.Split.ValuesOnly;
            reset(rdr);
            [Key, Value] = readFullSplit(rdr, datacumsizes(1));
            if ~valuesOnly
                % Keys are not needed if ValuesOnly, for example in case of TallDatastore
                if iscell(Key)
                    data.Key = cell(datasize, 1);
                elseif isnumeric(Key)
                    data.Key = zeros(datasize, 1, 'like', Key);
                end
            end
            if ~isempty(Value)
                if iscell(Value)
                    data.Value = cell(datasize, 1);
                elseif isnumeric(Value)
                    data.Value = zeros(datasize, 1, 'like', Value);
                end
            end
            keyClass = class(Key);
            valueClass = class(Value);
            if ~valuesOnly
                % Keys are not needed if ValuesOnly, for example in case of TallDatastore
                data.Key(1:datacumsizes(1), 1) = Key;
            end
            data.Value(1:datacumsizes(1), 1) = Value;
            for ii = 2:numSplits
                splitSize = datacumsizes(ii) - datacumsizes(ii-1);
                rdr.Split = splitter.Splits(ii);
                try
                    reset(rdr);
                    [Key, Value] = readFullSplit(rdr, splitSize);
                catch e
                    if failFlag
                        [splitter, rdr] = handleException(splitter, rdr, maxfails, ii);
                        continue;
                    else
                        throwAsCaller(e);
                    end
                end
                stidx = datacumsizes(ii-1) + 1;
                if ~valuesOnly
                    % Keys are not needed if ValuesOnly, for example in case of TallDatastore
                    try
                        data.Key(stidx:datacumsizes(ii), 1) = Key;
                    catch e
                        % keys are of different data types, handle exception
                        if failFlag
                            [splitter, rdr] = handleException(splitter, rdr, maxfails, ii);
                            continue;
                        else
                            MatKVFileSplitter.invalidKeyValueError(keyClass, class(Key),...
                                splitter.Splits(1).Filename, splitter.Splits(ii).Filename, e, true);
                        end
                    end
                end
                try
                    data.Value(stidx:datacumsizes(ii), 1) = Value;
                catch e
                    % values are of different types, handle exception
                    if failFlag
                        [splitter, rdr] = handleException(splitter, rdr, maxfails, ii);
                    else
                        MatKVFileSplitter.invalidKeyValueError(valueClass, class(Value), ...
                            splitter.Splits(1).Filename, splitter.Splits(ii).Filename, e, false);
                    end
                end
            end
            if failFlag && sum(splitter.PrivateReadFailuresList)
                warning('off','backtrace');
                warning(message('MATLAB:datastoreio:filebaseddatastore:warnReadall'));
                warning('on','backtrace');
            end
        end

        % handle exceptions when ReadFailureRule is set to skipfile
        function [splitter, rdr] = handleException(splitter, rdr, maxfails, ii)
            splitter.PrivateReadFailuresList(ii) = 1;
            rdr.ReadingDone = true;
            if (maxfails >= 1 && sum(splitter.PrivateReadFailuresList) > maxfails) ...
                    || (sum(splitter.PrivateReadFailuresList) > numel(splitter.Files)*maxfails)
                error(message('MATLAB:datastoreio:filebaseddatastore:maxErrorsExceeded'));
            end
        end

        % set all splits to have the SchemaAvailable field to the
        % given boolean.
        function setSchemaAvailable(splitter, tf)
            [splitter.Splits.SchemaAvailable] = deal(tf);
        end

        % set all splits to have the ValuesOnly field to the
        % given boolean.
        function setSplitsWithValuesOnly(splitter, tf)
            [splitter.Splits.ValuesOnly] = deal(tf);
        end

        % Return a reader for the ii-th split.
        function rdr = createReader(splitter, ii)
            rdr = matlab.io.datastore.splitreader.MatKVFileSplitReader(...
                    numel(splitter.Files), splitter.KeyValueLimit);
            rdr.Split = splitter.Splits(ii);
            rdr.KeyType = splitter.KeyType;
            rdr.Filename = splitter.Splits(ii).Filename;
            if ii > 1
                rdr.PrevFilename = splitter.Splits(ii-1).Filename;
            else
                rdr.PrevFilename = rdr.Filename;
            end
        end

        % Create Splitter from existing Splits
        %
        % Splits passed as input must be of identical in structure to the
        % splits used by this Splitter class.
        function splitterCopy = createCopyWithSplits(splitter, splits)
            splitterCopy = splitter.createFromSplits(splits);
            splitterCopy.KeyValueLimit = splitter.KeyValueLimit;
        end
    end
    methods (Static, Access = private)
        function invalidKeyValueError(c1, c2, f1, f2, e, keyError)
            if strcmp(e.identifier, 'MATLAB:invalidConversion')
                msgid = 'MATLAB:datastoreio:keyvaluedatastore:invalidKeyConversion';
                if ~keyError
                    msgid = 'MATLAB:datastoreio:keyvaluedatastore:invalidValueConversion';
                end
                msg = message(msgid, c1, c2, f1, f2);
                throw(MException(msg));
            end
            throw(e);
        end
    end
end

% Parse the filename when ValuesOnly is true - for TallDatastore.
% For example:
%    From tall/write, filename could be of the form 'array_r10_1_snapshot_8A'
%    Here '8A' represents the number of values in the MAT-file in hex form.
%    - outInfo is a struct with the above number, when the filename matches the pattern
%    - outInfo is a struct from whos, when the filename does not match the above pattern.
function outInfo = iParseValuesOnlyFilename(fileName, fileSize)
    import matlab.io.datastore.splitter.MatKVFileSplitter;
    [~,name,ext] = fileparts(fileName);
    pattern = ['\w*_',...
              MatKVFileSplitter.SNAPSHOT_SUFFIX_STR,'_',...
              MatKVFileSplitter.HEX_PREFIX_STR,...
              '(\w*)$'];
    numKV = regexp(name, pattern, 'tokens', 'once');
    outInfo = [];
    if strcmp(ext, '.mat') && ~isempty(numKV) && ~isempty(numKV{1})
        try
            % convert the hex number of values to decimal
            outInfo.size = hex2dec(numKV{1});
        catch
            % swallow and use legacy support check
        end
    end
    if isempty(outInfo)
        % Legacy MAT-file support check:
        % Use whos to find if the MAT-file is supported.
        % We reach here if the filenames are changed manually
        % or MAT-file is constructed manually
        % or if the file is not from tall/write 
        [~, info] = MatKVFileSplitter.isMatSupported(fileName, true, fileSize);
        if ~isempty(info)
            if numel(info) < 2
                % invalid MAT-file, error
                error(message('MATLAB:datastoreio:keyvaluedatastore:unexpectedFileType','MAT-',fileName));
            end
            outInfo.size = info(2).size(1);
        end
    end
end
