function link = getChartHyperlink(chartName, escapeQuotes)
%

%   Copyright 2018-2019 The MathWorks, Inc.

    if ~exist('escapeQuotes', 'var')
        escapeQuotes = false;
    end
    if ~escapeQuotes
        link = ['<a href="matlab:edit ' chartName '.sfx">''' chartName '''</a>'];
    else
        link = ['<a href="matlab:edit ' chartName '.sfx">''''' chartName '''''</a>'];
    end
end
