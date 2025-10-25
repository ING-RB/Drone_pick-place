classdef WholeFileCustomReadSplitReader < matlab.io.datastore.splitreader.SplitReader
%WHOLEFILECUSTOMREADSPLITREADER SplitReader that reads files with a custom read function.
%
% See also - matlab.io.datastore.WholeFileCustomReadDatastore

% Copyright 2015-2019 The MathWorks, Inc.

    properties
        % Split to read
        Split;

        % Read function
        ReadFcn;

        % Boolean to indicate if reading is complete
        ReadingDone = false;

        % An internal error handler that gets called when read fails.
        CustomReadErrorFcn(1, 1) function_handle = ...
            @matlab.io.datastore.exceptions.decorateCustomFunctionError;
    end

    properties (Access = protected, Transient)
        % Info struct for this Split.
        Info;
    end

    methods (Access = protected)

        function copiedObj = copyElement(obj)
            % Shallow copy
            copiedObj = copyElement@matlab.mixin.Copyable(obj);
        end
    end

    methods (Hidden)

        function pctg = progress(reader)
            % Percentage of read completion between 0.0 and 1.0 for the split.
            pctg = double(reader.ReadingDone);
        end

        function tf = hasNext(reader)
            % Return logical scalar indicating availability of data
            tf = ~reader.ReadingDone;
        end

        function [data, info] = getNext(reader)
            % Return data and info as appropriate for the datastore
            import matlab.io.datastore.mixin.RemoteToLocalFile;
            import matlab.io.datastore.splitreader.WholeFileCustomReadSplitReader;

            remote2Local = RemoteToLocalFile(reader.Split.Filename);
            try
                data = reader.ReadFcn(remote2Local.LocalFileName);
            catch ME
                reader.CustomReadErrorFcn(ME, reader.ReadFcn, reader.Split.Filename, ...
                    1, mfilename); % At least one output argument required.
            end
            info = reader.Info;
            reader.ReadingDone = true;
        end

        function reset(reader)
            % Reset the reader to the beginning of the split
            if isempty(reader.Split)
                return;
            end
            % The checks for file existence is not needed (In case,
            % the file is deleted just before reading). We let the read
            % error for full file datastores.

            % initialize the info struct to be returned by readSplitData
            reader.Info = struct('Filename', reader.Split.Filename, ...
                'FileSize', reader.Split.FileSize);
            reader.ReadingDone = false;
        end
    end
end


