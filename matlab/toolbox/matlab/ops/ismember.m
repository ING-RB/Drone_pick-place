function [lia,locb] = ismember(A,B,flag1,flag2)
%   Syntax:
%      Lia = ismember(A,B)
%      Lia = ismember(A,B,"rows")
%      [Lia,Locb] = ismember(___)
%
%      [Lia,Locb] = ismember(___,"legacy")
%
%   For more information, see documentation

%   Copyright 1984-2024 The MathWorks, Inc.

% Convert string flags to char flags to dispatch to the right method
if nargin == 3 && isstring(flag1)
    flag1 = convertFlag(flag1);
    if nargout < 2
        lia = ismember(A, B, flag1);
    else
        [lia, locb] = ismember(A, B, flag1);
    end
    return
end
if nargin == 4 && (isstring(flag1) || isstring(flag2))
    if isstring(flag1)
        flag1 = convertFlag(flag1);
    end
    if isstring(flag2)
        flag2 = convertFlag(flag2);
    end
    if nargout < 2
        lia = ismember(A, B, flag1, flag2);
    else
        [lia, locb] = ismember(A, B, flag1, flag2);
    end
    return
end

if (isstring(A) || isstring(B))
    if ~ischar(A) && ~isstring(A) && ~iscellstr(A)
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    elseif ~ischar(B) && ~isstring(B) && ~iscellstr(B)
        secondInput = getString(message('MATLAB:string:SecondInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', secondInput));
    end
    A = string(A);
    B = string(B);
end

if nargin <= 2
    if nargout < 2
        lia = ismemberR2012a(A,B);
    else
        [lia,locb] = ismemberR2012a(A,B);
    end
else
    % acceptable combinations, with optional inputs denoted in []
    % ismember(A,B, ['rows'], ['legacy'/'R2012a'])
    nflagvals = 3;
    flagvals = ["rows", "legacy", "R2012a"];
    % When a flag is found, note the index into varargin where it was found
    flaginds = zeros(1,nflagvals);
    for i = 3:nargin
        if i == 3
            flag = flag1;
        else
            flag = flag2;
        end
        assert(~isstring(flag));
        foundflag = matlab.internal.math.partialMatchString(flag,flagvals);
        if ~any(foundflag)
            if ischar(flag)
                error(message('MATLAB:ISMEMBER:UnknownFlag',flag));
            else
                error(message('MATLAB:ISMEMBER:UnknownInput'));
            end
        end
        % Only 1 occurrence of each allowed flag value
        if flaginds(foundflag)
            error(message('MATLAB:ISMEMBER:RepeatedFlag',flag));
        end
        flaginds(foundflag) = i;
    end

    % Only 1 of each of the paired flags
    if flaginds(2) && flaginds(3)
        error(message('MATLAB:ISMEMBER:BehaviorConflict'))
    end
    % 'legacy' and 'R2012a' flags must be trailing
    if flaginds(2) && flaginds(2)~=nargin
        error(message('MATLAB:ISMEMBER:LegacyTrailing'))
    end
    if flaginds(3) && flaginds(3)~=nargin
        error(message('MATLAB:ISMEMBER:R2012aTrailing'))
    end

    if flaginds(3) % trailing 'R2012a' specified
        if nargout < 2
            lia = ismemberR2012a(A,B,logical(flaginds(1)));
        else
            [lia,locb] = ismemberR2012a(A,B,logical(flaginds(1)));
        end
    elseif flaginds(2) % trailing 'legacy' specified
        if nargout < 2
            lia = ismemberlegacy(A,B,logical(flaginds(1)));
        else
            [lia,locb] = ismemberlegacy(A,B,logical(flaginds(1)));
        end
    else % 'R2012a' (default behavior)
        if nargout < 2
            lia = ismemberR2012a(A,B,logical(flaginds(1)));
        else
            [lia,locb] = ismemberR2012a(A,B,logical(flaginds(1)));
        end
    end
