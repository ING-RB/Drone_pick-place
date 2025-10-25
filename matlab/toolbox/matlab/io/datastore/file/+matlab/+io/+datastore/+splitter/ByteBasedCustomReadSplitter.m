classdef ByteBasedCustomReadSplitter < matlab.io.datastore.splitter.FileSizeBasedSplitter
% BYTEBASEDCUSTOMREADSPLITTER Splitter for creating byte-based file splits with custom reader.
%
% See also - matlab.io.datastore.FileDatastore

%   Copyright 2015-2017 The MathWorks, Inc.

    properties (Hidden)
        % Custom read function
        ReadFcn;
    end
    properties (Transient)
        % Sharing a locally-downloaded copy of a file between reads
        RemoteToLocal;
    end

    methods (Static, Hidden)
        function splitter = create(files, fileSizes, splitSize, oldSplits)
            import matlab.io.datastore.splitter.FileSizeBasedSplitter;
            import matlab.io.datastore.splitter.ByteBasedCustomReadSplitter;

            % Only create new splits when necessary.
            if nargin < 4
                % Use FileSizeBasedSplitter to create splits.
                splits = FileSizeBasedSplitter.createArgs(files, splitSize, fileSizes);
            else
                splits = oldSplits;
            end

            % Add splitSize as a property on the splits
            splitter = ByteBasedCustomReadSplitter(splits);
        end

        function splitter = createFromSplits(splits)
            import matlab.io.datastore.splitter.FileSizeBasedSplitter;
            import matlab.io.datastore.splitter.ByteBasedCustomReadSplitter;

            % Use FileSizeBasedSplitter to create splits.
            newSplits = FileSizeBasedSplitter.createFromSplitsArgs(splits);
            splitter = ByteBasedCustomReadSplitter(newSplits);
        end
    end

    methods (Access = protected)
        function splitter = ByteBasedCustomReadSplitter(splits)
            splitter@matlab.io.datastore.splitter.FileSizeBasedSplitter(splits);
        end
    end

    methods (Hidden)
        % Return a reader for the ii-th split.
        function rdr = createReader(splitter, ii)
            import matlab.io.datastore.mixin.RemoteToLocalFile;
            rdr = matlab.io.datastore.splitreader.ByteBasedCustomReadSplitReader;
            rdr.ReadFcn = splitter.ReadFcn;
            rdr.Split = splitter.Splits(ii);

            % Provide a handle to the previous remoteToLocal object to the SplitReader
            % if it has the same filename.
            % This can help prevent duplicate downloads of the same file.
            if isempty(splitter.RemoteToLocal) || ...
                ~strcmp(splitter.RemoteToLocal.RemoteFileName, rdr.Split.Filename)
                splitter.RemoteToLocal = RemoteToLocalFile(rdr.Split.Filename);
            end
            rdr.RemoteToLocal = splitter.RemoteToLocal;
        end
        
        % Return file names as a cellstr for specific indices
        function files = getFilesAsCellStr(splitter, indices)
            if length(splitter.Splits) == 0
                files = {};
                return;
            end
            if nargin == 1
                files = {splitter.Splits.Filename};
            else
                files = {splitter.Splits(indices).Filename};
            end
            files = files(:);
        end

        % Return file sizes as a column vector for specific indices
        function fileSizes = getFileSizes(splitter, indices)
            if length(splitter.Splits) == 0
                fileSizes = [];
                return;
            end
            if nargin == 1
                fileSizes = [splitter.Splits.FileSize];
            else
                fileSizes = [splitter.Splits(indices).FileSize];
            end
            fileSizes = fileSizes(:);
        end

        % Create Splitter from existing Splits
        %
        % Splits passed as input must be of identical in structure to the
        % splits used by this Spltiter class.
        function splitterCopy = createCopyWithSplits(splitter, splits)
            splitterCopy = splitter.createFromSplits(splits);
            splitterCopy.ReadFcn = splitter.ReadFcn;
        end
    end
end
