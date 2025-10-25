function range = colon_range_check(varname, a, s, b, varargin)
%

% Copyright 2018-2024 The MathWorks, Inc.

% This function is undocumented and reserved for internal use.  It may be
% removed in a future release.

% A parfor-loop range must evaluate to a series of consecutive ascending
% integer values. A parfor-loop range that evaluates to a vector must be a
% row vector and not a column vector.

% colon_range_check validates a parfor-loop colon range and returns
% a base-limit pair row-vector [a b]. [a b] is the canonical two-element range
% format of parallel_function. colon_range_check validates that
% integer type ranges do not violate the lower-bound or upper-bound
% limits of the corresponding integer types.
%
% colon_range_check avoids the cost of colon expansion for the
% common cases of range=a:b or range=a:s:b
%
% varargin contains a list of sliced offset variable name-value pairs.
% Sliced offset values may be positive or negative values.
% colon_range_check validates that integer type.

% Validate colon range endpoints and the range step.
internal.parallel.parfor.endpoint_check(varname, a);
internal.parallel.parfor.range_step_check(varname, s);
internal.parallel.parfor.endpoint_check(varname, b);

% Validate mixed non-double ranges.
aisad = isa(a,'double');
bisad = isa(b,'double');
sisad = isa(s,'double');

% All range element pairs must be mixed doubles and integers or integers of
% the same type.
mixed_non_double_operands = ~((aisad || sisad || isa(a,class(s))) ...
                              && (aisad || bisad || isa(a,class(b))) ...
                              && (sisad || bisad || isa(s,class(b))));
if mixed_non_double_operands
    error(message('MATLAB:parfor:InvalidMixedNonDoubleParforLoopRange',...
        varname,...
        doclink( '/toolbox/parallel-computing/distcomp_ug.map', 'ERR_PARFOR_RANGE', 'parfor-Loops in MATLAB, "parfor"' )));
end

% Return the canonical empty range.
if b < a
    range = [1, 0];
    return
end

% Validate range saturation for integer type ranges.
if ~(aisad && sisad && bisad)
    % Skip this check for common case of all double arguments.
    integer_range_overflow_check(varname, a, s, b);
end

% Validate integer range bounds constraints with sliced offsets.
for idx = 1:2:numel(varargin)
    offset_name = varargin{idx};
    offset_value = varargin{idx+1};

    internal.parallel.parfor.sliced_offset_check(offset_name, offset_value);

    % The parfor-loop range and sliced offsets must be mixed doubles
    % and integers or integers of the same type.
    mixed_non_double_range_offset = ~(isa(offset_value, 'double') ...
        || (aisad && sisad && bisad) ...
        || isa(offset_value, class(a)) ...
        || isa(offset_value, class(s)) ...
        || isa(offset_value, class(b)));
    if mixed_non_double_range_offset
        error(message('MATLAB:parfor:InvalidMixedNonDoubleSlicedVariableOffset',...
            offset_name,...
            doclink('/toolbox/parallel-computing/distcomp_ug.map', 'ERR_PARFOR_RANGE', 'parfor-Loops in MATLAB, "parfor"' )))
    end

    integer_range_overflow_check(varname, a, s, b, offset_value);
end

% Set the canonical range type to the type of a:s:b.
if ~aisad
    b = cast(b,'like',a);
elseif ~sisad
    a = cast(a,'like',s);
    b = cast(b,'like',s);
elseif ~bisad
    a = cast(a,'like',b);
end

% Return the canonical two-element row-vector.
range = [a, b];

return

end

function integer_range_overflow_check(varname, base, step, limit, offset)
% Validates that integer type ranges do not silently truncate range values.
%
% parallel_function([base limit]) internally specifies the range as
% a semi-open interval '(base-1, limit]', and executes the loop intervals in
% reverse as 'limit-base-1:-1:1'. Hence if 'base <= intmin(class(base))', or
% for 'diff = limit-base, diff >= intmax(class(diff))' an error is thrown.

diff = limit-(base*step);
base = cast(base, 'like', diff);

if nargin > 4
    base = base + offset;
    diff = diff + offset;
end

if isinteger(diff)

    if (base <= intmin(class(base))) || (diff >= intmax(class(diff)))

        error(message('MATLAB:parfor:range_exceeds_bounds',...
                varname,...
                doclink( '/toolbox/parallel-computing/distcomp_ug.map', 'ERR_PARFOR_RANGE', 'parfor-Loops in MATLAB, "parfor"' )));
    end

end

end