end
end


function [lia,locb] = ismemberR2012a(a,b,options)
% 'R2012a' flag implementation

% Error check flag
if nargin == 2
    byrow = false;
else
    byrow = options > 0;
end

doBuiltinTypes = true;
% Check that one of A and B is double if A and B are non-homogeneous. Do a
% separate check if A is a heterogeneous object and only allow a B
% that is of the same root class.
if ~(isa(a,'handle.handle') || isa(b,'handle.handle'))
    if ~strcmpi(class(a),class(b))
        if isa(a,'matlab.mixin.Heterogeneous') && isa(b,'matlab.mixin.Heterogeneous')
            rootClassA = meta.internal.findHeterogeneousRootClass(a);
            if isempty(rootClassA) || ~isa(b,rootClassA.Name)
                error(message('MATLAB:ISMEMBER:InvalidInputsDataType',class(a),class(b)));
            end
            doBuiltinTypes = false;
        elseif ~(strcmpi(class(a),'double') || strcmpi(class(b),'double'))
            error(message('MATLAB:ISMEMBER:InvalidInputsDataType',class(a),class(b)));
        end
    end
end

if ~byrow
    if ~(isa(a,'opaque') || isa(b,'opaque')) && doBuiltinTypes
        % Builtin types
        if nargout > 1
            [lia,locb] = ismemberBuiltinTypes(a,b);
        else
            lia = ismemberBuiltinTypes(a,b);
        end
    else
        % Handle objects
        if nargout > 1
            [lia,locb] = ismemberClassTypes(a,b);
        else
            lia = ismemberClassTypes(a,b);
        end
    end
else    % 'rows' case
    if ~(ismatrix(a) && ismatrix(b))
        error(message('MATLAB:ISMEMBER:NotAMatrix'));
    end

    [rowsA,colsA] = size(a);
    [rowsB,colsB] = size(b);

    % Automatically pad strings with spaces
    if ischar(a) && ischar(b)
        b = [b repmat(' ',rowsB,colsA-colsB)];
        a = [a repmat(' ',rowsA,colsB-colsA)];
    elseif colsA ~= colsB
        error(message('MATLAB:ISMEMBER:AandBColnumAgree'));
    end

    % Empty check for 'rows'.
    if rowsA == 0 || rowsB == 0
        lia = false(rowsA,1);
        locb = zeros(rowsA,1);
        return
    end

    % General handling for 'rows'.
    [checkCast, cls] = needsCastingChecks(a, b);
    needLocb = (nargout > 1) || checkCast;

    % Duplicates within the sets are eliminated
    if (rowsA == 1)
        uA = repmat(a,rowsB,1);
        d = uA(1:end,:)==b(1:end,:);
        d = all(d,2);
        lia = any(d);
        if nargout > 1
            if lia
                locb = find(d, 1, 'first');
            else
                locb = 0;
            end
        end
        return;
    else
        if checkCast
            [uA,~,icA] = unique(cast(a, cls),'rows','sorted');
        else
            [uA,~,icA] = unique(a,'rows','sorted');
        end
    end
    if ~needLocb
        uB = unique(b,'rows','sorted');
    elseif checkCast && ~strcmp(cls, class(b))
        % Find rows of B that do not change when cast.
        ibC = find(all(cast(b, cls) == b, 2));
        % Find the unique rows within those rows.
        [uB,ib] = unique(b(ibC,:), 'rows','sorted');
        % Adjust the indices to account for the removed rows.
        ib = ibC(ib);
    else
        [uB,ib] = unique(b, 'rows','sorted');
    end

    % Sort the unique elements of A and B, duplicate entries are adjacent
    [sortuAuB,IndSortuAuB] = sortrows([uA;uB]);

    % Find matching entries
    d = sortuAuB(1:end-1,:)==sortuAuB(2:end,:);     % d indicates matching entries
    d = all(d,2);                                   % Finds the index of matching entries
    ndx1 = IndSortuAuB(d);                          % NDX1 are locations of repeats in C

    if ~needLocb
        lia = ismemberBuiltinTypes(icA,ndx1);           % Find repeats among original list
    else
        szuA = size(uA,1);
        [lia,locb] = ismemberBuiltinTypes(icA,ndx1);    % Find locb by using given indices
        d = find(d);
        newd = d(locb(lia));                    % NEWD is D for non-unique A
        where = ib(IndSortuAuB(newd+1)-szuA);   % Index values of uB through UNIQUE
        locb(lia) = where;                      % Return first or last occurrence of A within B
    end
    if checkCast
        % Post-processing step: if we matched anything in a to b only
        % because of casting during the concatenation, we need to fix it.
        if ~strcmp(cls, class(a))
            % a may have lost precision in the concatenation.
            % Find all rows that have an entry that changed in the cast.
            rmA = any(cast(a, cls) ~= a, 2);
            % Remove these rows from elibility.
            lia(rmA) = false;
            locb(rmA) = 0;
        end
    end
