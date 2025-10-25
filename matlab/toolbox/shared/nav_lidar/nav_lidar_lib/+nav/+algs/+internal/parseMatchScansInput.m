function parsedInputs = parseMatchScansInput(defaults, varargin)
%This function is for internal use only. It may be removed in the future.

%PARSEMATCHSCANSINPUT Parse inputs to "matchScans" function
%   PARSEDINPUTS = parseMatchScansInput(DEFAULTS, CURRSCAN, REFSCAN,
%   varargin) parses the inputs to matchScans. In this syntax, CURRSCAN and
%   REFSCAN are lidarScan objects and name-value pairs are passed in
%   varargin.
%
%   PARSEDINPUTS = parseMatchScansInput(DEFAULTS, CURRRANGES, CURRANGLES, REFRANGES, REFANGLES, varargin)
%   specified the current and reference laser scans as raw ranges and
%   angles.

%   Copyright 2016-2020 The MathWorks, Inc.

%#codegen

    parsedInputs = struct;

    if isa(varargin{1}, 'lidarScan')
        % Syntax: PARSEDINPUTS = parseMatchScansInput(DEFAULTS, CURRSCAN, REFSCAN, varargin)

        narginchk(3,Inf);

        parsedInputs.CurrentScan = robotics.internal.validation.validateLidarScan(varargin{1}, 'matchScans', 'currScan');
        parsedInputs.ReferenceScan = robotics.internal.validation.validateLidarScan(varargin{2}, 'matchScans', 'refScan');

        nvArgsPresent = nargin > 2;
        nvArgsStartIdx = 3;
    else
        % Syntax: PARSEDINPUTS = parseMatchScansInput(DEFAULTS, CURRRANGES, CURRANGLES, REFRANGES, REFANGLES, varargin)

        narginchk(5,Inf);

        parsedInputs.CurrentScan = robotics.internal.validation.validateLidarScan(...
            varargin{1}, varargin{2}, 'matchScans', 'currRanges', 'currAngles');
        parsedInputs.ReferenceScan = robotics.internal.validation.validateLidarScan(...
            varargin{3}, varargin{4}, 'matchScans', 'refRanges', 'refAngles');

        nvArgsPresent = nargin > 4;
        nvArgsStartIdx = 5;
    end

    % Return right away with defaults if no name-value pairs are specified
    if ~nvArgsPresent
        parsedInputs.CellSize = defaults.CellSize;
        parsedInputs.InitialPose = defaults.InitialPose;
        parsedInputs.MaxIterations = defaults.MaxIterations;
        parsedInputs.ScoreTolerance = defaults.ScoreTolerance;
        parsedInputs.SolverAlgorithm = defaults.SolverAlgorithm;
        return;
    end

    % Define names and default values for name-value pairs
    names = {'CellSize', 'InitialPose', 'MaxIterations', 'ScoreTolerance', 'SolverAlgorithm'};
    defaultValues = {defaults.CellSize, defaults.InitialPose, defaults.MaxIterations, ...
                     defaults.ScoreTolerance, defaults.SolverAlgorithm};

    % Parse name-value pairs
    parser = robotics.core.internal.NameValueParser(names, defaultValues);
    parse(parser, varargin{nvArgsStartIdx:end});

    cellSize = parameterValue(parser, 'CellSize');
    initialPose = parameterValue(parser, 'InitialPose');
    maxIterations = parameterValue(parser, 'MaxIterations');
    scoreTolerance = parameterValue(parser, 'ScoreTolerance');
    solverAlgorithm = parameterValue(parser, 'SolverAlgorithm');

    % Validate values of name-value pairs
    validateattributes(cellSize, {'numeric'}, {'nonempty', 'scalar', 'real', ...
                        'nonnan', 'finite', 'positive'}, 'matchScans', 'CellSize')
    parsedInputs.CellSize = double(cellSize);

    parsedInputs.InitialPose = robotics.internal.validation.validateMobilePose(...
        initialPose, 'matchScans', 'InitialPose');

    validateattributes(maxIterations, {'numeric'}, {'nonempty', 'scalar', 'real', ...
                        'nonnan', 'finite', 'integer', 'positive'}, 'matchScans', 'MaxIterations')
    parsedInputs.MaxIterations = double(maxIterations);

    validateattributes(scoreTolerance, {'numeric'}, {'nonempty', 'scalar', 'real', ...
                        'nonnan', 'finite', 'nonnegative'}, 'matchScans', 'ScoreTolerance')
    parsedInputs.ScoreTolerance = double(scoreTolerance);

    parsedInputs.SolverAlgorithm = validatestring(solverAlgorithm, {'trust-region', 'fminunc'}, 'matchScans', 'SolverAlgorithm');
end
