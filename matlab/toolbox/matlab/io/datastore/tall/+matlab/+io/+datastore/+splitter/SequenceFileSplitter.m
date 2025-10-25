classdef (Sealed, Hidden) SequenceFileSplitter < matlab.io.datastore.splitter.FileSizeBasedSplitter
%SEQUENCEFILESPLITTER Splitter to handle Sequence files.
% Helper class that wraps around FileSizeBasedSplitter to adapt this to the
% interface expected by KeyValueDatastore.

%   Copyright 2015-2018 The MathWorks, Inc.

    properties (Constant, Access = private)
        % KeyValueLimit to be set for readall.
        READALL_KEY_VALUE_LIMIT = 1000;
        % Split size analogous to hdfs block size
        DEFAULT_SEQ_SPLIT_SIZE = 64*1024*1024; % 64 MB
    end

    properties (Access = public)
        % KeyValueLimit for this Splitter
        KeyValueLimit;
    end

    properties (Hidden)
        PrivateReadFailuresList;
    end

    methods (Access = public, Hidden)
        % Required function for KeyValueDatastore/readall. Reads all data
        % from all files.
        function output = readAllSplits(splitter,readfailrule,maxfails)
            import matlab.io.datastore.splitreader.SequenceFileSplitReader;
            import matlab.io.datastore.splitter.SequenceFileSplitter;
            splitReader = SequenceFileSplitReader();
            splitReader.KeyValueLimit = SequenceFileSplitter.READALL_KEY_VALUE_LIMIT;
            splits = splitter.Splits;
            valuesOnly = false;
            if ~isempty(splits)
                valuesOnly = splits(1).ValuesOnly;
            end

            output = cell(numel(splits), 1);
            failFlag = strcmpi(readfailrule,'skipfile');
            concatFlag = 1;
            if ~valuesOnly
                % Key classes can be different. Values are always in a cell.
                % Used for throwing useful error messages.
                splitKeyClasses = cell(numel(splits), 1);
            end
            sampleData = [];
            for ii = 1:numel(splits)
                splitReader.Split = splits(ii);
                if ii > 1
                    splitReader.PrevFilename = splits(ii-1).Filename;
                else
                    splitReader.PrevFilename = splits(ii).Filename;
                end
                try
                    splitReader.reset;
                catch ME
                    if ~failFlag
                        throwAsCaller(ME);
                    else
                        % file is probably corrupted
                        splitter.PrivateReadFailuresList(ii) = 1;
                        if (maxfails >= 1 && sum(splitter.PrivateReadFailuresList) > maxfails) ...
                                || (sum(splitter.PrivateReadFailuresList) > numel(splitter.Files)*maxfails)
                            error(message('MATLAB:datastoreio:filebaseddatastore:maxErrorsExceeded'));
                        else
                            continue;
                        end
                    end
                end

                splitOutput = {};
                
                while hasNext(splitReader)
                    try
                        splitOutput{end + 1} = getNext(splitReader); %#ok<AGROW>
                        if ii == 1
                            if ~isempty(splitOutput)
                                sampleData = splitOutput{end};
                                if iscell(sampleData)
                                    sampleData = SequenceFileSplitter.createSampleData(sampleData{1});
                                else
                                    sampleData = SequenceFileSplitter.createSampleData(sampleData);
                                end
                            else
                                sampleData = [];
                            end
                        else
                            % concatenate new split with first split to verify
                            % that data is compatible for concatenation
                            newData = splitOutput{end};
                            if ~isempty(newData)
                                if isempty(sampleData)
                                    sampleData = newData;
                                else
                                    if iscell(newData)
                                        newData = SequenceFileSplitter.createSampleData(newData{1});
                                    else
                                        newData = SequenceFileSplitter.createSampleData(newData);
                                    end
                                    try
                                        concatData = [sampleData; newData]; %#ok<NASGU>
                                    catch
                                        error(message('MATLAB:datastoreio:talldatastore:incorrectOutputType', ...
                                            splitter.Splits(ii).Filename));
                                    end
                                end
                            end
                        end
                    catch ME
                        % unable to read this file
                        if failFlag
                            splitter.PrivateReadFailuresList(ii) = 1;
                            if (maxfails >= 1 && sum(splitter.PrivateReadFailuresList) > maxfails) ...
                                    || (sum(splitter.PrivateReadFailuresList) > numel(splitter.Files)*maxfails)
                                error(message('MATLAB:datastoreio:filebaseddatastore:maxErrorsExceeded'));
                            end
                            concatFlag = 0;
                            splitReader.ReadingDone = true;
                            continue;
                        else
                            throwAsCaller(ME);
                        end
                    end
                end
                if concatFlag
                    output{ii} = vertcat(splitOutput{:});
                else
                    concatFlag = 1;
                end
                if ~valuesOnly && ~isempty(output{ii})
                    splitKeyClasses{ii} = class(output{ii}.Key);
                end
            end
            try
                output = vertcat(output{:});
            catch e
                if ~valuesOnly && strcmp(e.identifier, 'MATLAB:table:vertcat:VertcatCellAndNonCell')
                    SequenceFileSplitter.invalidKeyError(splitKeyClasses, splits);
                end
                throw(e);
            end
            % if empty, we do not want empty double array as output.
            if isempty(output)
                output = table;
            end

            if valuesOnly
                % output.Value is used in the readall of TallDatastore for both
                % MAT-files and Sequence files.
                % valuesOnly is true only for TallDatastore.
                data.Value = output;
                output = data;
            end

            if failFlag && sum(splitter.PrivateReadFailuresList)
                warning('off','backtrace');
                warning(message('MATLAB:datastoreio:filebaseddatastore:warnReadall'));
                warning('on','backtrace');
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

    end

    methods (Static, Access = private)
        function invalidKeyError(keyClasses, splits)
            if isempty(keyClasses) || numel(keyClasses) < 2
                return;
            end
            c1 = keyClasses{1};
            c2 = '';
            j = [];
            % We just need the first 2 differing key classes
            % Below for loop breaks when we find the first different class.
            % Better than [i, j, k] = unique(keyClasses).
            for ii = 2:numel(keyClasses)
                c2 = keyClasses{ii};
                if ~strcmp(c2, c1)
                    j = ii;
                    break;
                end
            end
            if ~isempty(j)
                msgid = 'MATLAB:datastoreio:keyvaluedatastore:invalidKeyConversion';
                msg = message(msgid, c1, c2, splits(1).Filename, splits(j).Filename);
                throw(MException(msg));
            end
        end
    end

    methods (Static = true)
        % Create Splitter from appropriate arguments
        function splitter = create(fileInfo)
            import matlab.io.datastore.splitter.SequenceFileSplitter;
            import matlab.io.datastore.splitter.FileSizeBasedSplitter;
            [splits, splitSize] = FileSizeBasedSplitter.createArgs(fileInfo.Files, ...
                                    SequenceFileSplitter.DEFAULT_SEQ_SPLIT_SIZE, fileInfo.FileSizes);
            splitter = SequenceFileSplitter(splits, splitSize);
        end

        % Create Splitter from existing Splits
        function splitter = createFromSplits(splits)
            import matlab.io.datastore.splitter.SequenceFileSplitter;
            import matlab.io.datastore.splitter.FileSizeBasedSplitter;
            [splits, ~] = FileSizeBasedSplitter.createFromSplitsArgs(splits);
            splitter = SequenceFileSplitter(splits, ...
                                SequenceFileSplitter.DEFAULT_SEQ_SPLIT_SIZE);
        end
    end

    methods (Static, Hidden)

        function tfArr = filterSeqFiles(files, valuesOnly)
            import matlab.io.datastore.internal.SequenceFileReader;
            numFiles = numel(files);
            tfArr = true(numFiles, 1);
            for ii = 1:numFiles
                tfArr(ii) = SequenceFileReader.isSeqSupported(files{ii}, valuesOnly);
            end
        end

        function [tf, idx] = areSeqFilesSupported(files, valuesOnly)
            import matlab.io.datastore.internal.SequenceFileReader;
            numFiles = numel(files);
            tf = true;
            idx = -1;
            for ii = 1:numFiles
                if ~SequenceFileReader.isSeqSupported(files{ii}, valuesOnly)
                    idx = ii;
                    tf = false;
                    break;
                end
            end
        end
        function sampleData = createSampleData(sampleData)
            if ~isempty(sampleData)
                if size(sampleData,1) < 2
                    sampleData = sampleData(1,:);
                else
                    sampleData = sampleData(1:2,:);
                end
            end
        end
    end

    methods (Access = private)
        % Private constructor for static build methods
        function splitter = SequenceFileSplitter(splits, splitSize)
            splitter@matlab.io.datastore.splitter.FileSizeBasedSplitter(splits, splitSize);
        end
    end

    methods (Access = 'public')
        % Create reader for the ii-th split
        function rdr = createReader(splitter, ii)
            rdr = matlab.io.datastore.splitreader.SequenceFileSplitReader;
            rdr.Split = splitter.Splits(ii);
            rdr.KeyValueLimit = splitter.KeyValueLimit;
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
        % splits used by this Spltiter class.
        function splitterCopy = createCopyWithSplits(splitter, splits)
            splitterCopy = copy(splitter);
            splitterCopy.Splits = splits;
        end
    end
end
