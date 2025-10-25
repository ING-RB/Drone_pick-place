classdef PartialFileCustomReadSplitter < matlab.io.datastore.splitter.WholeFileCustomReadSplitter
% PARTIALFILECUSTOMREADSPLITTER Splitter for creating partial file splits with custom reader.
%
% See also - matlab.io.datastore.FileDatastore

%   Copyright 2015-2018 The MathWorks, Inc.

    methods (Static, Hidden)
        % Override static method in superclass to create PartialFileCustomReadSplitter
        function splitter = create(files, fileSizes, includeSubfolders)
            import matlab.io.datastore.splitter.WholeFileCustomReadSplitter;
            import matlab.io.datastore.splitter.PartialFileCustomReadSplitter;
            splitter = WholeFileCustomReadSplitter.create(files, fileSizes, includeSubfolders);
            splitter = PartialFileCustomReadSplitter(splitter.Splits);
        end

        % Override static method in superclass to create PartialFileCustomReadSplitter
        function splitter = createFromSplits(splits)
            import matlab.io.datastore.splitter.WholeFileCustomReadSplitter;
            import matlab.io.datastore.splitter.PartialFileCustomReadSplitter;
            splitter = WholeFileCustomReadSplitter.createFromSplits(splits);
            splitter = PartialFileCustomReadSplitter(splitter.Splits);
        end
    end

    methods (Hidden)
        % Override createReader method from superclass since we want to create
        % PartialFileCustomReadSplitReaders instead of WholeFileCustomReadSplitReaders
        function rdr = createReader(splitter, ii)
            rdr = matlab.io.datastore.splitreader.PartialFileCustomReadSplitReader;
            rdr.ReadFcn = splitter.ReadFcn;
            rdr.Split = splitter.Splits(ii);
        end
    end
end
