function [data, info] = read(rptds)
%READ   Return the next block of data from the RepeatedDatastore.
%
%   DATA = READ(RPTDS) reads the next block of data from the RepeatedDatastore.
%       If RepeatFcn returns a value more than 1, then the current read from the
%       underlying datastore will be repeated.
%
%   [DATA, INFO] = READ(RPTDS) also returns a struct containing additional information
%       about DATA:
%        - RepetitionIndex: A scalar double integer value.
%                           Usually starts from 1 to N, where N is the value returned by RepeatFcn.
%                           If RepeatFcn returned 0, then RepetitionIndex will be [].
%
%   See also: matlab.io.datastore.internal.RepeatedDatastore

%   Copyright 2021 The MathWorks, Inc.

    if ~rptds.hasdata()
        msgid = "MATLAB:io:datastore:common:read:NoMoreData";
        error(message(msgid));
    end

    % If the InnerDatastore is empty, find the number of repetitions and
    % construct a new InnerDatastore.
    if ~rptds.InnerDatastore.hasdata()

        % Move on to the next read from the UnderlyingDatastore.
        [rptds.CurrentReadData, rptds.CurrentReadInfo] = rptds.UnderlyingDatastore.read();
        readIndex = double(rptds.UnderlyingDatastoreIndex.read());

        % Get the list of repetitions for this read.
        repetitions = rptds.computeRepetitionIndices(readIndex, ...
                                                     rptds.CurrentReadData, ...
                                                     rptds.CurrentReadInfo);

        % Construct a new InnerDatastore based on the repetition counts.
        rptds.InnerDatastore = arrayDatastore(repetitions, OutputType="same");
    end

    % data and info are just copied from the cached values.
    data = rptds.CurrentReadData;
    info = rptds.CurrentReadInfo;

    % Add the RepetitionIndex on the info struct.
    repetitionIndex = rptds.InnerDatastore.read();
    if repetitionIndex == 0
        % Change 0 to [] when reading. This is easier for clients like
        % parquetread and sheetnames to use since 0 is considered an
        % invalid index in MATLAB.
        % Another reason for [] over 0 is: if we add ReadSize to this
        % datastore, then [] implies "read nothing", as opposed to 0 which
        % implies "read the 0th thing".
        repetitionIndex = [];
    end

    % Only add the RepetitionIndex if the info is a struct.
    % TODO: Maybe a separated cell would be better, like on CombinedDatastore?
    if isstruct(info)
        [info.RepetitionIndex] = deal(repetitionIndex);
    end
end
