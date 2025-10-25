function nvStruct = parseNVPairs(varargin)
%

%   Copyright 2020 The MathWorks, Inc.

    persistent parser
    if isempty(parser)
        parser = inputParser;
        parser.FunctionName = "matlab.io.datastore.ArrayDatastore";
        parser.addParameter("ReadSize",               1);
        parser.addParameter("IterationDimension",     1);
        parser.addParameter("OutputType",             "cell");
        parser.addParameter("ConcatenationDimension", 1);
    end

    parser.parse(varargin{:});
    nvStruct = parser.Results;
end
