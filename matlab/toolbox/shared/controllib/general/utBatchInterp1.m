function yi = utBatchInterp1(x,y,xi)
%UTBATCHINTERP1  Interpolation of vector-valued functions of one variable.
% 
%   YI = UTBATCHINTERP1(X,Y,XI) interpolates to find YI, the values of the
%   underlying vector-valued function Y=F(X) at the points in the array XI. 
%   X must be a vector of length N and Y must be an array with N rows. This
%   function returns an array YI with LENGTH(XI) rows and the same remaining
%   sizes as Y.
%
%   Class support for inputs X, Y, XI:
%      float: double, single
%
%   See also INTERP1.

%   Copyright 1984-2011 The MathWorks, Inc.


% Input Error Checking
narginchk(3,3)

n = numel(x);
siz_y = size(y);
if siz_y(1)~=n
   ctrlMsgUtils.error('Controllib:utility:utBatchInterp1')
end

% Work with column vectors
y = y(:,:);
x = x(:);
xi = xi(:);

% Spacing between entries of x
h = diff(x);

% Check to see if X is sorted
if any(h<0)
    % Sort X
    [x,p] = sort(x);
    y = y(p,:);
    h = diff(x);
end

% Check for uniqueness of x
% Note inf-inf is nan
duplicateXidx = find(h == 0 | isnan(h));
if ~isempty(duplicateXidx)
    % Remove duplicate entries
    % Note: length(h) = length(x) - 1
    x(duplicateXidx) = [];
    y(duplicateXidx,:) = [];
    h(duplicateXidx) = [];
    % Adjust n for the change in size of y and x
    n = length(x);
end

% Initialize YI with NaN (extrapolation value is NaN)
yi = nan([numel(xi) siz_y(2:end)],superiorfloat(x,y,xi));

% Perform interpolation
if (n < 2)
    % Handle case when size of X and Y is 1
    yi(x==xi,:) = y;
else
    % Interpolate
    
    % Since yi is initialized with NaN only need to work with Xi that are
    % in the range of X
    inBoundsIdx = find(xi>=x(1) & xi<=x(n));
    xi = xi(inBoundsIdx);

    % Find indices of subintervals, x(k) <= u < x(k+1),
    % or u < x(1) or u >= x(m-1).
    [~,~,k] = histcounts(xi,x);
    k(k==n) = n-1;

    for ct = 1:numel(xi)
        bin = k(ct);
        % Special handling is performed for non finite endpoints of X
        % Recall X is sorted and unique
        if (bin == 1) && (x(bin) == -inf)
            % Case: -inf <= xi < b needs to be handled
            % if xi = -inf then yi = y(bin)
            % if xi is finite then yi = y(bin+1)
            yi(inBoundsIdx(ct),:) = y(bin+~isinf(xi(ct)),:);
        elseif (bin == (n-1)) && (x(bin+1) == inf)
            % Case: a < xi <= inf needs to be handled
            % if xi = inf then yi = y(bin+1)
            % if xi is finite then yi = y(bin)
            yi(inBoundsIdx(ct),:) = y(bin+isinf(xi(ct)),:);
        else
            % x(bin), x(bin+1), xi(ct) are all finite
            s = (xi(ct) - x(bin))/h(bin);
            if (s==0) || (s==1)
                % Xi lies on a point in X
                yi(inBoundsIdx(ct),:) = y(bin+s,:);
            else
                % Xi lies between two points in X and interpolate
                yi(inBoundsIdx(ct),:) = (1-s)*y(bin,:) + s*y(bin+1,:);
            end
        end
    end

end
        
