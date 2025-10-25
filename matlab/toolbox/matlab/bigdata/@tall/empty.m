function t = empty(varargin)
%TALL.EMPTY Create empty array of class TALL
%   A = TALL.EMPTY returns an empty 0-by-0 tall array.
%   
%   A = TALL.EMPTY(M,N,P,...) returns an empty tall array of doubles with the
%   specified dimensions. At least one of the dimensions must be 0.
%   
%   A = TALL.EMPTY([M,N,P,...]) returns an empty tall array of doubles with the
%   specified dimensions. At least one of the dimensions must be 0.
%   
%   A = TALL.EMPTY(...,CLASSNAME) returns an empty tall array with the specified
%   dimensions and underlying type.
%
%  See also TALL.

% Copyright 2016-2023 The MathWorks, Inc.

tall.checkNotTall(upper(mfilename), 0, varargin{:});
[args, flags] = splitArgsAndFlags(varargin{:});
if numel(flags) >= 2
    % only a single flag is permitted - the classname
    error(message('MATLAB:bigdata:array:EmptySingleFlag'));
end

try
    % Just use double.empty to validate the arguments.
    d = double.empty(args{:});
    % If that didn't error, d now has the size we want.
    t = tall.createGathered(zeros(size(d), flags{:}));
catch E
    throw(E);
end
end
