function [c, ia, ib] = setxor(A, B, flag1, flag2)
%SETXOR Set exclusive-or.
%   C = SETXOR(A,B) for vectors A and B, returns the values that are not 
%   in the intersection of A and B with no repetitions. C will be sorted. 
%
%   C = SETXOR(A,B,'rows') for matrices A and B with the same number of 
%   columns, returns the rows that are not in the intersection of A and B.
%   The rows of the matrix C will be in sorted order.
%
%   [C,IA,IB] = SETXOR(A,B) also returns index vectors IA and IB such that 
%   C is a sorted combination of the values A(IA) and B(IB). If there 
%   are repeated values that are not in the intersection in A or B then the
%   index of the first occurrence of each repeated value is returned.
%
%   [C,IA,IB] = SETXOR(A,B,'rows') also returns index vectors IA and IB 
%   such that C is the sorted combination of rows A(IA,:) and B(IB,:).
%
%   [C,IA,IB] = SETXOR(A,B,'stable') for arrays A and B, returns the values
%   of C in the same order that they appear in A, then B.
%   [C,IA,IB] = SETXOR(A,B,'sorted') returns the values of C in sorted
%   order.
%   If A and B are row vectors, then C will be a row vector as well,
%   otherwise C will be a column vector. IA and IB are column vectors.
%   If there are repeated values that are not in the intersection of A and
%   B, then the index of the first occurrence of each repeated value is
%   returned.
%
%   [C,IA,IB] = SETXOR(A,B,'rows','stable') returns the rows of C in the
%   same order that they appear in A, then B.
%   [C,IA,IB] = SETXOR(A,B,'rows','sorted') returns the rows of C in sorted
%   order.
%
%   The behavior of SETXOR has changed.  This includes:
%     -	occurrence of indices in IA and IB switched from last to first
%     -	orientation of vector C
%     -	IA and IB will always be column index vectors
%     -	tighter restrictions on combinations of classes
% 
%   If this change in behavior has adversely affected your code, you may 
%   preserve the previous behavior with:
% 
%      [C,IA,IB] = SETXOR(A,B,'legacy')
%      [C,IA,IB] = SETXOR(A,B,'rows','legacy')
%
%   Examples:
%
%      a = [9 9 9 9 9 9 8 8 8 8 7 7 7 6 6 6 5 5 4 2 1]
%      b = [1 1 1 3 3 3 3 3 4 4 4 4 4 10 10 10]
%      [c1,ia1,ib1] = setxor(a,b)
%      % returns
%      c1 = [2 3 5 6 7 8 9 10], ia1 = [20 17 14 11 7 1]', ib1 = [4 14]'
%
%      [c2,ia2,ib2] = setxor(a,b,'stable')
%      % returns
%      c2 = [9 8 7 6 5 2 3 10], ia2 = [1 7 11 14 17 20]', ib2 = [4 14]'
%
%      c = setxor([1 NaN 2 3],[3 4 NaN 1])
%      % NaNs compare as not equal, so this returns
%      c = [2 4 NaN NaN]
%
%   Class support for inputs A and B, where A and B must be of the same
%   class unless stated otherwise:
%      - logical, char, all numeric classes (may combine with double arrays)
%      - cell arrays of strings (may combine with char arrays)
%      -- 'rows' option is not supported for cell arrays
%      - objects with methods SORT (SORTROWS for the 'rows' option), EQ and NE
%      -- including heterogeneous arrays derived from the same root class
%
%   See also UNIQUE, UNION, INTERSECT, SETDIFF, ISMEMBER, SORT, SORTROWS.

%   Copyright 1984-2019 The MathWorks, Inc.

% Convert string flags to char flags to dispatch to the right method
if nargin == 3 && isstring(flag1)
    flag1 = convertFlag(flag1);
    if nargout <= 1
       c = setxor(A, B, flag1);
    else
       [c, ia, ib] = setxor(A, B, flag1);
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
    if nargout <= 1
       c = setxor(A, B, flag1, flag2);
    else
       [c, ia, ib] = setxor(A, B, flag1, flag2);
    end
    return
end
if isstring(A) || isstring(B)
    if ~ischar(A) && ~iscellstr(A) && ~isstring(A)
        firstInput = getString(message('MATLAB:string:FirstInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', firstInput));
    elseif ~ischar(B) && ~iscellstr(B) && ~isstring(B)
        secondInput = getString(message('MATLAB:string:SecondInput'));
        error(message('MATLAB:string:MustBeCharCellArrayOrString', secondInput));
    end
    A = string(A);
    B = string(B);
end

if nargin == 2
    if nargout <= 1
       c = setxorR2012a(A, B);
    else
       [c, ia, ib] = setxorR2012a(A, B);
    end
