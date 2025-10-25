function tf = isequaln(cacher1, cacher2, varargin)
%isequaln   isequaln is overloaded for ParquetReadCacher to ignore the
%   cached properties and instead just compute equality using the Filename.
%
%   Other properties (like the current rowgroup index or OutputType) are compared
%   using isequaln on ParquetImportOptions or the relevant datastore object, like
%   RepeatedDatastore.

%   Copyright 2021-2022 The MathWorks, Inc.

    % Verify that the object classes are correct
    isParquetReadCacher = @(x) isa(x, "matlab.io.parquet.internal.ParquetReadCacher");
    tf = isParquetReadCacher(cacher1) && isParquetReadCacher(cacher2) ...
       && isequaln(cacher1.Filename, cacher2.Filename);

    % Recurse for any other inputs.
    for index = 1:numel(varargin)
        tf = tf && isequaln(cacher1, varargin{index});
    end
end
