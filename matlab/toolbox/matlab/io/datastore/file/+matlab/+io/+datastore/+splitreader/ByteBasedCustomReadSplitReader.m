classdef ByteBasedCustomReadSplitReader ...
            < matlab.io.datastore.splitreader.WholeFileCustomReadSplitReader
%BYTEBASEDCUSTOMREADSPLITREADER SplitReader that reads files with a custom read
% function at a specified byte range.
%
% See also - matlab.io.datastore.FileDatastore

%   Copyright 2015-2018 The MathWorks, Inc.

    properties (Hidden, Transient)
        % RemoteToLocal object for downloading files from remote data sources
        RemoteToLocal;
    end

    methods (Hidden)

        function [data, info] = getNext(reader)
            % Return data and info as appropriate for the datastore
            import matlab.io.datastore.splitreader.WholeFileCustomReadSplitReader;

            try
                data = reader.ReadFcn(reader.RemoteToLocal.LocalFileName, ...
                                    reader.Split.Offset, reader.Split.Size);
            catch ME
                reader.CustomReadErrorFcn(ME, reader.ReadFcn, reader.Split.Filename, ...
                    1, mfilename); % At least one output argument required.
            end
            info = reader.Info;
            reader.ReadingDone = true;
        end
    end
end

