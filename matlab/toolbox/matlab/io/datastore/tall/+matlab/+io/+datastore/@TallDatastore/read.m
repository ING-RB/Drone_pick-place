function [data, info] = read(tds)
%READ Read data rows from a TallDatastore.
%   T = READ(TDS) reads some data rows from TDS.
%   TDS.ReadSize controls the number of data rows that are
%   read.
%   read(TDS) errors if there are no more data rows in TDS,
%   and should be used with hasdata(TDS).
%
%   [T,info] = READ(TDS) also returns a structure with additional
%   information about TDS. The fields of info are:
%      Filename - Name of the file from which data was read.
%      FileSize - Size of the file (Size of Value variable for 'mat', bytes for
%                 'seq').
%
%   Example:
%   --------
%      % Create a simple tall double.
%      t = tall(rand(500,1))
%      % Write to a new folder.
%      newFolder = fullfile(pwd, 'myTest');
%      write(newFolder, t)
%      % Create an TallDatastore from newFolder
%      tds = datastore(newFolder)
%      % read 3 data rows at a time
%      tds.ReadSize = 3
%      while hasdata(tds)
%         a3 = read(tds)
%      end
%
%   See also matlab.io.datastore.TallDatastore, hasdata, readall, preview, reset.

%   Copyright 2016-2019 The MathWorks, Inc.
try
    warning('off', 'MATLAB:MatFile:OlderFormat');
    c = onCleanup(@() warning('on', 'MATLAB:MatFile:OlderFormat'));
    readSize = tds.ReadSize;

    if tds.BufferedSize == 0
        [d, tds.BufferedInfo] = tds.readData();
        % check that buffered info is from the current split
        if tds.ErrorSplitIdx
            tds.BufferedSize = 0;
            tds.BufferedInfo = [];
            tds.BufferedData = [];
            error(message('MATLAB:datastoreio:talldatastore:unsupportedFiles', tds.FileType));
        end
        d = vertcat(d{:});
        % first dimension is the ReadSize dimension
        tds.BufferedSize = size(d, 1);

        if tds.SplitIdx == 1
            tds.FirstReadData = d;
        elseif ~isempty(tds.FirstReadData)
            % try concatenating data to see whether data types are
            % compatible
            try
                if size(tds.FirstReadData,1) > 1 && size(d,1) > 1
                    temp = [tds.FirstReadData(1:2,:); d(1:2,:)]; %#ok<NASGU>
                end
            catch ME
                error(message('MATLAB:datastoreio:talldatastore:incorrectOutputType',tds.Files{tds.SplitIdx}));
            end
        end
        tds.BufferedData = d;
    end

    if tds.BufferedSize == readSize
        data = tds.BufferedData;
        info.Filename = tds.BufferedInfo.Filename;
        info.FileSize = tds.BufferedInfo.FileSize;
        tds.BufferedSize = 0;
        return;
    end

    while tds.BufferedSize < readSize && hasNext(tds.SplitReader)
        % We are getting data from the same file, if needed.
        % Can we do hasdata and readData, instead?
        % info.Filename will be a cell array in this case.
        [d, tds.BufferedInfo] = getNext(tds.SplitReader);
        d = vertcat(d{:});
        % first dimension is the ReadSize dimension
        tds.BufferedSize = tds.BufferedSize + size(d, 1);
        try
            tds.BufferedData = vertcat(tds.BufferedData, d);
        catch
            error(message('MATLAB:datastoreio:talldatastore:incorrectOutputType',tds.Files{tds.SplitIdx}));
        end
    end

    % Get data and info, from buffered data and its info
    data = getDataUsingSubstructInfo(tds, min(readSize, tds.BufferedSize));
    if ~isempty(data)
        info.Filename = tds.BufferedInfo.Filename;
        info.FileSize = tds.BufferedInfo.FileSize;
    end
catch e
    if strcmpi(e.identifier,'MATLAB:datastoreio:splittabledatastore:noMoreData')
        throwAsCaller(e);
    end
    if ~contains(e.stack(1).file,"hasdata")
        [data, info] = matlab.io.datastore.FileBasedDatastore.errorHandlerRoutine(tds,e);
    else
        data = e;
    end
    tds.BufferedSize = 0;
    tds.BufferedInfo = [];
    tds.ErrorSplitIdx = 0;
    tds.BufferedData = [];
    if isa(data,'MException')
        throwAsCaller(data);
    end
end
end
