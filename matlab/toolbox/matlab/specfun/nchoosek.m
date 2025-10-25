function c = nchoosek(v,k)
%NCHOOSEK Binomial coefficient or all combinations.
%   NCHOOSEK(N,K) where N and K are non-negative integers returns N!/K!(N-K)!.
%   This is the number of combinations of N things taken K at a time.
%   When a coefficient is large, a warning will be produced indicating
%   possible inexact results. In such cases, the result is only accurate
%   to 15 digits for double-precision inputs, or 8 digits for single-precision
%   inputs.
%
%   NCHOOSEK(V,K) where V is a vector of length N, produces a matrix
%   with N!/K!(N-K)! rows and K columns. Each row of the result has K of
%   the elements in the vector V. This syntax is only practical for
%   situations where N is less than about 15.
%
%   Class support for inputs N,K:
%      float: double, single
%      integer: uint8, int8, uint16, int16, uint32, int32, uint64, int64
%
%   Class support for inputs V:
%      float: double, single
%      integer: uint8, int8, uint16, int16, uint32, int32, uint64, int64
%      logical, char
%
%   See also PERMS.

%   Copyright 1984-2024 The MathWorks, Inc.

if ~isscalar(k) || k < 0 || ~isreal(k) || k ~= round(k)
    error(message('MATLAB:nchoosek:InvalidArg2'));
end

if ~isvector(v)
    error(message('MATLAB:nchoosek:InvalidArg1'));
end

% the first argument is a scalar integer
if isscalar(v) && isnumeric(v) && isreal(v) && v==round(v) && v >= 0
    % if the first argument is a scalar, then, we only return the number of
    % combinations. Not the actual combinations.
    % We use the Pascal triangle method. No overflow involved. c will be
    % the biggest number computed in the entire routine.
    %
    n = v;  % rename v to be n. the algorithm is more readable this way.
    if isinteger(n)
        if ~(strcmp(class(n),class(k)) || isa(k,'double'))
            error(message('MATLAB:nchoosek:mixedIntegerTypes'))
        end
        classOut = class(n);
        inttype = true;
        int64type = isa(n,'int64') || isa(n,'uint64');
    elseif isinteger(k)
        if ~isa(n,'double')
            error(message('MATLAB:nchoosek:mixedIntegerTypes'))
        end
        classOut = class(k);
        inttype = true;
        int64type = isa(k,'int64') || isa(k,'uint64');
    else % floating point types
        classOut = superiorfloat(n,k);
        inttype = false;
        int64type = false;
    end
    
    if k > n
        error(message('MATLAB:nchoosek:KOutOfRange'));
    elseif ~int64type && n > flintmax
        error(message('MATLAB:nchoosek:NOutOfRange'));
    end
    
    if k > n/2   % use smaller k if available
        k = n-k;
    end
    
    if k <= 1
        c = n^k;
    else
        if int64type
            % For 64-bit integers, use an algorithm that avoids
            % converting to doubles
            c = binCoefInt(n,k,classOut);
        else
            % Do the computation in doubles.
            nd = full(double(n));
            kd = full(double(k));
            
            % Customer suggestion:
            maxRelErr = 0;
            c = nd;
            for i = 2:kd
                % Recursively compute
                % nchoosek(n, i) = (n-i+1) / i * nchoosek(n, i-1)
                c = c * ((nd-i+1) / i);
                
                if ~(2*eps(c) < 0.5)
                    % Round-off error may be larger than 0.5, meaning round
                    % may add some round-off error to the result.
                    maxRelErr = maxRelErr + 2*eps;
                end
                c = round(c);
            end
            
            % Use uint64 computation if there was round-off error
            if maxRelErr ~= 0 && c <= 2*double(intmax('uint64'))
                % May get more accurate result using uint64 instead.
                cInt = binCoefInt(n, k, 'uint64');
                if cInt < intmax('uint64')
                    c = cInt;
                    maxRelErr = 0;
                end
            end
            
            if inttype
                 % Only <64bit integer types, round-off in double only
                 % starts when these are saturated already.
                maxRelErr = 0;
            elseif c > flintmax(classOut)
                maxRelErr = max(maxRelErr, double(eps(classOut)));
            end
            
            if maxRelErr ~= 0 && isfinite(c)
                warning(message('MATLAB:nchoosek:LargeCoefficient', ...
                    num2str(maxRelErr), num2str(ceil(maxRelErr*c))))
            end
            
            % Convert answer back to the correct type
            c = cast(c,classOut);
        end
    end
    
else
    % the first argument is a vector, generate actual combinations.
    
    k = double(k);
    n = length(v);
    if iscolumn(v)
        v = v.';
    end
    
    if n == k
        c = v;
    elseif n == k + 1
        c = repmat(v,n,1);
        c(1:n+1:n*n) = [];
        c = reshape(c,n,k);
    elseif k == 1
        c = v.';
    elseif k == 0
        c = reshape(v([]), 1, 0);
    elseif k > n
        c = reshape(v([]), 0, k);
    else
        if isnumeric(v) && ~isobject(v)
           c = combs(v,k);
        else
           c = combs(1:n,k);
           c = v(c);
        end
    end

end


function c = binCoefInt(n,k,classOut)

n = cast(n, classOut);
k = cast(k, classOut);
im = intmax(classOut);

c = n; % = nchoosek(n, 1)

for i = 2:k
    % Recursively compute nchoosek(n, i) = (n-i+1) / i * nchoosek(n, i-1).
    % Each iteration computes c = (c * m) / i, avoiding overflow in c*m.
    m = (n-i+1);
    cm = c*m;
    
    if cm ~= im
        % No overflow, can use simple formula
        c = cm / i;
    else
        % Do c = (c*m)/i, but avoid overflow by splitting up c == cr+i*ci
        cr = rem(c, i);
        ci = (c - cr) / i;
        
        c = ci * m + (cr * m) / i;
        
        if c == im
            % Overflow reached, no need to iterate more.
            break;
        end
    end
end


function P = combs(v,k)
%COMBS  All possible combinations.
%   COMBS(1:N,M) or COMBS(V,M) where V is a row vector of length N,
%   creates a matrix with N!/((N-M)! M!) rows and M columns containing
%   all possible combinations of N elements taken M at a time.
%
%   This function is only practical for situations where M is less
%   than about 15.

v = v(:).'; % Make sure v is a row vector.
n = length(v);

total = nchoosek(n, k);
if isinf(total) % Can overflow, give useful error for that case.
    error(message('MATLAB:pmaxsize'));
end
P = zeros(total, k, "like", v);

% Compute P one row at a time:
ind = 1:k;
P(1, :) = v(1:k);
for i=2:total
    % Find right-most index to increase
    % j = find(ind < n-k+1:n, 1, 'last');
    for j = k:-1:1
        if ind(j)<n-k+j
            break;
        end
    end
    
    % Increase index j, initialize all indices to j's right.
    % ind(j:k) = (ind(j) + 1) : (ind(j) + 1 + k - j);
    % P(i, :) = v(ind);
    for t=1:j-1
        P(i, t) = v(ind(t));
    end
    indj = ind(j) - j + 1;
    for t = j:k
        ind(t) = indj + t;
        P(i, t) = v(indj + t);
    end
end