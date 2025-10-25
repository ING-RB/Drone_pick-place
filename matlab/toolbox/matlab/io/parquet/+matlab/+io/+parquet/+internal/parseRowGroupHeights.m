function [heights, supplied] = parseRowGroupHeights(args, totalHeight)
%parseRowGroupHeights   parses the RowGroupHeights N-V pair out of
%   parquetwrite input arguments.
%
%   Should ALWAYS return a row vector as the height output.

%   Copyright 2021 The MathWorks, Inc.

    import matlab.io.parquet.internal.validateRowGroupHeights;

    persistent parser;
    
    if isempty(parser)
        parser = inputParser;
        parser.FunctionName = "parquetwrite";
        parser.KeepUnmatched = true;
        parser.addParameter("RowGroupHeights", missing);
    end
    
    parser.parse(args{:});

    % Handle the default case outside the persistent block.
    supplied = ~ismember("RowGroupHeights", string(parser.UsingDefaults));
    if supplied
        heights = parser.Results.RowGroupHeights;
    else
        heights = totalHeight;
    end
    
    heights = validateRowGroupHeights(heights, totalHeight);
end