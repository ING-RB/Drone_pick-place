function [bins, edges] = discretize(x, binspec, varargin)
%

%   Copyright 2016-2024 The MathWorks, Inc.

nin = nargin;
funcname = mfilename();

if ~isa(x, 'duration')
    error(message('MATLAB:duration:discretize:XNotDuration'));
end

fmt = '';
if isa(binspec, 'duration') && ~isscalar(binspec)
    edges = binspec;
    [xdata,edgesdata] = duration.compareUtil(x,edges);
    if ~isvector(edgesdata) || length(edgesdata) < 2
        error(message('MATLAB:duration:discretize:InvalidEdges'));
    elseif ~issorted(edgesdata) || any(isnan(edgesdata))
        error(message('MATLAB:duration:discretize:UnsortedEdges'));
    end
else
    % to determine the edges, we only use the finite data
    xfinite = x;
    xfinite.millis = x.millis(isfinite(x));
    xmin = min(xfinite);
    xmax = max(xfinite);
    if isempty(xfinite) % check for empty data
        xmin = seconds(0);  % just use 0 as reference
        xmax = xmin;
    end
    maxnbins = 65536;  %2^16
    binspec = convertStringsToChars(binspec);
    if isnumeric(binspec)
        validateattributes(binspec, {'numeric'}, {'scalar', 'integer', 'positive'},...
            funcname, 'N', 2);
        edges = generateBinEdgesFromNumBins(binspec,xmin,xmax,false);
    elseif isa(binspec, 'duration')
        if ~(isscalar(binspec) && isfinite(binspec) && binspec > 0)
            error(message('MATLAB:duration:discretize:InvalidDur'));
        end
        edges = generateBinEdgesFromDuration(binspec,xmin,xmax,false,maxnbins);
    elseif ischar(binspec) && isrow(binspec)
        binspec = validatestring(binspec, {'year', 'day', 'hour', ...
            'minute', 'second'}, funcname, 'DUR', 2);
        edges = generateBinEdgesFromBinMethod(binspec,xmin,xmax,false,maxnbins);
    else
        error(message('MATLAB:duration:discretize:InvalidSecondInput'));
    end
    xdata = x.millis;
    edgesdata = edges.millis;
end

nbins = length(edgesdata)-1;
    
persistent p p2;
valuesIsString = nargin > 2 && isstring(varargin{1});
if valuesIsString
    stringValues = varargin{1};
end
[varargin{:}] = convertStringsToChars(varargin{:});

if nin > 2 && isrow(varargin{1}) && ~iscell(varargin{1}) ...
        && strncmpi(varargin{1},'categorical',max(length(varargin{1}),1))
    % create categorical output
    if nin > 3
        if isempty(p)
            % Set the persistent var only when the inputParser is completely
            % initialized to avoid ctrl-C exposing incomplete persistents.
            parser = inputParser;
            addOptional(parser, 'categorynames', NaN, @(x) (iscellstr(x) && ...
                isvector(x)) || (ischar(x) && isrow(x) && ~isempty(x) && ...
                ~strncmpi(x,'I',1)))   %#ok<ISCLSTR> % the check on the first letter is needed
                                      % to differentiate from Name Value
                                      % pair IncludedEdge
            addParameter(parser, 'IncludedEdge', 'left', ...
                @(x) validateattributes(x,{'char'},{}))
            p = parser;
        end
        parse(p,varargin{2:end})
        catnames = p.Results.categorynames;
        catnames_provided = iscell(catnames);
        if catnames_provided
            if length(catnames) ~= nbins
                error(message('MATLAB:discretize:CategoryNamesInvalidSize',nbins));
            end
        elseif ischar(catnames)   % fmt provided
            fmt = catnames;
        end
        
        right = (validatestring(p.Results.IncludedEdge,{'left','right'}) == "right");
    else
        catnames_provided = false;
        right = false;
    end
    
    if ~catnames_provided
        catnames = gencatnames(edges,right,fmt);
    end
    
    bins = matlab.internal.math.discretize(xdata, edgesdata, right);
    
    bins = categorical(bins, 1:nbins, catnames, 'Ordinal', true);
else
    % create numerical output
    if nin > 2
        if isempty(p2)
            % Set the persistent var only when the inputParser is completely
            % initialized to avoid ctrl-C exposing incomplete persistents.
            parser = inputParser;
            addOptional(parser, 'values', [], @(x) isvector(x) && ~isempty(x) ...
                && ~ischar(x) && ~isa(x,'function_handle'))
            addParameter(parser, 'IncludedEdge', 'left', ...
                @(x) validateattributes(x,{'char'},{}))
            p2 = parser;
        end
        parse(p2,varargin{:})
        values = p2.Results.values;
        if valuesIsString && ~matches("values",p2.UsingDefaults)
            % Preserve the type of 'values' when it's a string.
            values = stringValues;
        end
        values_provided = ~isempty(values);
        if values_provided && length(values) ~= nbins
            error(message('MATLAB:discretize:ValuesInvalidSize',nbins));
        end
        right = (validatestring(p2.Results.IncludedEdge,{'left','right'}) == "right");
    else
        values_provided = false;
        right = false;
    end
    
    bins = matlab.internal.math.discretize(xdata, edgesdata, right);
    if values_provided
        nanbins = isnan(bins);
        if isa(values, 'duration')
            binindices = bins;
            if any(nanbins(:))
                values.millis(end+1) = NaN;
                binindices(nanbins) = length(values);
            end
            bins = values;  % bins needs to be duration
            % reshape needed when x and values are vectors of different orientation
            bins.millis = reshape(values.millis(binindices),size(x));        
        else 
            if any(nanbins(:))
                try
                    values(end+1) = NaN;
                catch
                    error(message('MATLAB:discretize:ValuesClassNoNaN',class(values)));
                end
                bins(isnan(bins)) = length(values);
            end
            % reshape needed when x and values are vectors of different orientation
            bins = reshape(values(bins),size(x));
        end
        
    end
    
end

end

function names = gencatnames(edges,includeright,fmt)

if includeright
    leftedge = '(';
    rightedge = ']';
else
    leftedge = '[';
    rightedge = ')';    
end

nbins = length(edges)-1;
names = cell(1,nbins);

charedges = cellstr(edges,fmt);
for i = 1:nbins
    names{i} = sprintf('%s%s, %s%s',leftedge,charedges{i},charedges{i+1},rightedge);
end

if includeright
    names{1}(1) = '[';
else
    names{end}(end) = ']';
end

if length(unique(names)) < length(names)
    error(message('MATLAB:duration:discretize:DefaultCategoryNamesNotUnique'));
end

end



