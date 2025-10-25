% Makes the ND Summary string

% Copyright 2017-2024 The MathWorks, Inc.

function summarString = makeNDSummaryString(size, numRows, class)
    import internal.matlab.variableeditor.peer.PeerDataUtils;
    summaryString = '1';
    for sz = size
        summaryString = [summaryString, internal.matlab.datatoolsservices.FormatDataUtils.TIMES_SYMBOL, num2str(sz)]; %#ok<AGROW>
    end
    summaryString = [summaryString, ' ', class];
    summarString = repmat({summaryString}, numRows, 1);
end