end
end

function [lia,locb] = ismemberBuiltinTypes(a,b)
% General handling.
% Use FIND method for very small sizes of the input vector to avoid SORT.
if nargout > 1
    locb = zeros(size(a));
end
% Handle empty arrays and scalars.
numelA = numel(a);
numelB = numel(b);
if numelA == 0 || numelB <= 1
    if numelA > 0 && numelB == 1
        lia = (a == b);
        if nargout > 1
            % Use DOUBLE to convert logical "1" index to double "1" index.
            locb = double(lia);
        end
    else
        lia = false(size(a));
    end
    return
end

% Use method which sorts list, then performs binary search.
% Convert to full to work in C helper.
if issparse(a)
    a = full(a);
end
if issparse(b)
    b = full(b);
end


% Use builtin helper function ISMEMBERHELPER:
% [LIA,LOCB] = ISMEMBERHELPER(A,B) Returns logical array LIA indicating
% which elements of A occur in B and a double array LOCB with the
% locations of the elements of A occurring in B. If multiple instances
% occur, the first occurrence is returned. B must be already sorted.

if ~isobject(a) && ~isobject(b) && (isnumeric(a) || ischar(a) || islogical(a))
    na = numel(a);
    nb = numel(b);
    bIsComplexInt = isinteger(b) && ~isreal(b);
    useBinarySearch = (na >= 32 || nb >= 32) && (na > 5 && nb > 10);
    if ~useBinarySearch
        needToSort = false;
        if na > 1 && nb >= 4 && na*nb > 256 && ~bIsComplexInt 
            useBinarySearch = issorted(b(:),'ComparisonMethod','real');
        end
    else
        needToSort = bIsComplexInt || ~issorted(b(:),'ComparisonMethod','real');
    end
    if needToSort
        if bIsComplexInt
            [~,idx] = sortrows([real(b(:)),imag(b(:))]);
            b = b(idx);
        else
            if nargout > 1
                [b,idx] = sort(b(:),'ComparisonMethod','real');
            else
                b = sort(b(:),'ComparisonMethod','real');
            end
        end
    end
    if nargout <= 1
        lia = matlab.internal.math.ismemberhelper(a,b,useBinarySearch);
    else
        [lia, locb] = matlab.internal.math.ismemberhelper(a,b,useBinarySearch);
        if needToSort
            locb(lia) = idx(locb(lia));
        end
    end
