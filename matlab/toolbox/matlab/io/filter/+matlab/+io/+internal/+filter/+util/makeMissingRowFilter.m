function f = makeMissingRowFilter()
%makeMissingRowFilter   convenience function to easily generate missing
%   (internal) RowFilter objects.

%   Copyright 2021 The MathWorks, Inc.

    import matlab.io.internal.filter.MissingRowFilter;
    import matlab.io.internal.filter.properties.MissingRowFilterProperties;

    f = MissingRowFilter(MissingRowFilterProperties(string.empty(0, 1)));
end