function [n,xedges,yedges,binx,biny] = histcounts2(x,y,varargin)
% Syntax:
%     [N,XEDGES,YEDGES] = histcounts2(X,Y)
%     [N,XEDGES,YEDGES] = histcounts2(X,Y,NBINS)
%     [N,XEDGES,YEDGES] = histcounts2(X,Y,XEDGES,YEDGES)
%     [N,XEDGES,YEDGES] = histcounts2(___,Name=Value)
%     [N,XEDGES,YEDGES,BINX,BINY] = histcounts2(___)
%
%     Name-Value Arguments:
%         BinMethod
%         BinWidth
%         XBinLimits
%         YBinLimits
%         Normalization
%
% For more information, see documentation

%   Copyright 1984-2024 The MathWorks, Inc.

import matlab.internal.math.binpicker

validateattributes(x,{'numeric','logical'},{'real'}, mfilename, 'x', 1)
validateattributes(y,{'numeric','logical'},{'real','size',size(x)}, ...
    mfilename, 'y', 2)

opts = parseinput(varargin);

% Determine Bin Edges on X axis

if ~isempty(opts.XBinEdges)
    xedges = reshape(opts.XBinEdges,1,[]);
else
    if isempty(opts.XBinLimits)
        if ~isfloat(x)
            % for integers, the edges are doubles
            xc = x(:);
            minx = double(min(xc));
            maxx = double(max(xc));
        else
            xc = x(isfinite(x) & isfinite(y));
            minx = min(xc);  % exclude Inf and NaN
            maxx = max(xc);
        end
    else
        if ~isfloat(opts.XBinLimits)
            % for integers, the edges are doubles
            minx = double(opts.XBinLimits(1));
            maxx = double(opts.XBinLimits(2));
        else
            minx = opts.XBinLimits(1);
            maxx = opts.XBinLimits(2);
        end
        inrange = x>=minx & x<=maxx;
        if ~isempty(opts.YBinLimits)
            inrange = inrange & y>=opts.YBinLimits(1) & y<=opts.YBinLimits(2);
        end
        xc = x(inrange);
    end
    xrange = maxx - minx;
    if ~isempty(opts.NumBins)
        numbins = double(opts.NumBins);
        if isempty(opts.XBinLimits)
            xedges = binpicker(minx,maxx,numbins(1),xrange/numbins(1));
        else
            xedges = linspace(minx, maxx, numbins(1)+1);
        end
    elseif ~isempty(opts.BinWidth)
        if ~isfloat(opts.BinWidth)
            opts.BinWidth = double(opts.BinWidth);
        end
        if ~isempty(minx)
            % Do not create more than maximum bins.
            MaximumBins = getmaxnumbins();       
            if isempty(opts.XBinLimits)
                binWidthx = opts.BinWidth(1);
                leftEdgex = binWidthx*floor(minx/binWidthx);
                nbinsx = max(1,ceil((maxx-leftEdgex) ./ binWidthx));
                if nbinsx > MaximumBins  % maximum exceeded, recompute
                    % See if we can use exactly range/MaximumBins as the 
                    % bin width. This occurs only when miny is exactly a
                    % multiple of range/MaximumBins. Otherwise we use 
                    % range/(MaximumBins-1), to make sure we have exactly
                    % MaximumBins number of bins.
                    if rem(minx*MaximumBins, xrange)==0
                        binWidthx = xrange/MaximumBins;
                        leftEdgex = minx;
                    else
                        binWidthx = xrange/(MaximumBins-1);
                        leftEdgex = binWidthx*floor(minx/binWidthx);
                    end
                    nbinsx = MaximumBins;
                end
                xedges = leftEdgex + (0:nbinsx) .* binWidthx; % get exact multiples
                if xedges(end) < maxx % maxx outside the last edge due to numerical error
                    xedges(end) = maxx;
                end
            else
                binWidthx = max(opts.BinWidth(1), xrange/MaximumBins);
                xedges = minx:binWidthx:maxx;
                if xedges(end) < maxx || isscalar(xedges)
                    xedges = [xedges maxx];
                end
            end
        else
            xedges = cast([0 opts.BinWidth(1)], "like", xrange);
        end
    else    % BinMethod specified
        hardlimits = ~isempty(opts.XBinLimits);
        switch opts.BinMethod
            case 'auto'
                xedges = autorule(xc,minx,maxx,hardlimits);
            case 'scott'
                xedges = scottsrule(xc,minx,maxx,hardlimits);
            case 'fd'
                xedges = fdrule(xc,minx,maxx,hardlimits);
            case 'integers'
                xedges = integerrule(xc,minx,maxx,hardlimits,getmaxnumbins());
        end
    end
