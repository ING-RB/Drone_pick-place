function [n,edges,bin] = histcounts(x, a, varargin)
% Syntax:
%     [N,EDGES] = histcounts(X)
%     [N,EDGES] = histcounts(X,NBINS)
%     [N,EDGES] = histcounts(X,EDGES)
%     [N,EDGES,BIN] = histcounts(___)
%
%     N = histcounts(C)
%     N = histcounts(C,CATEGORIES)
%     [N,CATEGORIES] = histcounts(___)
%
%     [___] = histcounts(___,Name=Value)
%
%     Name-Value Arguments:
%         BinLimits
%         BinMethod
%         BinWidth
%         BinEdges
%         Normalization
%         NumBins
%
% For more information, see documentation

%   Copyright 1984-2024 The MathWorks, Inc.

if ~(isnumeric(x) || islogical(x))
    error(message('MATLAB:histcounts:NonNumericInput'))
end

if ~isreal(x)
    error(message('MATLAB:histcounts:ComplexX'))
end

nin = nargin;
edgestransposed = false;

if nin < 3
    % optimized code path for no name-value pair inputs
    opts = [];
    if nin == 2 && ~isscalar(a)
        % bin edges code path
        validateBinEdges(a);

        if iscolumn(a)
            edges = a.';
            edgestransposed = true;
        else
            edges = a;
        end
    else
        % default 'auto' BinMethod and numbins code path
        if ~isfloat(x)
            % for integers, the edges are doubles
            xc = x(:);
            minx = double(min(xc));
            maxx = double(max(xc));
        else
            xc = x(:);
            minx = min(xc,[],'includenan');
            maxx = max(xc,[],'includenan');
            if ~isempty(x) && ~(isfinite(minx) && isfinite(maxx))
                % exclude Inf and NaN
                xc = x(isfinite(x));
                minx = min(xc);
                maxx = max(xc);
            end
        end
        if nin == 1  % auto bin method
            edges = autorule(xc, minx, maxx, false);
        else   % numbins
            validateBinNumber(a);
            xrange = maxx - minx;
            numbins = double(a);
            edges = matlab.internal.math.binpicker(minx,maxx,numbins,xrange/numbins);
        end
    end
else
    % parse through inputs including name-value pairs
    opts = parseinput([{a};varargin(:)]);

    if isempty(opts.BinLimits)  % Bin Limits is not specified
        if ~isempty(opts.BinEdges)
            if iscolumn(opts.BinEdges)
                edges = opts.BinEdges.';
                edgestransposed = true;
            else
                edges = opts.BinEdges;
            end
        else
            if ~isfloat(x)
                % for integers, the edges are doubles
                xc = x(:);
                minx = double(min(xc));
                maxx = double(max(xc));
            else
                xc = x(:);
                minx = min(xc,[],'includenan');
                maxx = max(xc,[],'includenan');
                if ~isempty(x) && ~(isfinite(minx) && isfinite(maxx))
                    % exclude Inf and NaN
                    xc = x(isfinite(x));
                    minx = min(xc);
                    maxx = max(xc);
                end
            end
            if ~isempty(opts.NumBins)
                numbins = double(opts.NumBins);
                xrange = maxx - minx;
                edges = matlab.internal.math.binpicker(minx,maxx,numbins,xrange/numbins);
            elseif ~isempty(opts.BinWidth)
                if ~isfloat(opts.BinWidth)
                    opts.BinWidth = double(opts.BinWidth);
                end
                xrange = maxx - minx;
                if ~isempty(minx)
                    binWidth = opts.BinWidth;
                    leftEdge = binWidth*floor(minx/binWidth);
                    nbins = max(1,ceil((maxx-leftEdge) ./ binWidth));
                    % Do not create more than maximum bins.
                    MaximumBins = getmaxnumbins();
                    if nbins > MaximumBins  % maximum exceeded, recompute
                        % Try setting bin width to xrange/(MaximumBins-1).
                        % In cases where minx is exactly a multiple of
                        % xrange/MaximumBins, then we can set bin width to
                        % xrange/MaximumBins-1 instead.
                        nbins = MaximumBins;
                        binWidth = xrange/(MaximumBins-1);
                        leftEdge = binWidth*floor(minx/binWidth);

                        if maxx <= leftEdge + (nbins-1) * binWidth
                            binWidth = xrange/MaximumBins;
                            leftEdge = minx;
                        end
                    end
                    edges = leftEdge + (0:nbins) .* binWidth; % get exact multiples
                    if edges(end) < maxx % maxx outside the last edge due to numerical error
                        edges(end) = maxx;
                    end
                else
                    edges = cast([0 opts.BinWidth], "like", xrange);
                end
            else    % BinMethod specified
                if strcmp(opts.BinMethod, 'auto')
                    edges = autorule(xc, minx, maxx, false);
                else
                    switch opts.BinMethod
                        case 'scott'
                            edges = scottsrule(xc,minx,maxx,false);
                        case 'fd'
                            edges = fdrule(xc,minx,maxx,false);
                        case 'integers'
                            edges = integerrule(xc,minx,maxx,false,getmaxnumbins());
                        case 'sqrt'
                            edges = sqrtrule(xc,minx,maxx,false);
                        case 'sturges'
                            edges = sturgesrule(xc,minx,maxx,false);
                    end
                end
            end
        end

    else   % BinLimits specified
        if ~isfloat(opts.BinLimits)
            % for integers, the edges are doubles
            minx = double(opts.BinLimits(1));
            maxx = double(opts.BinLimits(2));
        else
            minx = opts.BinLimits(1);
            maxx = opts.BinLimits(2);
        end
        if ~isempty(opts.NumBins)
            numbins = double(opts.NumBins);
            edges = [minx + (0:numbins-1).*((maxx-minx)/numbins), maxx];
        elseif ~isempty(opts.BinWidth)
            if ~isfloat(opts.BinWidth)
                opts.BinWidth = double(opts.BinWidth);
            end
            % Do not create more than maximum bins.
            MaximumBins = getmaxnumbins();
            binWidth = max(opts.BinWidth, (maxx-minx)/MaximumBins);
            edges = minx:binWidth:maxx;
            if edges(end) < maxx || isscalar(edges)
                edges = [edges maxx];
            end

        else    % BinMethod specified
            xc = x(x>=minx & x<=maxx);
            if strcmp(opts.BinMethod, 'auto')
                edges = autorule(xc, minx, maxx, true);
            else
                switch opts.BinMethod
                    case 'scott'
                        edges = scottsrule(xc,minx,maxx,true);
                    case 'fd'
                        edges = fdrule(xc,minx,maxx,true);
                    case 'integers'
                        edges = integerrule(xc,minx,maxx,true,getmaxnumbins());
                    case 'sqrt'
                        edges = sqrtrule(xc,minx,maxx,true);
                    case 'sturges'
                        edges = sturgesrule(xc,minx,maxx,true);
                end
            end
        end
    end
