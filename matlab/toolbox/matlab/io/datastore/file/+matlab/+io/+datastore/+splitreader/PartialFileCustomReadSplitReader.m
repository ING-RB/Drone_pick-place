classdef PartialFileCustomReadSplitReader ...
           <  matlab.io.datastore.splitreader.WholeFileCustomReadSplitReader
%PARTIALFILECUSTOMREADSPLITREADER SplitReader that reads files with a custom
% read function in parts while persisting data between reads.
%
% See also - matlab.io.datastore.FileDatastore

%   Copyright 2015-2018 The MathWorks, Inc.

    properties (Hidden)
        % UserData property for user-provided metadata
        % that is persisted between reads from the same filename.
        UserData = [];
    end

    properties (Access = protected, Transient)
        % remoteToLocal handle which can be shared between multiple
        % reads so that the file does not have to be re-downloaded on
        % each new read from the same filename.
        remoteToLocal;
    end

    methods (Hidden)

        function [data, info] = getNext(reader)
            % Return data and info as appropriate for the datastore
            import matlab.io.datastore.mixin.RemoteToLocalFile;
            import matlab.io.datastore.splitreader.WholeFileCustomReadSplitReader;

            reader.remoteToLocal = RemoteToLocalFile(reader.Split.Filename);
            try
                [data, userdata, readingdone] = ...
                      reader.ReadFcn(reader.remoteToLocal.LocalFileName, reader.UserData);
            catch ME
                reader.CustomReadErrorFcn(ME, reader.ReadFcn, ...
                    reader.Split.Filename, 3, mfilename); % At least three output arguments required.
            end
            if ~isscalar(readingdone) || ~islogical(readingdone)
                msgid = "MATLAB:datastoreio:customreaddatastore:partialReadLogicalOutputTypeError";
                error(message(msgid, func2str(reader.ReadFcn)));
            end
            reader.UserData = userdata;
            reader.ReadingDone = readingdone;
            info = reader.Info;
        end

        function reset(reader)
            % Call superclass reset method
            reset@matlab.io.datastore.splitreader.WholeFileCustomReadSplitReader(reader);

            reader.UserData = [];
        end
    end
end

