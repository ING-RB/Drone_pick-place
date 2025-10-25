function args = parseNamedArguments(numNamedArguments, varargin)
% Parsing name-value pairs provided as name=value syntax for tabular
% construction.

%   Copyright 2023 The MathWorks, Inc.

args = varargin;
if numNamedArguments > 0
    % Name coming from Name=Value would be a scalar string. Convert
    % it to char row vector, because tabular constructors don't allow
    % scalar strings for name-value names.
    namedArgumentsStart = numel(varargin) - 2*numNamedArguments + 1;
    [args{namedArgumentsStart:2:end}] = convertStringsToChars(varargin{namedArgumentsStart:2:end});
end