end

edges = full(edges); % make sure edges are non-sparse
if nargout <= 2
    n = matlab.internal.math.histcounts(x,edges);
else
    [n,bin] = matlab.internal.math.histcounts(x,edges);
end

if ~isempty(opts)
    switch opts.Normalization
        case 'countdensity'
            n = n./double(diff(edges));
        case 'cumcount'
            n = cumsum(n);
        case 'probability'
            n = n / numel(x);
        case 'percentage'
            n = (100 * n) / numel(x);
        case 'pdf'
            n = n/numel(x)./double(diff(edges));
        case 'cdf'
            n = cumsum(n / numel(x));
    end
end

if nargin > 1 && edgestransposed
    % make sure the returned bin edges have the same shape as inputs
    edges = edges.';
end
end

function opts = parseinput(input)

opts = struct('NumBins',[],'BinEdges',[],'BinLimits',[],...
    'BinWidth',[],'Normalization','count','BinMethod','auto');

% Parse second input in the function call
if ~isempty(input)
    in = input{1};
    if isnumeric(in) || islogical(in)
        if isscalar(in)
            validateBinNumber(in);
            opts.NumBins = in;
            opts.BinMethod = [];
        else
            validateBinEdges(in);
            opts.BinEdges = in;
            opts.BinMethod = [];
        end
        input(1) = [];
    end

    % All the rest are name-value pairs
    inputlen = length(input);
    if rem(inputlen,2) ~= 0
        error(message('MATLAB:histcounts:ArgNameValueMismatch'))
    end

    for i = 1:2:inputlen
        name = validateStringOption(input{i}, {'NumBins', 'BinEdges', 'BinWidth', 'BinLimits', ...
            'Normalization', 'BinMethod'}, 'InvalidName');

        value = input{i+1};
        switch name
            case 'NumBins'
                validateBinNumber(value);
                opts.NumBins = value;
                if ~isempty(opts.BinEdges)
                    error(message('MATLAB:histcounts:InvalidMixedBinInputs'))
                end
                opts.BinMethod = [];
                opts.BinWidth = [];
            case 'BinEdges'
                validateBinEdges(value);
                if length(value) < 2
                    error(message('MATLAB:histcounts:EmptyOrScalarBinEdges'));
                end
                opts.BinEdges = value;
                opts.BinMethod = [];
                opts.NumBins = [];
                opts.BinWidth = [];
                opts.BinLimits = [];
            case 'BinWidth'
                if ~(isnumeric(value) || islogical(value)) || ...
                        ~isscalar(value) || ~isreal(value) || ...
                        value <= 0 || ~isfinite(value)
                    error(message('MATLAB:histcounts:InvalidBinWidth'))
                end
                opts.BinWidth = value;
                if ~isempty(opts.BinEdges)
                    error(message('MATLAB:histcounts:InvalidMixedBinInputs'))
                end
                opts.BinMethod = [];
                opts.NumBins = [];
            case 'BinLimits'
                if ~(isnumeric(value) || islogical(value)) || numel(value)~=2 ...
                        || ~isvector(value) || ~isreal(value) || ~allfinite(value)
                    error(message('MATLAB:histcounts:InvalidBinLimits'))
                end
                if any(diff(value) < 0)
                    error(message('MATLAB:histcounts:DecreasingBinLimits'));
                end
                opts.BinLimits = value;
                if ~isempty(opts.BinEdges)
                    error(message('MATLAB:histcounts:InvalidMixedBinInputs'))
                end
            case 'Normalization'
                opts.Normalization = validateStringOption(value, {'countdensity', 'cumcount',...
                    'probability', 'percentage','pdf', 'cdf'}, 'InvalidNormalization');
                % Differentiate between 'count' and 'countdensity'
                if strcmp(opts.Normalization,'countdensity') && matlab.internal.math.checkInputName(value,'count')
                    opts.Normalization = 'count';
                end
            otherwise % 'BinMethod'
                opts.BinMethod = validateStringOption(value, {'auto','scott', 'fd', ...
                    'integers', 'sturges', 'sqrt'}, 'InvalidBinMethod');
                if ~isempty(opts.BinEdges)
                    error(message('MATLAB:histcounts:InvalidMixedBinInputs'))
                end
                opts.BinWidth = [];
                opts.NumBins = [];
        end
    end
