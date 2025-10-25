function [M,F,C] = mode(x,dim)
%MODE   Mode, or most frequent value in a sample.
%   M=MODE(X) for vector X computes M as the sample mode, or most frequently
%   occurring value in X.  For a matrix X, M is a row vector containing
%   the mode of each column.  For N-D arrays, MODE(X) is the mode of the
%   elements along the first non-singleton dimension of X.
%
%   When there are multiple values occurring equally frequently, MODE
%   returns the smallest of those values.  For complex inputs, this is taken
%   to be the first value in a sorted list of values.
%
%   [M,F]=MODE(X) also returns an array F, of the same size as M.
%   Each element of F is the number of occurrences of the corresponding
%   element of M.
%
%   [M,F,C]=MODE(X) also returns a cell array C, of the same size
%   as M.  Each element of C is a sorted vector of all the values having
%   the same frequency as the corresponding element of M.
%
%   [...]=MODE(X,'all') is the mode of all elements in X.
%
%   [...]=MODE(X,DIM) takes the mode along the dimension DIM of X.
%
%   [...]=MODE(X,VECDIM) operates on the dimensions specified in the vector 
%   VECDIM. For example, MODE(X,[1 2]) operates on the elements contained
%   in the first and second dimensions of X.
%
%   This function is most useful with discrete or coarsely rounded data.
%   The mode for a continuous probability distribution is defined as
%   the peak of its density function.  Applying the MODE function to a
%   sample from that distribution is unlikely to provide a good estimate
%   of the peak; it would be better to compute a histogram or density
%   estimate and calculate the peak of that estimate.  Also, the MODE
%   function is not suitable for finding peaks in distributions having
%   multiple modes.
%
%   Example:
%       X = [3 3 1 4; 0 0 1 1; 0 1 2 4]
%       mode(X,1)
%       mode(X,2)
%
%      % To find the mode of a continuous variable grouped into bins:
%      y = randn(1000,1);
%      edges = -6:.25:6;
%      bin = discretize(y,edges);
%      m = mode(bin);
%      edges([m, m+1])
%      histogram(y,edges)
%
%   Class support for input X:
%      float:  double, single
%      integer: uint8, int8, uint16, int16, uint32, int32, uint64, int64
%
%   See also MEAN, MEDIAN, HISTOGRAM, HISTCOUNTS.

%   Copyright 2005-2024 The MathWorks, Inc.

if isstring(x)
    error(message('MATLAB:mode:wrongInput'));
end

dofreq = nargout>=2;
docell = nargout>=3;

if nargin<2
    % Special case to make mode, mean, and median behave similarly for []
    if isequal(x, [])
        M = modeForEmpty(x,1);
        if dofreq
            F = zeros("like",full(double(x([]))));
        end
        if docell
            C = {zeros(0,1,"like",x)};
        end
        return
    end
    
    % Determine the first non-singleton dimension
    dim = find(size(x)~=1, 1);
    if isempty(dim)
        dim = 1;
    end
else
    if isnumeric(dim) && isvector(dim)
        if ~isreal(dim) || any(dim~=floor(dim)) || any(dim<1) || ~allfinite(dim)
            error(message('MATLAB:mode:BadDim'));
        end
        if ~isscalar(dim) && numel(unique(dim)) ~= numel(dim)
            error(message('MATLAB:mode:vecDimsMustBeUniquePositiveIntegers'));
        end
        dim = reshape(dim, 1, []);
    elseif (ischar(dim) && isrow(dim)) || (isstring(dim) && isscalar(dim) && strlength(dim) > 0)
        if strncmpi(dim,'all',max(strlength(dim), 1))
            x = x(:);
            dim = 1;
        else
            error(message('MATLAB:mode:BadDim'));
        end
    else
        error(message('MATLAB:mode:BadDim'));
    end
end

if issparse(x)
    % permuting beyond second dimension not supported for sparse
    dim(dim > 2) = [];
else
    dim = min(dim, ndims(x)+1);
end

sizex = size(x);
if max(dim)>length(sizex)
    sizex(end+1:max(dim)) = 1;
end

sizem = sizex;
sizem(dim) = 1;

tf = false(size(sizem));
tf(dim) = true;
dim = find(tf);

% Dispose of empty arrays right away
if isempty(x)
    M = modeForEmpty(x,sizem);
    if dofreq
        F = zeros(sizem,"like",full(double(x([]))));
    end
    if docell
        C = cell(sizem);
        C(:) = {M(1:0)};  % fill C with empties of the proper type
    end
    return
end

if isvector(x) && (isscalar(dim) && dim <=2)
    % Treat vectors separately
    if (iscolumn(x) && dim == 2) || (~iscolumn(x) && dim == 1)
        % No computation needed for mode(col,2) and mode(row,1)
        M = x;
        
        if dofreq
            F = ones(sizex,"like",full(double(x([]))));
        end
        if docell
            C = num2cell(x);
        end
    else
        % Sort the vector and compute the mode
        x = sort(x(:));
        if docell || isobject(x)
            % start of run of equal values
            start = find([1; x(1:end-1)~=x(2:end)]);
            % frequencies for each run (force to double datatype)
            freq = zeros(numel(x),1,"like",full(double(x([]))));
            freq(start) = [diff(start); numel(x)+1-start(end)];
            [maxfreq,firstloc] = max(freq);
        
            M = x(firstloc);                % Mode
        
            if dofreq
                F = maxfreq;                % Frequency
            end

            C = {x(freq == maxfreq)};   % Cell array with modes
        else
            % Only need mode, do simple loop.
            M = x(1);
            F = 1;
            freq = 1;
            for i = 2:numel(x)
                if x(i) ~= x(i-1)
                    if freq > F
                        M = x(i-1);
                        F = freq;
                    end
                    freq = 0;
                end
                freq = freq + 1;
            end
            % The last element could be the mode
            if freq > F
                F = freq;
                M = x(end);
            end
        end
    end
else
    % Permute data and reshape into a 2-D array
    perm = [dim, find(~tf)];
    x = permute(x, perm);
    x = reshape(x, [prod(sizex(dim)), prod(sizem)]);
    [nrows,ncols] = size(x);
    
    % Compute the modes for each column of the 2-D array
    x = sort(x,1);
    % start of run of equal values
    start = [ones(1,ncols); x(1:end-1,:)~=x(2:end,:)];
    start = find(start(:));
    % frequencies for each run (force to double datatype)
    freq = zeros([nrows,ncols],"like",full(double(x([]))));
    freq(start) = [start(2:end); numel(x)+1]-start;
    [maxfreq,firstloc] = max(freq,[],1);
    
    M = x((0:nrows:numel(x)-1)+firstloc);           % Modes for each column
    M = reshape(M, sizem);           % Reshape and permute back
    
    if dofreq
        F = reshape(maxfreq, sizem); % Frequencies
    end
    if docell
        C = cell(size(M));                          % Cell array with modes
        selection = freq == maxfreq;
        for j = 1:numel(M)
            C{j} = x(selection(:,j),j);
        end
    end
end

function m = modeForEmpty(x,sizem)
if isinteger(x) || islogical(x)
    m = zeros(sizem,"like",x);
else
    m = NaN(sizem,"like",x);
end