else % a,b, are some other class like gpuArray, sym object.
    if (isreal(b))
        % Find out whether list is presorted before sort
        sortedlist = issorted(b(:));
        if nargout > 1
            if ~sortedlist
                [b,idx] = sort(b(:));
            end
        elseif ~sortedlist
            b = sort(b(:));
        end
    else
        sortedlist = 0;
        [b,idx] = sort(b(:),"ComparisonMethod","real");
    end
    lia = false(size(a));
    if nargout <= 1
        for i=1:numelA
            if any(a(i)==b)
                lia(i) = true;
            end
        end
    else
        for i=1:numelA
            found = a(i)==b(:); % FIND returns indices for LOCB.
            if any(found)
                lia(i) = true;
                found = find(found);
                locb(i) = found(1);
            end
        end
    end
    if nargout > 1 && ~sortedlist
        % Re-reference locb to original list if it was unsorted
        locb(lia) = idx(locb(lia));
    end
end
end


function [lia,locb] = ismemberClassTypes(a,b)
if issparse(a)
    a = full(a);
end
if issparse(b)
    b = full(b);
end
% Duplicates within the sets are eliminated
if isempty(a)||isempty(b)
    lia = false(size(a));
    if nargout > 1
        locb = zeros(size(a));
    end
    return
end
if isscalar(a) || isscalar(b)
    if strcmp(class(a),class(b))
        if length(a)==numel(a) && length(b)==numel(b)
            % a and b do not need to be reshaped if they are n-dimensional
            % vectors
            lia = a==b;
        else
            lia = a(:)==b(:);
        end
    else
        ab = [a(:);b(:)];
        numa = numel(a);
        lia = ab(1:numa)==ab(1+numa:end);
    end
    if ~any(lia)
        lia  = false(size(a));
        if nargout > 1
            locb = zeros(size(a));
        end
        return
    end
    if nargout > 1
        if ~isscalar(b)
            locb = find(lia);
            locb = locb(1);
            lia = any(lia);
        else
            locb = double(lia);
        end
    else
        if ~isscalar(b)
            lia = any(lia);
        end
    end
else
    % Duplicates within the sets are eliminated
    [uA,~,icA] = unique(a(:),'sorted');
    if nargout <= 1
        uB = unique(b(:),'sorted');
    else
        [uB,ib] = unique(b(:),'sorted');
    end

    % Sort the unique elements of A and B, duplicate entries are adjacent
    [sortuAuB,IndSortuAuB] = sort([uA;uB]);

    % Find matching entries
    d = sortuAuB(1:end-1)==sortuAuB(2:end);         % d indicates the indices matching entries
    ndx1 = IndSortuAuB(d);                          % NDX1 are locations of repeats in C

    if nargout <= 1
        lia = ismemberBuiltinTypes(icA,ndx1);       % Find repeats among original list
    else
        szuA = size(uA,1);
        d = find(d);
        [lia,locb] = ismemberBuiltinTypes(icA,ndx1);% Find locb by using given indices
        newd = d(locb(lia));                        % NEWD is D for non-unique A
        where = ib(IndSortuAuB(newd+1)-szuA);       % Index values of uB through UNIQUE
        locb(lia) = where;                          % Return first or last occurrence of A within B
    end
end
lia = reshape(lia,size(a));
if nargout > 1
    locb = reshape(locb,size(a));
end
end

function flag = convertFlag(flag)
if isscalar(flag)
    flag = char(flag);
else
    error(message('MATLAB:ISMEMBER:UnknownInput'));
end
end

function [tf, cls] = needsCastingChecks(a,b)
aIsBuiltinType = (isnumeric(a) || ischar(a) || islogical(a)) && ~isobject(a);
bIsBuiltinType = (isnumeric(b) || ischar(b) || islogical(b)) && ~isobject(b);
tf = aIsBuiltinType && bIsBuiltinType && ~strcmp(class(a), class(b));
if aIsBuiltinType && bIsBuiltinType
    % This concatenation does not work for all type combinations, but
    % we only need it for these combinations anyway.
    % This creates empties of the class of a and b and concatenates
    % them so that we can determine what the resulting class will be.
    cls = class([a([],:); b([],:)]);
else
    cls = class(a);
end
end
