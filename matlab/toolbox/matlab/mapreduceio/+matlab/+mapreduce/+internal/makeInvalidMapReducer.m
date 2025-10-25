function obj = makeInvalidMapReducer()
% Make an invalid reference to a matlab.mapreduce.MapReducer.

%   Copyright 2024 The MathWorks, Inc.

obj = matlab.lang.invalidHandle("matlab.mapreduce.SerialMapReducer");
end