else
    % acceptable combinations, with optional inputs denoted in []
    % setxor(A,B, ['rows'], ['legacy'/'R2012a']),
    % setxor(A,B, ['rows'], ['sorted'/'stable']),
    % where the position of 'rows' and 'sorted'/'stable' may be reversed
    nflagvals = 5;
    % When a flag is found, note the index into varargin where it was found
    flaginds = parseFlags(zeros(1,nflagvals), flag1, 3);
    if nargin > 3
         flaginds = parseFlags(flaginds, flag2, 4);
    end
      
    % Only 1 of each of the paired flags
    if flaginds(2) && flaginds(3)
        error(message('MATLAB:SETXOR:SetOrderConflict'))
    end
    if flaginds(4) && flaginds(5)
        error(message('MATLAB:SETXOR:BehaviorConflict'))
    end
    % 'legacy' and 'R2012a' flags must be trailing
    if flaginds(4) && flaginds(4)~=nargin
        error(message('MATLAB:SETXOR:LegacyTrailing'))
    end
    if flaginds(5) && flaginds(5)~=nargin
        error(message('MATLAB:SETXOR:R2012aTrailing'))
    end
    
    if flaginds(2) || flaginds(3) % 'stable'/'sorted' specified
        if flaginds(4) || flaginds(5) % does not combine with 'legacy'/'R2012a'
            error(message('MATLAB:SETXOR:SetOrderBehavior'))
        end
        if nargout <= 1
            c = setxorR2012a(A, B, logical(flaginds(1:3)));
        else
            [c, ia, ib] = setxorR2012a(A, B, logical(flaginds(1:3)));
        end
    elseif flaginds(5) % trailing 'R2012a' specified
        if nargout <= 1
            c = setxorR2012a(A, B, logical(flaginds(1:3)));
        else
            [c, ia, ib] = setxorR2012a(A, B, logical(flaginds(1:3)));
        end
    elseif flaginds(4) % trailing 'legacy' specified
        if nargout <= 1
            c = setxorlegacy(A, B, logical(flaginds(1)));
        else
            [c, ia, ib] = setxorlegacy(A, B, logical(flaginds(1)));
        end
    else % 'R2012a' (default behavior)
        if nargout <= 1
            c = setxorR2012a(A, B, logical(flaginds(1:3)));
        else
            [c, ia, ib] = setxorR2012a(A, B, logical(flaginds(1:3)));
        end
    end
end
end


function [c,ia,ib] = setxorR2012a(a,b,options)
% 'R2012a' flag implementation

% flagvals = {'rows' 'sorted' 'stable'};
if nargin == 2
    byrow = false;
    order = 'sorted';
else
    byrow = (options(1) > 0);
    if options(3) > 0
        order = 'stable';
    else % if options(2) > 0 || sum(options(2:3)) == 0)
        order = 'sorted';
    end
end

% Check that one of A and B is double if A and B are non-homogeneous. Do a
% separate check if A is a heterogeneous object and only allow a B
% that is of the same root class.
if ~(isa(a,'handle.handle') || isa(b,'handle.handle'))
    if ~strcmpi(class(a),class(b))
        if isa(a,'matlab.mixin.Heterogeneous') && isa(b,'matlab.mixin.Heterogeneous')
            rootClassA = meta.internal.findHeterogeneousRootClass(a);
            if isempty(rootClassA) || ~isa(b,rootClassA.Name)
                error(message('MATLAB:SETXOR:InvalidInputsDataType',class(a),class(b)));
            end
        elseif ~(strcmpi(class(a),'double') || strcmpi(class(b),'double'))
            error(message('MATLAB:SETXOR:InvalidInputsDataType',class(a),class(b)));
        end
    end
end

% Determine if A and B are both row vectors.
rowvec = isrow(a) && isrow(b);

if ~byrow
    
    numelA = numel(a);
    numelB = numel(b);
    % Convert to columns.
    a = a(:);
    b = b(:);
    
    % Sort for sorted.  
    if nargout <= 1
        if strcmp(order, 'sorted')  % || strcmp(order, 'last')
            a = sort(a);
            b = sort(b);
        end
    else
        if ~strcmp(order, 'stable')
            [a,ia] = sort(a);
        else
            ia = (1:numelA)';
        end
        if ~strcmp(order, 'stable')
            [b,ib] = sort(b);
        else
            ib = (1:numelB)';
        end
    end
    
    % Call ismember to find the elements in A which are not in B and
    % vice versa
    tfa = ~ismember(a,b,'R2012a');
    tfb = ~ismember(b,a,'R2012a');
    
    
    % a(tfa) now contains all members of A which are not in B
    % b(tfb) now contains all members of B which are not in A
    if nargout <= 1
        c = unique([a(tfa);b(tfb)],order);    % Remove duplicates from XOR list.
    else
        ia = ia(tfa);
        ib = ib(tfb);
        n = size(ia,1);
        [c,ndx] = unique([a(tfa);b(tfb)],order);  % NDX holds indices to generate C.
        d = ndx > n;                        % Find indices of A and of B.
        ia = ia(ndx(~d));
        ib = ib(ndx(d) - n);
        if isempty(ib)
            ib = zeros(0,1);
        end
        if isempty(ia)
            ia = zeros(0,1);
        end
    end
    
    % If A and B are row vectors, return C as row vector.
    if rowvec
        c = c.';
    end
    
