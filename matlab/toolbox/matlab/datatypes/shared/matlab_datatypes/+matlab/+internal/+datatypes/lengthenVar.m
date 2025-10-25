function b = lengthenVar(a,n)
% LENGTHENVAR Lengthen an existing variable's data out to n rows.
%   LENGTHENVAR does not behave the same as DEFAULTARRAYLIKE. That function fills
%   in with missing values where it knows how to. This function is equivalent to
%   what gets filled in for the unassigned end+1st element when you assign to
%   the end+2nd element of a table variable.
%
%   Consistent with standard MATLAB behavior, 0x0 vars will be lengthened to
%   Nx1, not as Nx0. Other empties will remain empty.
%
%      Array Class            Fill Value
%      ---------------------------------------------
%      double, single         0
%      duration               0
%      calendarDuration       0
%      datetime               NaT
%      int8, ..., uint64      0
%      logical                false
%      categorical            <undefined>
%      char                   char(0)
%      cellstr                {[]}
%      cell                   {[]}
%      string                 <missing>
%      struct                 struct with [] in fields
%      table                  table with vars recursively filled in
%      enumeration            first enumeration value listed in class definition
%      other                  [MATLAB default value]

%   Copyright 2021-2023 The MathWorks, Inc.

b = a;
m = size(a,1);
if n <= m
    return
end

if isnumeric(a) && ~isenum(a) % including float, integer, and things like gpuArray
    % Let a numeric (sub)class pad with its choice, e.g. zero or NaN. For core numeric
    % types, assignment to b(n+1,:) when b is 0x0 (perversely) adds a first column, but
    % for at least some others like gpuArray, it (more correctly) returns an (n+1)x0.
    b(n+1,:) = 0; % preserves trailing shape for N-D when not 0x0
    b = b(1:n,:); % breaks trailing N-D shape
    if ~ismatrix(a)
        sizeOut = size(a); sizeOut(1) = n;
        b = reshape(b,sizeOut); % restore N-D shape
    end
elseif islogical(a)
    b(n,:) = false;
elseif isa(a,'categorical')
    b(n,:) = categorical.undefLabel;
elseif isa(a, 'datetime') 
    b(n,:) = NaT;
elseif isa(a, 'duration')
    b(n,:) = 0;
elseif isa(a, 'calendarDuration') 
    b(n,:) = calendarDuration(0,0,0);
elseif isstring(a)
    b(n,:) = missing;
elseif iscell(a)
    b(m+1:n,:) = {[]};
elseif ischar(a)
    b(n,:) = char(0);
elseif isenum(a) % both pure and "numeric"
    % enum inheriting from [u]int "is numeric", but may not support zero, so
    % can't go through the numeric case
    b(n,:) = matlab.lang.internal.getDefaultEnumerationMember(a);
elseif isstruct(a)
    fnames = fieldnames(a);
    b(n,:) = cell2struct(cell(size(fnames)),fnames);
elseif isa(a,'tabular')
    b = lengthenVar(b,n);
else % arbitrary objects
    % Get a scalar value of the array type to be lengthened.
    if isempty(b)
        % There's no existing value to get, so get one from the ctor if possible. This
        % does not copy any metadata from a that should be preserved.
        try
            b0 = feval(class(a));
        catch ME
            throwAsCaller(addCause(MException(message('MATLAB:table:ObjectConstructorFailed',class(a))),ME));
        end
        if isempty(b0)
            % If the ctor's default behavior returns an empty, there's no way to
            % create a non-empty instance.
            throwAsCaller(MException(message('MATLAB:table:ObjectConstructorReturnedEmpty',class(a))));
        end
    else
        b0 = b(1,:);
    end
    % Assign the value just past the desired end to fill the previous elements
    % with their default values. That scalar value is thrown away, so it doesn't
    % matter what it is.
    b(n+1,:) = b0; % preserves trailing shape for N-D
    b = b(1:n,:); % breaks N-D shape
    if ~ismatrix(a)
        sizeOut = size(a); sizeOut(1) = n;
        b = reshape(b,sizeOut); % restore N-D shape
    end
end