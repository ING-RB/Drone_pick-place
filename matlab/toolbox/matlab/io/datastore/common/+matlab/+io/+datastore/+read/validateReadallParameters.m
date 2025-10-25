function tf = validateReadallParameters(varargin)
%VALIDATEREADALLINPUTPARAMS Validate input parameters for datastore readall
%   and return the value of UseParallel

%   Copyright 2020 The MathWorks, Inc.

    % check whether the NV pair passed in is UseParallel
    readallInputParser = inputParser;
    addParameter(readallInputParser, "UseParallel", false);
    readallInputParser.KeepUnmatched = true;
    readallInputParser.parse(varargin{:});

    % Copy the results out of the InputParser instance.
    nvStruct = readallInputParser.Results;
    if ~isempty(fieldnames(readallInputParser.Unmatched))
        error(message("MATLAB:datastoreio:datastorereadall:UnrecognizedName"));
    end

    % Return the value of the UseParallel NV pair
    validateattributes(nvStruct.UseParallel, {'logical'}, {'scalar'}, 'readall', 'UseParallel');
    tf = logical(nvStruct.UseParallel);
end