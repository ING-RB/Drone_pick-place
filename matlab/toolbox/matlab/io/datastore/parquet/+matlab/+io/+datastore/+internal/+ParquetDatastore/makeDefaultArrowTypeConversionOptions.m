function typeOpts = makeDefaultArrowTypeConversionOptions()
%makeDefaultArrowTypeConversionOptions   Default ArrowTypeConversionOptions
%   used in ParquetDatastore2.

%   Copyright 2022 The MathWorks, Inc.

    import matlab.io.internal.arrow.conversion.*

    % The schema of the table returned by each ParquetDatastore read should
    % be consistent (i.e. the VariableTypes and VariableNames shold be consistent).
    % To ensure this is the case for Parquet files where some row
    % groups have columns with logical or integer type AND contain missing values:
    %
    %    1. We *SHOULD NOT* convert logical or integral typed columns to
    %       double in order to fill NULL array slots with NaN (like parquetread does).
    %
    %    2. We *SHOULD* fill NULL array slots with the sentinel value '0' for
    %       integer typed columns and 'false' for logical typed columns.

    logicalOpts = LogicalTypeConversionOptions(CastToDouble=false, NullFillValue=false);
    integerOpts = IntegerTypeConversionOptions(CastToDouble=false, NullFillValue=0);

    typeOpts = ArrowTypeConversionOptions(LogicalTypeConversionOptions=logicalOpts, ...
                                          IntegerTypeConversionOptions=integerOpts);
end