function str = formatBigSize(sz)
%FORMATBIGSIZE  convert a dimension vector into a formatted string
%
%   STR = FORMATBIGSIZE(SZ) converts the dimension vector SZ into a
%   formatted string with thousands separated by commas or periods
%   according to the current locale.
%

%   Copyright 2015-2021 The MathWorks, Inc.

import matlab.bigdata.internal.util.formatBigDouble

% Must be a row vector of non-negative integers
assert( isrow(sz) && all(sz >= 0) && all(floor(sz) == sz) );
strs = arrayfun( @formatBigDouble, sz );

str = char(strjoin(strs, matlab.internal.display.getDimensionSpecifier()));

end
