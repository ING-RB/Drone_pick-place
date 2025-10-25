function [n,edges,bin] = histcounts(x, varargin)
%

%   Copyright 2016-2024 The MathWorks, Inc.

nin = nargin;

if ~isdatetime(x)
    error(message('MATLAB:datetime:histcounts:NonDatetimeInput'))
end
edgestransposed = false;

if nin < 3
    % optimized code path for no name-value pair inputs
    opts = [];
    if nin == 2 && ~isscalar(varargin{1})
        % bin edges code path
        in = varargin{1};
        if isdatetime(in)
            if ~(isvector(in) && length(in)>=2) 
                error(message('MATLAB:datetime:histcounts:InvalidEdges'))
            elseif ~issorted(in) || any(isnat(in))
                error(message('MATLAB:datetime:histcounts:UnsortedEdges'))
            end
            if iscolumn(in)
                edges = in.';
                edgestransposed = true;
            else
                edges = in;
            end
            [xdata,edgesdata] = datetime.compareUtil(x,edges);
        else
            error(message('MATLAB:datetime:histcounts:NonDatetimeEdges'))
        end
    else
        % default 'auto' BinMethod and numbins code path
        xc = x;
        xc.data = xc.data(:);
        minx = min(xc,[],'includenan');
        maxx = max(xc,[],'includenan');
        if ~isempty(x) && ~(isfinite(minx) && isfinite(maxx))
            % exclude Inf and NaN
            xc.data = x.data(isfinite(x));
            minx = min(xc);
            maxx = max(xc);
        end
        % deal with empty case
        if isempty(xc)
            minx = datetime('now', 'TimeZone', x.tz);  % use the current time
            maxx = minx;
        end
        
        if nin == 1  % auto bin method
            edges = autorule(xc, minx, maxx, false);
        else   % numbins
            numbins = varargin{1};
            validateattributes(numbins,{'numeric','logical'},{'integer', 'positive'}, ...
                mfilename, 'm', 2)
            edges = generateBinEdgesFromNumBins(numbins,minx,maxx,false);
        end
        xdata = x.data;
        edgesdata = edges.data;
    end
else
    % parse through inputs including name-value pairs
    opts = parseinput(varargin);
    
    if ~isempty(opts.BinEdges)
        if iscolumn(opts.BinEdges)
            edges = opts.BinEdges.';
            edgestransposed = true;
        else
            edges = opts.BinEdges;
        end
        [xdata,edgesdata] = datetime.compareUtil(x,edges);
    else
        if isempty(opts.BinLimits)  % Bin Limits is not specified
            xc = x;
            xc.data = xc.data(:);
            minx = min(xc,[],'includenan');
            maxx = max(xc,[],'includenan');
            if ~isempty(x) && ~(isfinite(minx) && isfinite(maxx))
                % exclude Inf and NaN
                xc.data = x.data(isfinite(x));
                minx = min(xc);
                maxx = max(xc);
            end            
            % deal with empty case
            if isempty(xc)
                minx = datetime('now', 'TimeZone', x.tz);  % use the current time
                maxx = minx;
            end
            hardlimits = false;
        else % Bin Limits specified
            minx = opts.BinLimits;
            minx.data = minx.data(1);
            maxx = opts.BinLimits;
            maxx.data = maxx.data(2);
            xc = x;
            xc.data = xc.data(isbetween(xc,minx,maxx));
            hardlimits = true;
        end
        
        maxnbins = 65536;  %2^16, limit for using bin width and bin methods
        if ~isempty(opts.NumBins)
            edges = generateBinEdgesFromNumBins(opts.NumBins,minx,maxx,hardlimits);
        elseif ~isempty(opts.BinWidth)
            if isduration(opts.BinWidth)
                edges = generateBinEdgesFromDuration(opts.BinWidth,minx,...
                    maxx,hardlimits,maxnbins);
            else  % calendarDuration
                edges = generateBinEdgesFromCalendarDuration(...
                    opts.BinWidth,minx,maxx,hardlimits,maxnbins);
            end
        else    % BinMethod specified
            switch opts.BinMethod
                case 'auto'
                    edges = autorule(xc,minx,maxx,hardlimits);
                case 'scott'
                    edges = scottsrule(xc,minx,maxx,hardlimits);
                case 'fd'
                    edges = fdrule(xc,minx,maxx,hardlimits);
                case 'sqrt'
                    edges = sqrtrule(xc,minx,maxx,hardlimits);
                case 'sturges'
                    edges = sturgesrule(xc,minx,maxx,hardlimits);
                otherwise
                    edges = generateBinEdgesFromBinMethod(opts.BinMethod,...
                        minx,maxx,hardlimits,maxnbins);
            end
        end
        xdata = x.data;
        edgesdata = edges.data;
        
    end
