function w = createParquetWriter(filename, tableSchema, varargin)
%createParquetWriter Creates a ParquetWriter

%   Copyright 2018-2023 The MathWorks, Inc.

import matlab.io.parquet.internal.ParquetWriter
import matlab.io.parquet.internal.parseParquetWriterOptions

opts = parseParquetWriterOptions(tableSchema, varargin{:});

w = ParquetWriter(filename);
w.VariableNames = tableSchema.ColumnNames;

if any(isfield(opts, ["VariableEncoding", "VariableCompression"]))
    compliantListType = true;
    if isfield(opts, "UseCompliantNestedTypes")
        compliantListType = opts.UseCompliantNestedTypes;
    end

    [offsets, paths] = getLeafColumnPaths(tableSchema, compliantListType);

    w.setLeafColumnPaths(offsets, paths);
end

% Apply parsed options to ParquetWriter.
% opts struct will only contain fields for non-default settings
optionNames = fieldnames(opts);
for ii = 1:numel(optionNames)
    % Copy options onto the writer instance
    w.(optionNames{ii}) = opts.(optionNames{ii});
end
end

function [offsets, leafPaths] = getLeafColumnPaths(tableSchema, compliantListType)
    import matlab.io.internal.arrow.schema.GeneratePathVisitor

    visitor = GeneratePathVisitor(UseCompliantListSuffix=compliantListType);

    offsets = zeros([1 tableSchema.NumColumns + 1], "uint64");
    perVarPaths = cell([1 tableSchema.NumColumns]);

    for ii = 1:tableSchema.NumColumns
        perVarPaths{ii} = visitor.visit(tableSchema.ColumnNames(ii), ...
            tableSchema.ColumnDataTypes(ii));
        offsets(ii + 1) = offsets(ii) + numel(perVarPaths{ii});
    end

    leafPaths = [perVarPaths{:}];
end