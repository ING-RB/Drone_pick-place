function y = defaultarrayLike(sz,~,x,ascellstr)
%DEFAULTARRAYLIKE Create a variable like x containing null values
%   Y = DEFAULTARRAYLIKE(SZ,'Like',X,ASCELLSTR) returns a variable the same
%   class as X, with the specified size, containing default values.  The
%   default value for floating point types is NaN, in other cases the
%   default value is the value MATLAB uses by default to fill in
%   unspecified elements on array expansion. ASCELLSTR specifies whether x,
%   *if it is a cell array of character vectors*, should be treated as a
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

%   Copyright 2012-2024 The MathWorks, Inc.

if isscalar(sz)
    sz = sz([1 1]);
end
n = sz(1); p = prod(sz(2:end));
if isfloat(x) % including double and things like gpuArray
    y = nan(sz,"like",x);
elseif isnumeric(x) && ~isenum(x)
    y = zeros(sz,"like",x);
elseif islogical(x)
    y = false(sz,"like",x);
    
% These could become categorical/datetime/duration/calendarDuration methods
elseif isa(x,'categorical')
    y = x(1:0); % preserve the categories
    if n*p > 0
        y(n,p) = categorical.undefLabel; % automatically in-fills with <undefined>
    end
    y = reshape(y,sz);
elseif isa(x, 'datetime') 
    y = x(1:0); % preserve the format (including default) and time zone
    if n*p > 0
        y(n,p) = NaT; % automatically in-fills with NaT
    end
    y = reshape(y,sz);
    
% duration and calendarDuration in-fill with 0, set to NaN explicitly
elseif isa(x, 'duration') || isa(x, 'calendarDuration') 
    y = x(1:0); % preserve the format
    if n*p > 0
        y(1:n,1:p) = NaN;
    end
    y = reshape(y,sz);
    
elseif isstring(x)
    y = repmat(string(nan),sz);
elseif iscell(x)
    if iscellstr(x) && (nargin < 4 || ascellstr)
        y = repmat({''},sz);
    else
        y = cell(sz);
    end
elseif ischar(x)
    y = repmat(char(0),sz);
    
elseif isenum(x)
    y = repmat(matlab.lang.internal.getDefaultEnumerationMember(x),sz);
    
elseif isstruct(x)
    fnames = fieldnames(x);
    y = repmat(cell2struct(cell(size(fnames)),fnames),sz);
    
elseif isa(x,'tabular')
    % This calls the tabular method, which ignores all but the first element of sz, and
    % creates a tabular with the same vars/types as x, with their default contents.
    % Properties, including row, var, and dim labels, are preserved.
    if nargin < 4, ascellstr = true; end
    y = defaultarrayLike(sz,"like",x,ascellstr);

else % fallback for unrecognized types
    % Create an empty version of the input, then assign off the end to let the
    % class decide how it wants to fill in default values. That may or may not
    % be the same as what the class constructor returns for no inputs.
    y = x(1:0);
    if n*p > 0
        % If the output is non-empty, get a scalar value of the template array type.
        if isempty(x)
            % There's no existing value to get, so get one from the ctor if possible.
            % This does not copy any metadata from a that should be preserved.
            try
                x0 = feval(class(x));
            catch ME
                throwAsCaller(addCause(MException(message('MATLAB:table:ObjectConstructorFailed',class(x))),ME));
            end
            if isempty(x0)
                % If the ctor's default behavior returns an empty, there's no way to
                % create a non-empty instance.
                throwAsCaller(MException(message('MATLAB:table:ObjectConstructorReturnedEmpty',class(x))));
            end
        else
            x0 = x(1);
        end
        % Assign the value just past the desired end to fill the previous elements with
        % their default values. That scalar value will be thrown away, so it doesn't
        % matter what it is.
        y(n*p+1) = x0;
    end
    % Reshape the default elements to the output size
    y = reshape(y(1:n*p),sz); % fails if the class does not support reshape
end