end

if nargout <= 2
    n = matlab.internal.datetime.datetimeHistcounts(xdata, edgesdata);
else
    [n,bin] = matlab.internal.datetime.datetimeHistcounts(xdata,edgesdata);
end

if ~isempty(opts)
    % For normalization methods probability, percentage, and cdf, use the total
    % number of elements including non-finite values and values outside the
    % bins.
    switch opts.Normalization
        case 'cumcount'
            n = cumsum(n);
        case 'probability'
            n = n / numel(x);
        case 'percentage'
            n = (100 * n) / numel(x);
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
funcname = mfilename;

% Parse second input in the function call
if ~isempty(input)
    in = input{1};
    inputoffset = 0;
    if isnumeric(in) || islogical(in)
        if isscalar(in)
            validateattributes(in,{'numeric','logical'},{'integer', 'positive'}, ...
                funcname, 'm', inputoffset+2)
            opts.NumBins = in;
            opts.BinMethod = [];
        else
            error(message('MATLAB:datetime:histcounts:NonDatetimeEdges'))
        end
        input(1) = [];
        inputoffset = 1;
    elseif isdatetime(in)
        if ~(isvector(in) && length(in)>=2)
            error(message('MATLAB:datetime:histcounts:InvalidEdges'))
        elseif ~issorted(in) || any(isnat(in))
            error(message('MATLAB:datetime:histcounts:UnsortedEdges'))
        end
        opts.BinEdges = in;
        opts.BinMethod = [];
        input(1) = [];
        inputoffset = 1;
    end
    
    % All the rest are name-value pairs
    inputlen = length(input);
    if rem(inputlen,2) ~= 0
        error(message('MATLAB:datetime:histcounts:ArgNameValueMismatch'))
    end
    
    for i = 1:2:inputlen
        name = validatestring(input{i}, {'NumBins', 'BinEdges', 'BinWidth', 'BinLimits', ...
            'Normalization', 'BinMethod'}, i+1+inputoffset);
        
        value = input{i+1};
        switch name
            case 'NumBins'
                validateattributes(value,{'numeric','logical'},{'scalar', 'integer', ...
                    'positive'}, funcname, 'NumBins', i+2+inputoffset)
                opts.NumBins = value;
                if ~isempty(opts.BinEdges)
                    error(message('MATLAB:datetime:histcounts:InvalidMixedBinInputs'))
                end
                opts.BinMethod = [];
                opts.BinWidth = [];
            case 'BinEdges'
                if ~(isdatetime(value) && isvector(value) && length(value)>=2)
                    error(message('MATLAB:datetime:histcounts:InvalidEdges'))
                elseif ~issorted(value) || any(isnat(value))
                    error(message('MATLAB:datetime:histcounts:UnsortedEdges'))
                end
                opts.BinEdges = value;
                opts.BinMethod = [];
                opts.NumBins = [];
                opts.BinWidth = [];
                opts.BinLimits = [];
            case 'BinWidth'
                if isduration(value)
                    if ~(isscalar(value) && isfinite(value) && value > 0)
                        error(message('MATLAB:datetime:histcounts:InvalidBinWidth'));
                    end
                elseif iscalendarduration(value)
                    if ~(isscalar(value) && isfinite(value))
                        error(message('MATLAB:datetime:histcounts:InvalidBinWidth'));
                    end
                    [caly,calm,cald,calt] = split(value,{'year','month','day','time'});
                    if (caly < 0 || calm < 0 || cald < 0 || calt < 0) || ...
                            (caly == 0 && calm == 0 && cald == 0 && calt == 0)
                        error(message('MATLAB:datetime:histcounts:InvalidBinWidth'));
                    end
                else
                    error(message('MATLAB:datetime:histcounts:InvalidBinWidth'));
                end
                
                opts.BinWidth = value;
                if ~isempty(opts.BinEdges)
                    error(message('MATLAB:datetime:histcounts:InvalidMixedBinInputs'))
                end
                opts.BinMethod = [];
                opts.NumBins = [];
            case 'BinLimits'
                if ~(isdatetime(value) && numel(value)==2 && issorted(value) && ...
                        all(isfinite(value)))
                    error(message('MATLAB:datetime:histcounts:InvalidBinLimits'))
                end
                opts.BinLimits = value;
                if ~isempty(opts.BinEdges)
                    error(message('MATLAB:datetime:histcounts:InvalidMixedBinInputs'))
                end
            case 'Normalization'
                opts.Normalization = validatestring(value, {'count', 'cumcount',...
                    'probability', 'percentage', 'cdf'}, funcname, 'Normalization', i+2+inputoffset);
            otherwise % 'BinMethod'
                opts.BinMethod = validatestring(value, {'second', 'minute', ...
                    'hour', 'day', 'week', 'month', 'quarter', 'year', ...
                    'decade', 'century', 'auto','scott', 'fd', ...
                    'sturges', 'sqrt'}, funcname, 'BinMethod', i+2+inputoffset);
                if ~isempty(opts.BinEdges)
                    error(message('MATLAB:datetime:histcounts:InvalidMixedBinInputs'))
                end
                opts.BinWidth = [];
                opts.NumBins = [];
        end
    end