end

% Determine Bin Edges on Y axis
if ~isempty(opts.YBinEdges)
    yedges = reshape(opts.YBinEdges,1,[]);
else
    if isempty(opts.YBinLimits)
        if ~isfloat(y)
            % for integers, the edges are doubles
            yc = y(:);
            miny = double(min(yc));
            maxy = double(max(yc));
        else
            yc = y(isfinite(x) & isfinite(y));
            miny = min(yc);  % exclude Inf and NaN
            maxy = max(yc);
        end
    else
        if ~isfloat(opts.YBinLimits)
            % for integers, the edges are doubles
            miny = double(opts.YBinLimits(1));
            maxy = double(opts.YBinLimits(2));
        else
            miny = opts.YBinLimits(1);
            maxy = opts.YBinLimits(2);
        end
        inrange = y>=miny & y<=maxy;
        if ~isempty(opts.XBinLimits)
            inrange = inrange & x>=opts.XBinLimits(1) & x<=opts.XBinLimits(2);
        end
        yc = y(inrange);
    end
    yrange = maxy - miny;
    if ~isempty(opts.NumBins)
        numbins = double(opts.NumBins);
        if isempty(opts.YBinLimits)
            yedges = binpicker(miny,maxy,numbins(2),yrange/numbins(2));
        else
            yedges = linspace(miny, maxy, numbins(2)+1);
        end
    elseif ~isempty(opts.BinWidth)
        if ~isfloat(opts.BinWidth)
            opts.BinWidth = double(opts.BinWidth);
        end
        if ~isempty(miny)
            % Do not create more than maximum bins.
            MaximumBins = getmaxnumbins();
            if isempty(opts.YBinLimits)
                binWidthy = opts.BinWidth(2);
                leftEdgey = binWidthy*floor(miny/binWidthy);
                nbinsy = max(1,ceil((maxy-leftEdgey) ./ binWidthy));
                if nbinsy > MaximumBins  % maximum exceeded, recompute
                    % See if we can use exactly range/MaximumBins as the 
                    % bin width. This occurs only when miny is exactly a
                    % multiple of range/MaximumBins. Otherwise we use 
                    % range/(MaximumBins-1), to make sure we have exactly
                    % MaximumBins number of bins.
                    if rem(miny*MaximumBins, yrange)==0
                        binWidthy = yrange/MaximumBins;
                        leftEdgey = miny;
                    else
                        binWidthy = yrange/(MaximumBins-1);
                        leftEdgey = binWidthy*floor(miny/binWidthy);
                    end
                    nbinsy = MaximumBins;
                end
                yedges = leftEdgey + (0:nbinsy) .* binWidthy; % get exact multiples
                if yedges(end) < maxy % maxy outside the last edge due to numerical error
                    yedges(end) = maxy;
                end
            else
                binWidthy = max(opts.BinWidth(2), yrange/MaximumBins);
                yedges = miny:binWidthy:maxy;
                if yedges(end) < maxy || isscalar(yedges)
                    yedges = [yedges maxy];
                end
            end
        else
            yedges = cast([0 opts.BinWidth(2)], "like", yrange);
        end
    else    % BinMethod specified
        hardlimits = ~isempty(opts.YBinLimits);
        switch opts.BinMethod
            case 'auto'
                yedges = autorule(yc,miny,maxy,hardlimits);
            case 'scott'
                yedges = scottsrule(yc,miny,maxy,hardlimits);
            case 'fd'
                yedges = fdrule(yc,miny,maxy,hardlimits);
            case 'integers'
                yedges = integerrule(yc,miny,maxy,hardlimits,getmaxnumbins());
        end
    end
end

xedges = full(xedges); % make sure edges are non-sparse
yedges = full(yedges);
[~,binx] = matlab.internal.math.histcounts(x,xedges);
[~,biny] = matlab.internal.math.histcounts(y,yedges);

