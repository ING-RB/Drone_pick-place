 function reset(tds)
%RESET Reset the TallDatastore to the start of the data.
%   RESET(TDS) resets TDS to the beginning of the datastore.
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
%      % Reset to the beginning of the datastore
%      RESET(tds)
%      a3 = read(tds)
%
%   See also matlab.io.datastore.TallDatastore, read, readall, hasdata, preview

%   Copyright 2016-2018 The MathWorks, Inc.
try
    if ~isempty(tds.Splitter) && isvalid(tds.Splitter) && ...
            tds.Splitter.NumSplits ~= 0
        tds.SplitIdx = 1;
        tds.ErrorSplitIdx = 0;
        setSplitsWithValuesOnly(tds.Splitter, true);
        if ~isempty(tds.SplitReader) && isvalid(tds.SplitReader)
            tds.SplitReader.Split = tds.Splitter.Splits(tds.SplitIdx);
        else
            tds.SplitReader = createReader(tds.Splitter, tds.SplitIdx);
        end

        tds.PrivateReadCounter = false;
        tds.PrivateReadFailuresList = zeros(tds.TotalFiles,1);
        tds.BufferedData = [];
        tds.BufferedSize = 0;
        reset(tds.SplitReader);
    end
catch ME
    if strcmpi(tds.ReadFailureRule,'skipfile') && ~isempty(tds.SplitReader.Split)
        % move to the next file and return an empty double for this file
        [~,splitIdx] = ismember(tds.SplitReader.Split.Filename, tds.Files);
        tds.PrivateReadFailuresList(splitIdx) = 1;
        if splitIdx + 1 <= numel(tds.Files)
            % there are more splits
            tds.moveToSplit(splitIdx+1);
        else
            % there are no further splits remaining
            tds.SplitReader.Split = [];
        end
    else
        throwAsCaller(ME);
    end
end
end
