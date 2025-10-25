%

% Copyright 2022 The MathWorks, Inc.

function res = getResults(varargin)

% Construct the builder (can throw an error)
resBuilder = matlab.coverage.internal.ResultBuilder(varargin{:});

% Create the matlab.coverage.Result objects
res = resBuilder.create();