countslenx = length(xedges)-1;
countsleny = length(yedges)-1;
% Filter out NaNs and out-of-range data
subs = [binx(:) biny(:)];
subs(any(subs==0,2),:) = [];
n = accumarray(subs,ones(size(subs,1),1),[countslenx countsleny]);

switch opts.Normalization
    case 'countdensity'
        binarea = double(diff(xedges.')) .* double(diff(yedges));
        n = n./binarea;
    case 'cumcount'
        n = cumsum(cumsum(n,1),2);
    case 'probability'
        n = n/numel(x);
    case 'percentage'
        n = (100 * n) / numel(x);
    case 'pdf'
        binarea = double(diff(xedges.')) .* double(diff(yedges));
        n = n/numel(x)./binarea;
    case 'cdf'
        n = cumsum(cumsum(n/numel(x),1),2);
end

if nargout > 1
    % make sure the returned bin edges have the same shape as inputs
    if ~isempty(opts.XBinEdges)
        xedges = reshape(xedges, size(opts.XBinEdges));
    end
    if ~isempty(opts.YBinEdges)
        yedges = reshape(yedges, size(opts.YBinEdges));
    end
    if nargout > 3
        binx(biny==0) = 0;
        biny(binx==0) = 0;
    end
end

end

function opts = parseinput(input)

opts = struct('NumBins',[],'XBinEdges',[],'YBinEdges',[],'XBinLimits',[],...
    'YBinLimits',[],'BinWidth',[],'Normalization','count','BinMethod','auto');
funcname = mfilename;

% Parse third and fourth input in the function call
inputlen = length(input);
if inputlen > 0
    in = input{1};
    inputoffset = 0;
    if isnumeric(in) || islogical(in)
        if inputlen == 1 || ~(isnumeric(input{2}) || islogical(input{2}))
            % Numbins
            if isscalar(in)
                in = [in in];
            end
            validateattributes(in,{'numeric','logical'},{'integer', 'positive', ...
                'numel', 2, 'vector'}, funcname, 'm', inputoffset+3)
            opts.NumBins = in;
            input(1) = [];
            inputoffset = inputoffset + 1;
        else
            % XBinEdges and YBinEdges
            in2 = input{2};
            validateattributes(in,{'numeric','logical'},{'vector', ...
                'real', 'nondecreasing'}, funcname, 'xedges', inputoffset+3)
            if length(in) < 2
                error(message('MATLAB:histcounts2:EmptyOrScalarXBinEdges'));
            end
            validateattributes(in2,{'numeric','logical'},{'vector', ...
                'real', 'nondecreasing'}, funcname, 'yedges', inputoffset+4)
            if length(in2) < 2
                error(message('MATLAB:histcounts2:EmptyOrScalarYBinEdges'));
            end
            opts.XBinEdges = in;
            opts.YBinEdges = in2;
            input(1:2) = [];
            inputoffset = inputoffset + 2;
        end
        opts.BinMethod = [];
    end
    
    % All the rest are name-value pairs
    inputlen = length(input);
    if rem(inputlen,2) ~= 0
        error(message('MATLAB:histcounts2:ArgNameValueMismatch'))
    end
    
    for i = 1:2:inputlen
        name = validatestring(input{i}, {'NumBins', 'XBinEdges', ...
            'YBinEdges','BinWidth', 'BinMethod', 'XBinLimits', ...
            'YBinLimits','Normalization'}, i+2+inputoffset);
        
        value = input{i+1};
        switch name
            case 'NumBins'
                if isscalar(value)
                    value = [value value]; %#ok
                end
                validateattributes(value,{'numeric','logical'},{'integer', ...
                    'positive', 'numel', 2, 'vector'}, funcname, 'NumBins', i+3+inputoffset)
                opts.NumBins = value;
                if ~isempty(opts.XBinEdges)
                    error(message('MATLAB:histcounts2:InvalidMixedXBinInputs'))
                elseif ~isempty(opts.YBinEdges)
                    error(message('MATLAB:histcounts2:InvalidMixedYBinInputs'))
                end
                opts.BinMethod = [];
                opts.BinWidth = [];
            case 'XBinEdges'
                validateattributes(value,{'numeric','logical'},{'vector', ...
                    'real', 'nondecreasing'}, funcname, 'XBinEdges', i+3+inputoffset);
                if length(value) < 2
                    error(message('MATLAB:histcounts2:EmptyOrScalarXBinEdges'));
                end
                opts.XBinEdges = value;
                % Only set NumBins field to empty if both XBinEdges and
                % YBinEdges are set, to enable BinEdges override of one
                % dimension
                if ~isempty(opts.YBinEdges)
                    opts.NumBins = [];
                    opts.BinMethod = [];
                    opts.BinWidth = [];
                end
                opts.XBinLimits = [];
            case 'YBinEdges'
                validateattributes(value,{'numeric','logical'},{'vector', ...
                    'real', 'nondecreasing'}, funcname, 'YBinEdges', i+3+inputoffset);
                if length(value) < 2
                    error(message('MATLAB:histcounts2:EmptyOrScalarYBinEdges'));
                end                
                opts.YBinEdges = value;
                % Only set NumBins field to empty if both XBinEdges and
                % YBinEdges are set, to enable BinEdges override of one
                % dimension
                if ~isempty(opts.XBinEdges)
                    opts.BinMethod = [];
                    opts.NumBins = [];
                    %opts.BinLimits = [];
                    opts.BinWidth = [];
                end
                opts.YBinLimits = [];
            case 'BinWidth'
                if isscalar(value)
                    value = [value value]; %#ok
                end
                validateattributes(value, {'numeric','logical'}, {'real', 'positive',...
                    'finite','numel',2,'vector'}, funcname, ...
                    'BinWidth', i+3+inputoffset);
                opts.BinWidth = value;
                if ~isempty(opts.XBinEdges)
                    error(message('MATLAB:histcounts2:InvalidMixedXBinInputs'))
                elseif ~isempty(opts.YBinEdges)
                    error(message('MATLAB:histcounts2:InvalidMixedYBinInputs'))
                end
                opts.BinMethod = [];
                opts.NumBins = [];
            case 'BinMethod'
                opts.BinMethod = validatestring(value, {'auto','scott',...
                    'fd','integers'}, funcname, 'BinMethod', i+3+inputoffset);
                if ~isempty(opts.XBinEdges)
                    error(message('MATLAB:histcounts2:InvalidMixedXBinInputs'))
                elseif ~isempty(opts.YBinEdges)
                    error(message('MATLAB:histcounts2:InvalidMixedYBinInputs'))
                end
                opts.BinWidth = [];
                opts.NumBins = [];
            case 'XBinLimits'
                validateattributes(value, {'numeric','logical'}, {'numel', 2, ...
                    'vector', 'real', 'finite','nondecreasing'}, funcname, ...
                    'XBinLimits', i+3+inputoffset)
                opts.XBinLimits = value;
                if ~isempty(opts.XBinEdges)
                    error(message('MATLAB:histcounts2:InvalidMixedXBinInputs'))
                end
            case 'YBinLimits'
                validateattributes(value, {'numeric','logical'}, {'numel', 2, ...
                    'vector', 'real', 'finite','nondecreasing'}, funcname, ...
                    'YBinLimits', i+3+inputoffset)
                opts.YBinLimits = value;
                if ~isempty(opts.YBinEdges)
                    error(message('MATLAB:histcounts2:InvalidMixedYBinInputs'))
                end
            otherwise % 'Normalization'
                opts.Normalization = validatestring(value, {'count', 'countdensity', 'cumcount',...
                    'probability', 'percentage','pdf', 'cdf'}, funcname, 'Normalization', i+3+inputoffset);
        end
    end
end
end

function mb = getmaxnumbins
mb = 1024;
end

function edges = autorule(x, minx, maxx, hardlimits)
xrange = maxx - minx;
if ~isempty(x) && (~isfloat(x) || isequal(round(x),x))...
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
% Note the multiplier and the power are different from the 1D case
binwidth = 3.5*std(x)/(numel(x)^(1/4));
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
    % Note the power is different from the 1D case
    binwidth = 2 * iq * n^(-1/4);
else
    binwidth = 1;
end
if ~hardlimits
    edges = matlab.internal.math.binpicker(minx,maxx,[],binwidth);
else
    edges = matlab.internal.math.binpickerbl(min(x(:)),max(x(:)),minx,maxx,binwidth);
end
end

