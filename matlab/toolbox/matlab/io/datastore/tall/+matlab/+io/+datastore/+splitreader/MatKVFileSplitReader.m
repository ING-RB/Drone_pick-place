classdef MatKVFileSplitReader < matlab.io.datastore.splitreader.SplitReader
%MATKVFILESPLITREADER SplitReader for reading key value mat file splits.
%    A split reader that reads key value pair data off of an assigned Split
%    struct. The splits are assigned by the SplittableDatastore, when this
%    split reader runs out of data to read. MATKVFILESPLITREADER reads
%    KeyValueLimit number of key value pairs in the mat file specified by
%    the Split struct.
%
% See also - matlab.io.datastore.KeyValueDatastore

%   Copyright 2015-2018 The MathWorks, Inc.

    properties (Hidden)
        % Split to read
        Split;
        % Number of key value pairs to read
        KeyValueLimit;
        % File type in the info struct returned by getNext
        FileType;
        % To obtain only the values.
        ValuesOnly;
    end

    properties (Access = private)
        % Number of files from Splitter.
        NumFiles;
    end

    properties (Access = private, Transient)
        % Index from which to read KeyValueLimit number of key value pairs.
        StartIdx;
        % A cache of mat file objects indexed by FileIndex provided by the Split.
        MatFileObjects;
        % Current KeyValue Object or MatFile Object
        CurrentObject;
        % Info struct fo this Split.
        Info;
        % End index on the file.
        SplitEnd;
    end

    properties (Hidden, Transient)
        ReadingDone = false; % boolean to indicate if reading is complete
        % Data type of keys
        KeyType = [];
        % The filename currently being read.
        Filename;
        % The file that was read prior to the current file
        PrevFilename;
    end

    methods
        function rdr = MatKVFileSplitReader(numfiles, keyValueLimit)
            rdr.NumFiles = numfiles;
            rdr.MatFileObjects = cell(numfiles, 1);
            rdr.FileType = 'mat';
            rdr.KeyValueLimit = keyValueLimit;
            rdr.ValuesOnly = false;
        end
    end

    methods (Access = public, Hidden)

        function frac = progress(rdr)
        % Percentage of read completion between 0.0 and 1.0 for the split.
            splitSize = rdr.SplitEnd;
            % subtracting one to make this a zero-based index.
            keyValueLimit = rdr.StartIdx - 1;
            frac = min(keyValueLimit/splitSize, 1.0);
        end

        function tf = hasNext(rdr)
        % Return logical scalar indicating availability of data
            tf = ~isempty(rdr.Split) && rdr.StartIdx <= rdr.Split.Size && ~rdr.ReadingDone;
        end

        function [data, info] = getNext(rdr)
        % Return data and info as appropriate for the datastore
            import matlab.io.datastore.splitreader.MatKVFileSplitReader;
            endidx = rdr.StartIdx + rdr.KeyValueLimit - 1;
            if endidx > rdr.SplitEnd
                endidx = rdr.SplitEnd;
            end
            rdr.Info.Offset = rdr.StartIdx;
            info = rdr.Info;
            value = rdr.CurrentObject.Value(rdr.StartIdx:endidx, 1);
            if rdr.ValuesOnly
                data = value;
            else
                data = table;
                tempKey = rdr.CurrentObject.Key(rdr.StartIdx:endidx, 1);
                if isempty(rdr.KeyType)
                    rdr.KeyType = class(tempKey);
                    rdr.Split.KeyType = rdr.KeyType;
                elseif ~strcmpi(class(tempKey),rdr.KeyType)
                    MatKVFileSplitReader.invalidKeyError(rdr.KeyType, ...
                        class(tempKey),rdr.PrevFilename, rdr.Filename);
                end
                data.Key = tempKey;
                data.Value = value;
            end
            rdr.StartIdx = endidx + 1;
            rdr.Split.Offset = rdr.StartIdx;
        end

        function reset(rdr)
        % Reset the reader to the beginning of the split
            import matlab.io.datastore.internal.isIRI
            
            if isempty(rdr.Split)
                return;
            end
            % initialize the index from which to read
            startOffset = rdr.Split.Offset;
            if startOffset > 0
                rdr.StartIdx = startOffset;
            else
                rdr.StartIdx = 1;
            end
            rdr.ReadingDone = false;

            if ~isIRI(rdr.Split.Filename) && exist(rdr.Split.Filename, 'file') ~=2
                error(message('MATLAB:datastoreio:pathlookup:fileNotFound',rdr.Split.Filename));
            end
            rdr.SplitEnd = rdr.Split.Size;
            setMatKVReadBuffer(rdr);
            % initialize the info struct to be returned by getNext
            rdr.Info = struct('FileType', rdr.FileType, ...
                'Filename', rdr.Split.Filename, ...
                'FileSize', rdr.Split.Size, ...
                'Offset', rdr.Split.Offset);
        end

        function [key, value] = readFullSplit(rdr, splitSize)
            startOffset = rdr.Split.Offset;
            if startOffset == 0
                startOffset = 1;
            end
            endidx = startOffset + splitSize - 1;
            key = [];
            if ~rdr.ValuesOnly
                key = rdr.CurrentObject.Key(startOffset:endidx, 1);
            end
            value = rdr.CurrentObject.Value(startOffset:endidx, 1);
        end

        % Used only by TallDatastore for best ReadSize and preview
        % This gets the buffered value in the underlying file container - MAT-Files
        function v = getBufferedValue(rdr)
            v = zeros(0,1); % empty matrix if Split is empty
            if rdr.ValuesOnly && ~isempty(rdr.Split) 
                % MAT-Files have a table of Value variable.
                % Value variable is always a cell 
                v = rdr.CurrentObject.Value;
                if isempty(v)
                    return;
                end
                % get the first value from the buffered Value.
                v = v{1};
            end
        end
    end

    methods (Access = private)
        % Set the read buffer for the split held on to by this SplitReader 
        function setMatKVReadBuffer(rdr)
            split = rdr.Split;
            if (split.SchemaAvailable)
                if isempty(rdr.CurrentObject) || (~isempty(rdr.CurrentObject) && ...
                        (isa(rdr.CurrentObject,'matlab.io.datastore.internal.MatValueReadBuffer') || ...
                        isa(rdr.CurrentObject,'matlab.io.datastore.internal.MatKVReadBuffer')) && ...
                        ~strcmp(rdr.CurrentObject.Source, split.Filename)) || ...
                        (~isempty(rdr.CurrentObject) && isa(rdr.CurrentObject,'matlab.io.MatFile') && ... 
                        ~strcmp(rdr.CurrentObject.Properties.Source, split.Filename))
                    try
                        rdr.setKVOrValueBuffer(split);
                    catch ME
                        throwAsCaller(ME);
                    end
                end
                return;
            end
            if isempty(rdr.MatFileObjects)
                rdr.MatFileObjects = cell(rdr.NumFiles, 1);
            end
            if isempty(rdr.MatFileObjects{split.FileIndex})
                rdr.MatFileObjects{split.FileIndex} = matfile(split.Filename);
            end
            rdr.CurrentObject = rdr.MatFileObjects{split.FileIndex};
        end

        % Set either ValueOnly read buffer or KeyValue read buffer
        function setKVOrValueBuffer(rdr, split)
            if isfield(split, 'ValuesOnly') && split.ValuesOnly
                rdr.CurrentObject = matlab.io.datastore.internal.MatValueReadBuffer(split);
                rdr.ValuesOnly = true;
            else
                rdr.CurrentObject = matlab.io.datastore.internal.MatKVReadBuffer(split);
            end
        end
    end
    methods (Static, Access = private)
        function invalidKeyError(c1, c2, f1, f2)
            msgid = 'MATLAB:datastoreio:keyvaluedatastore:invalidKeyConversion';
            msg = message(msgid, c1, c2, f1, f2);
            throw(MException(msg));
        end
    end
end