end
end

function mb = getmaxnumbins
mb = 65536;  %2^16
end

function edges = autorule(x, minx, maxx, hardlimits)
xrange = maxx - minx;
if ~isempty(x) && (isinteger(x) || islogical(x) || isequal(round(x),x))...
        && xrange <= 50 && maxx <= flintmax(class(maxx))/2 ...
        && minx >= -flintmax(class(minx))/2
    edges = integerrule(x,minx,maxx,hardlimits,getmaxnumbins());
else
    edges = scottsrule(x,minx,maxx,hardlimits);
end
end

function edges = scottsrule(x, minx, maxx, hardlimits)
% Scott's normal reference rule
if ~isfloat(x)
    x = double(x);
end
binwidth = 3.5*std(x)/(numel(x)^(1/3));
if ~hardlimits
    edges = matlab.internal.math.binpicker(minx,maxx,[],binwidth);
else
    edges = matlab.internal.math.binpickerbl(min(x(:)),max(x(:)),minx,maxx,binwidth);
end
end

function edges = fdrule(x, minx, maxx, hardlimits)
n = numel(x);
xrange = max(x(:)) - min(x(:));
if n > 1
    % Guard against too small an IQR.  This may be because there
    % are some extreme outliers.
    iq = max(iqr(double(x(:))),double(xrange)/10);
    binwidth = 2 * iq * n^(-1/3);
else
    binwidth = 1;
end
if ~hardlimits
    edges = matlab.internal.math.binpicker(minx,maxx,[],binwidth);
else
    edges = matlab.internal.math.binpickerbl(min(x(:)),max(x(:)),minx,maxx,binwidth);
end
end

function edges = sturgesrule(x, minx, maxx, hardlimits)
nbins = max(ceil(log2(numel(x))+1),1);
if ~hardlimits
    binwidth = (maxx-minx)/nbins;
    if isfinite(binwidth)
        edges = matlab.internal.math.binpicker(minx,maxx,[],binwidth);
    else
        edges = matlab.internal.math.binpicker(minx,maxx,nbins,binwidth);
    end
else
    edges = linspace(minx,maxx,nbins+1);
end
end

function edges = sqrtrule(x, minx, maxx, hardlimits)
nbins = max(ceil(sqrt(numel(x))),1);
if ~hardlimits
    binwidth = (maxx-minx)/nbins;
    if isfinite(binwidth)
        edges = matlab.internal.math.binpicker(minx,maxx,[],binwidth);
    else
        edges = matlab.internal.math.binpicker(minx,maxx,nbins,binwidth);
    end
else
    edges = linspace(minx,maxx,nbins+1);
end
end

function validateBinEdges(in)
if ~(isnumeric(in) || islogical(in)) || ~isvector(in) || isempty(in) || ~isreal(in) || anynan(in)
    error(message('MATLAB:histcounts:InvalidBinEdges'))
end

if any(diff(in) < 0)
    error(message('MATLAB:histcounts:DecreasingBinEdges'))
end
end

function validateBinNumber(in)
if ~(isnumeric(in) || islogical(in)) || ~isscalar(in)|| ~(fix(in) == in) || ...
         ~isreal(in) || in <= 0 || ~isfinite(in)
    error(message('MATLAB:histcounts:InvalidBinNumber'))
end
end
function option = validateStringOption(name,validOptions,errorTag)
possibleOptions = matlab.internal.math.checkInputName(name,validOptions);
if sum(possibleOptions) ~= 1
    error(message(['MATLAB:histcounts:',errorTag]));
end
option = validOptions{possibleOptions};
end