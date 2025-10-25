function y = defaultarrayLike(varargin)  %#codegen 
%DEFAULTARRAYLIKE Create a variable like x containing null values.
%   Y = DEFAULTARRAYLIKE(SZ1,SZ2,...,'Like',X,ASCELLSTR) or
%   Y = DEFAULTARRAYLIKE([SZ1,SZ2,...],'Like',X,ASCELLSTR)returns a variable
%   the same class as X, with the specified size, containing default values.
%   The default value for floating point types is NaN, in other cases the
%   default value is the value MATLAB uses by default to fill in
%   unspecified elements on array expansion. ASCELLSTR specifies whether x,
%   if it is a cell array of character vectors, should be treated as a
%   cellstr (TRUE) {''} or as a cell array (FALSE) {[]}.
%
%      Array Class            Null Value
%      ---------------------------------------------
%      double, single         NaN
%      duration               NaN
%      calendarDuration       NaN
%      datetime               NaT
%      int8, ..., uint64      0
%      logical                false
%      categorical            <undefined>
%      char                   char(0)
%      cellstr                {''}
%      cell                   {[]}
%      string                 string('')
%      enumeration            first enumeration value listed in class definition
%      struct                 struct with [] in fields
%      table                  table with specified height and same number/type vars as input table,
%                             filled with default values. Row names (when present) copied, and padded
%                             with default as needed. All other properties copied.
%      timetable              timetable with specified height and same number/type vars as input timetable,
%                             filled with default values. Row times copied and padded with NaT as needed.
%                             All other properties copied.
%      other                  [MATLAB default value]

%   Copyright 2020-2024 The MathWorks, Inc.

likeIdx = 0;
coder.unroll();
for i = 1:numel(varargin)
    if strcmpi('like', varargin{i})
        likeIdx = i;
        break;
    end
end
coder.const(likeIdx);  % must be constant
assert(likeIdx > 1 && likeIdx < nargin);
% get the sz arguments
if likeIdx == 2 && coder.internal.isConst(size(varargin{1})) && isscalar(varargin{1})
    % if only specify sz as a scalar, expand to two dimensions both of length sz
    sz = cell(1,2);
    sz{1} = varargin{1};
    sz{2} = varargin{1};
else
    sz = cell(1,likeIdx-1); % { [sz1 sz2 ...] } or {sz1 sz2 ... }
    for i = 1:numel(sz)
        sz{i} = varargin{i};
    end
end

% get the template argument
x = varargin{likeIdx+1};
% get the optional ascellstr argument
if nargin > likeIdx+1
    ascellstr = varargin{likeIdx+2};
else
    ascellstr = true;
end

if isfloat(x)
    y = nan(sz{:},'like',x);
elseif isnumeric(x) && ~isenum(x)
    y = zeros(sz{:},'like',x);
elseif islogical(x)
    y = false(sz{:},'like',x);
elseif isa(x,'categorical')
    xcats = categories(x);
    y = categorical(zeros(sz{:}), 1:numel(xcats), xcats, 'Ordinal', isordinal(x), ...
        'Protected', isprotected(x));
    
elseif isa(x, 'datetime')
    [~,fmt,tz] = datetime.toMillis(x);
    y = datetime.fromMillis(NaN(sz{:}),fmt,tz);
    
% duration and calendarDuration in-fill with 0, set to NaN explicitly
elseif isa(x, 'duration') %|| isa(x, 'calendarDuration') 
    y = x.fromMillis(nan(sz{:}), x.Format);
    
%elseif isstring(x)
%    y = repmat(string(nan),sz);
elseif iscell(x)
    % isConst check necessary because iscellstr is nonconstant if input is
    % variable sized (iscellstr({} is true)
    if coder.internal.isConst(iscellstr(x)) && iscellstr(x) && ascellstr 
        y = repmat({''},sz{:});
    else
        y = repmat({[]},sz{:});
    end
elseif ischar(x)
    y = repmat(char(0),sz{:});
elseif isenum(x) % both pure and "numeric"
    % enum inheriting from [u]int "is numeric", but may not support zero, so
    % can't go through the numeric case
    
    % matlab.lang.internal.getDefaultEnumerationMember works in mex but is not
    % supported in dll's, so even though numeric enumerations are at least
    % partially supported in codegen, they cannot be supported here.
    %y = repmat(matlab.lang.internal.getDefaultEnumerationMember(x),sz);
    coder.internal.assert(isenum(x), 'MATLAB:table:UnsupportedDefaultValues', class(x));
elseif isstruct(x)
    fnames = fieldnames(x);
    s = struct;
    for i = 1:numel(fnames)
        s.(fnames{i}) = [];
    end
    y = repmat(s,sz{:});

else % isa(x,'tabular')
    coder.internal.assert(isa(x,'tabular'), 'MATLAB:table:UnsupportedDefaultValues', class(x));
    
    % This calls the tabular method, which ignores all but the first element of sz, and
    % creates a tabular with the same vars/types as x, with their default contents.
    % Properties, including row, var, and dim labels, are preserved.
    %y = defaultarrayLike(sz{:},'like',x,ascellstr);
    y = defaultarrayLike(varargin{:}); % preserve const-ness of sizes
end