end
end

function edges = autorule(x, minx, maxx, hardlimits)
edges = scottsrule(x,minx,maxx,hardlimits);
end

function edges = scottsrule(x, minx, maxx, hardlimits)
% Scott's normal reference rule
binwidth = 3.5*std(x)/(numel(x)^(1/3));

% guard against constant or empty data
if binwidth > 0
    nbins = max(ceil((maxx-minx)/binwidth),1);
else
    nbins = 1;
end
    
edges = generateBinEdgesFromNumBins(nbins, minx, maxx, hardlimits);
end

function iq = localiqr(x)
n = numel(x);
F = ((1:n)'-.5) / n;
if n > 0
    iq = diff(interp1(F, sort(x), [.25; .75]));
else
    iq = seconds(NaN);
end
end

function edges = fdrule(x, minx, maxx, hardlimits)
n = numel(x);
xcol = reshape(x,[],1);
xrange = max(xcol) - min(xcol);
% guard against constant or empty data
if n > 1 && xrange > 0
    % Guard against too small an IQR.  This may be because there
    % are some extreme outliers.
    iq = max(localiqr(xcol),xrange/10);
    binwidth = 2 * iq * n^(-1/3);
    nbins = max(ceil((maxx-minx)/binwidth),1);
else
    nbins = 1;
end
edges = generateBinEdgesFromNumBins(nbins, minx, maxx, hardlimits);
end

function edges = sturgesrule(x, minx, maxx, hardlimits)
nbins = max(ceil(log2(numel(x))+1),1);
edges = generateBinEdgesFromNumBins(nbins, minx, maxx, hardlimits);
end

function edges = sqrtrule(x, minx, maxx, hardlimits)
nbins = max(ceil(sqrt(numel(x))),1);
edges = generateBinEdgesFromNumBins(nbins, minx, maxx, hardlimits);
end
