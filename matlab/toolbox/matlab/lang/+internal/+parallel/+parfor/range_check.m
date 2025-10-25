function range = range_check(varname, range, varargin)
%

% Copyright 2007-2024 The MathWorks, Inc.
%
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.
%
% A parfor-loop range must evaluate to a series of consecutive ascending
% integer values. A parfor-loop range must be a row vector and not a column
% vector (or matrix etc.).
%
% range_check validates a parfor-loop colon range and returns
% a two element row vector [base limit]. The [base limit] row vector is
% the expected format for parallel_function.

% Call isnumeric before colon expansion a:b to avoid the warning message,
% 'Warning: Colon operands must be real scalars.'
% Allow complex numbers with 0 as imaginary components. e.g [1+0i,2+0i,...]
if ~isnumeric(range) || (~isreal(range) && any(imag(range),'all')) || any(~isfinite(range),'all')
    error(message('MATLAB:parfor:range_not_consecutive',...
            varname,...
            doclink( '/toolbox/parallel-computing/distcomp_ug.map', 'ERR_PARFOR_RANGE', 'parfor-Loops in MATLAB, "parfor"' )));
end

% Check isrow before checking for empty range to ensure that even empty ranges are the correct shape
% for parfor. FOR treats the range as a matrix and iterates over columns. Only enforce ISROW if the
% corresponding FOR loop would have some iterations. (I.e. allow "parfor i = [], end" to silently do nothing).
[~, numColumns] = size(range);
if ~isrow(range) && numColumns ~= 0
    error(message('MATLAB:parfor:range_must_be_row_vector', ...
            varname,...
            doclink( '/toolbox/parallel-computing/distcomp_ug.map', 'ERR_PARFOR_RANGE', 'parfor-Loops in MATLAB, "parfor"' )));
end

if isempty(range)
    % parallel_function expects the canonical empty range
    range = [1, 0];
    return
end

a = round(range(1));
b = round(range(end));
if a > b || ~isequal(range, a:b)
    error(message('MATLAB:parfor:range_not_consecutive',...
            varname,...
            doclink( '/toolbox/parallel-computing/distcomp_ug.map', 'ERR_PARFOR_RANGE', 'parfor-Loops in MATLAB, "parfor"' )));
end

if isempty(varargin)
    range = internal.parallel.parfor.colon_range_check(varname, a, 1, b);
else
    range = internal.parallel.parfor.colon_range_check(varname, a, 1, b, varargin{:});
end

return

end
