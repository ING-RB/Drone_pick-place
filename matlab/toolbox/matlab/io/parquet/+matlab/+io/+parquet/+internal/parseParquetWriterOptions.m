function opts = parseParquetWriterOptions(tableSchema, varargin)
%parseParquetWriterOptions Parse optional parameters for ParquetWriter.

%   Copyright 2018-2024 The MathWorks, Inc.

import matlab.io.parquet.internal.validateVariableEncoding
import matlab.io.parquet.internal.validatePerVariableOption

persistent parser;

if isempty(parser)
    parser = inputParser;
    addParameter(parser, "VariableCompression", "snappy");
    addParameter(parser, "VariableEncoding", "auto");
    addParameter(parser, "Version", "2.0");
    addParameter(parser, "RowGroupHeights", missing); % Parsed elsewhere, ignore here.
    addParameter(parser, "VariableNames", missing); % Parsed elsewhere, ignore here.
    addParameter(parser, "UseCompliantNestedTypes", true); % undocumented nv-pair
end

parse(parser, varargin{:});
opts = rmfield(parser.Results, parser.UsingDefaults);

if isempty(fields(opts))
    % Use default options defined in parquetio lib
    return;
end

% Normalize supplied name-value parameters into valid ParquetWriter inputs
if isfield(opts, "VariableCompression")
    varCodecs = opts.VariableCompression;
    opts.VariableCompression = validatePerVariableOption(...
        tableSchema.ColumnNames, "VariableCompression", varCodecs, @iValidateCodec);
end

if isfield(opts, "VariableEncoding")
    varEncoding = opts.VariableEncoding;
    opts.VariableEncoding = validateVariableEncoding(tableSchema, ...
        varEncoding);
end

if isfield(opts, "Version")
    version = opts.Version;
    opts.Version = iValidateVersion(version);
end

if isfield(opts, "UseCompliantNestedTypes")
    iValidateUseCompliantNestedTypes(opts.UseCompliantNestedTypes);
end

if isfield(opts, "RowGroupHeights")
    % Remove this from the opts field since it is not used as an input
    % argument to the ParquetWriter C++ object.
    opts = rmfield(opts, "RowGroupHeights");
end

if isfield(opts, "VariableNames")
    % Remove this from the opts field since this nv-pair is handled elsewhere.
    opts = rmfield(opts, "VariableNames");
end

%--------------------------------------------------------------------------
function c = iValidateCodec(c)
allowedOpts = ["snappy", "gzip", "brotli", "uncompressed"];
c = validatestring(c, allowedOpts, "parquetio:write", "VariableCompression");
end

%--------------------------------------------------------------------------
function v = iValidateVersion(v)
allowedOpts = ["1.0", "2.0"];
v = validatestring(v, allowedOpts, "parquetio:write", "Version");
end

%--------------------------------------------------------------------------
function iValidateUseCompliantNestedTypes(c)
validateattributes(c, "logical", "scalar");
end
end