else    % 'rows' case
    if ~(ismatrix(a) && ismatrix(b))
        error(message('MATLAB:SETXOR:NotAMatrix'));
    end
    
    [rowsA,colsA] = size(a);
    [rowsB,colsB] = size(b);
    
    % Automatically pad strings with spaces
    if ischar(a) && ischar(b)
        b = [b repmat(' ',rowsB,colsA-colsB)];
        a = [a repmat(' ',rowsA,colsB-colsA)];
    elseif colsA ~= colsB
        error(message('MATLAB:SETXOR:AandBColnumAgree'));
    end
    
    % Make sure a and b contain unique elements.
    [checkCast, cls] = needsCastingChecks(a, b);
    if (nargout <= 1) && ~checkCast
        uA = unique(a,'rows',order);
        uB = unique(b,'rows',order);
    else
        % Get the unique elements of a and b.
        [uA,ia] = unique(a,'rows',order);
        [uB,ib] = unique(b,'rows',order);
    end
    
    if checkCast 
        if ~strcmp(cls, class(a))
            % Rows of a can lose precision when concatenating.
            % Find all rows of a that are members of b only because of casting.
            uAC = cast(uA,cls);
            [lia, locb] = ismember(uAC, uB, 'rows');
            lia = lia & any(cast(uAC,class(a)) ~= uA, 2);
            % Remove those rows from uB so that we get the output indices
            % correct.
            uB(locb(lia),:) = [];
            ib(locb(lia)) = [];
        else
            % Rows of b can lose precision when concatenating.
            % Find all rows of b that are members of a only because of casting.
            uBC = cast(uB,cls);
            lib = ismember(uBC, uA, 'rows');
            lib = lib & any(cast(uBC,class(b)) ~= uB, 2);
            % Remove those rows from uB.
            uB(lib,:) = [];
            ib(lib) = [];
        end
    end
    
    
    catuAuB = [uA;uB];                                  % Sort [uA;uB] in order to find matching entries
    [sortuAuB,indSortuAuB] = sortrows(catuAuB);
    
    d = find(all(sortuAuB(1:end-1,:)==sortuAuB(2:end,:),2));    % d indicates the location of matching entries
    indSortuAuB([d;d+1]) = [];                                  % Remove all matching entries - indSortuAuB only contains elements not in intersect
    
    if strcmp(order, 'stable') % 'stable'
        indSortuAuB = sort(indSortuAuB);        % Sort the indices to get 'stable' order
    end
    
    c = catuAuB(indSortuAuB,:);                 % Find C
    
    % Find indices if needed
    if nargout > 1
        n = size(uA,1);
        d = indSortuAuB <= n;           % Find indices in indSortuAuB that belong to A
        if d == 0                       % Force d to be correct shape if none of the elements
            d = zeros(0,1);             % in A are in C.
        end
        ia = ia(indSortuAuB(d));
        if nargout > 2
            d = indSortuAuB > n;            % Find indices in indSortuAuB that belong to B
            if d == 0                       % Force d to be correct shape if none of the elements
                d = zeros(0,1);             % in B are in C
            end
            ib = ib(indSortuAuB(d)-n);      % Find indices in indSortuAuB that belong to B
        end
    end
end
end

function flag = convertFlag(flag)
if isscalar(flag)
    flag = char(flag);
else
    error(message('MATLAB:SETXOR:UnknownInput'));
end
end

function [tf, cls] = needsCastingChecks(a,b)
    aIsBuiltinType = (isnumeric(a) || ischar(a) || islogical(a)) && ~isobject(a);
    bIsBuiltinType = (isnumeric(b) || ischar(b) || islogical(b)) && ~isobject(b);
    tf = ~strcmp(class(a), class(b)) && aIsBuiltinType && bIsBuiltinType;
    if aIsBuiltinType && bIsBuiltinType
        % This concatenation does not work for all type combinations, but
        % we only need it for these combinations anyway.
        cls = class([cast([], class(a)); cast([], class(b))]);
    else
        cls = class(a);
    end
end

function flaginds = parseFlags(flaginds, flag, positionOfFlag)
    assert(~isstring(flag));
    if ~ischar(flag)
        error(message('MATLAB:SETXOR:UnknownInput'));
    end
    flagvals = ["rows", "sorted", "stable", "legacy", "R2012a"];   
    foundflag = startsWith(flagvals,flag,'IgnoreCase',true);
    if sum(foundflag) ~= 1
        error(message('MATLAB:SETXOR:UnknownFlag',flag));
    end
    % Only 1 occurrence of each allowed flag value
    if flaginds(foundflag)
        error(message('MATLAB:SETXOR:RepeatedFlag',flag));
    end
    flaginds(foundflag) = positionOfFlag;
end