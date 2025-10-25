function [bins, edges] = discretize(x, binspec, varargin)
%

%   Copyright 2016-2024 The MathWorks, Inc.

nin = nargin;
funcname = mfilename();

if ~isa(x, 'datetime')
    error(message('MATLAB:datetime:discretize:XNotDateTime'));
end

% parameter for displaying default category names
twoedgesformat = true;
if isa(binspec, 'datetime')
    edges = binspec;
    [xdata,edgesdata] = datetime.compareUtil(x,edges);
    if ~(isvector(edgesdata) && length(edgesdata) >= 2)       
        error(message('MATLAB:datetime:discretize:InvalidEdges'));
    elseif ~issorted([real(edgesdata(:)) imag(edgesdata(:))],'rows') || ...
            any(isnan(edgesdata))
        error(message('MATLAB:datetime:discretize:UnsortedEdges'));
    end
    fmt = edges.fmt;
else
    % to determine the edges, we only use the finite data
    xfinite = x;
    xfinite.data = x.data(isfinite(x));
    % check for empty data
    if isempty(xfinite) 
        % set left edge to the Posix epoch
        xmin = datetime.fromMillis(0,x); 
        xmax = xmin;
    else
        % set limits 
        xmin = min(xfinite);
        xmax = max(xfinite);
    end
    fmt = '';
    maxnbins = 65536;  %2^16, limit for using bin width and bin methods
    binspec = convertStringsToChars(binspec);
    if isnumeric(binspec)
        validateattributes(binspec, {'numeric'}, {'scalar', 'integer', 'positive'},...
            funcname, 'N', 2);
        % for numeric bins set right edge to n seconds away from left edge
        if isempty(xfinite)
            xmax = xmin + seconds(binspec);
        end
        edges = generateBinEdgesFromNumBins(binspec,xmin,xmax,false);
    elseif isa(binspec, 'duration')
        if ~(isscalar(binspec) && isfinite(binspec) && binspec > 0)
            error(message('MATLAB:datetime:discretize:InvalidDur'));
        end
        edges = generateBinEdgesFromDuration(binspec,xmin,xmax,false,maxnbins);
    elseif isa(binspec, 'calendarDuration')
        if ~(isscalar(binspec) && isfinite(binspec))
            error(message('MATLAB:datetime:discretize:InvalidDur'));
        end
        [caly,calm,cald,calt] = split(binspec,{'year','month','day','time'});
        if (caly < 0 || calm < 0 || cald < 0 || calt < 0) || ... 
                (caly == 0 && calm == 0 && cald == 0 && calt == 0)
            error(message('MATLAB:datetime:discretize:InvalidDur'));
        end
        edges = generateBinEdgesFromCalendarDuration(binspec,xmin,xmax,false,maxnbins);
    elseif ischar(binspec) && isrow(binspec)
        binspec = validatestring(binspec, {'century', 'decade', 'year', 'quarter', ...
            'month', 'week', 'day', 'hour', 'minute', 'second'}, funcname, ...
            'DUR', 2);
        [edges,twoedgesformat,fmt] = generateBinEdgesFromBinMethod(binspec,xmin,xmax,false,maxnbins);
    else
        error(message('MATLAB:datetime:discretize:InvalidSecondInput'));
    end
    xdata = x.data;
    edgesdata = edges.data;
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
        right = (validatestring(p.Results.IncludedEdge,{'left','right'}) == "right");
        if right && ischar(binspec) && xmax.data==edgesdata(end-1)
            edges.data(end) = [];
            nbins = nbins - 1;
        end
        catnames = p.Results.categorynames;
        catnames_provided = iscell(catnames);
        if catnames_provided 
            if length(catnames) ~= nbins
                error(message('MATLAB:discretize:CategoryNamesInvalidSize',nbins));
            end
        elseif ischar(catnames)  % fmt provided
            fmt = catnames;   
        end
    else
        catnames_provided = false;
        right = false;
    end
    
    if ~catnames_provided
        catnames = gencatnames(edges,right,twoedgesformat,fmt);
    end
    
    bins = matlab.internal.datetime.datetimeDiscretize(xdata, edgesdata, right);
    
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
        right = (validatestring(p2.Results.IncludedEdge,{'left','right'}) == "right");
        if right && ischar(binspec) && xmax.data==edgesdata(end-1)
            edges.data(end) = [];
            nbins = nbins - 1;
        end
        values = p2.Results.values;
        if valuesIsString && ~any(p2.UsingDefaults == "values")
            % Preserve the type of 'values' when it's a string.
            values = stringValues;
        end
        values_provided = ~isempty(values);
        if values_provided && length(values) ~= nbins
            error(message('MATLAB:discretize:ValuesInvalidSize',nbins));
        end
    else
        values_provided = false;
        right = false;
    end
    
    bins = matlab.internal.datetime.datetimeDiscretize(xdata, edgesdata, right);
    if values_provided
        nanbins = isnan(bins);
        if isa(values, 'datetime')
            binindices = bins;
            if any(nanbins(:))
                values.data(end+1) = NaN;               
                binindices(nanbins) = length(values);
            end
            bins = values;  % bins need to be datetime
            % reshape needed when x and values are vectors of different orientation
            bins.data = reshape(values.data(binindices),size(x));           
        else
            if any(nanbins(:))
                try
                    values(end+1) = NaN;
                catch
                    error(message('MATLAB:discretize:ValuesClassNoNaN',class(values)));
                end
                bins(nanbins) = length(values);
            end
            % reshape needed when x and values are vectors of different orientation
            bins = reshape(values(bins),size(x));
        end
        
    end
    
end

end

function names = gencatnames(edges,includeright,twoedgesformat,fmt)

import matlab.internal.datetime.getDatetimeSettings

if ~twoedgesformat
    names = cellstr(edges,fmt);
    names = names(1:end-1);
else
    fullprecision = ~all(timeofday(edges) == seconds(0));
    if ~fullprecision
        if isempty(fmt)
            fmt = getDatetimeSettings('defaultdateformat');
        end
        % Without full precision (i.e. no time component in datetime), always
        % use [A,B) regardless of closedRight. For example, if A and B are at
        % day boundaries, (23-Sep-2016,24-Sep-2016] is confusing when the ] only
        % means including the exact midnight of 24-Sep-2016, rather than the
        % entire day of 24-Sep-2016.
        leftedge = '[';
        rightedge = ')';
    else
        if isempty(fmt)
            fmt = getDatetimeSettings('defaultformat');
            fmt = increaseFormatSubsecondPrecision(fmt, edges);
        end
        if includeright
            leftedge = '(';
            rightedge = ']';
        else
            leftedge = '[';
            rightedge = ')';
        end
    end

    nbins = length(edges)-1;
    names = cell(1,nbins);
  
    charedges = cellstr(edges,fmt);
    for i = 1:nbins
        names{i} = sprintf('%s%s, %s%s',leftedge,charedges{i},...
            charedges{i+1},rightedge);
    end
    
    if fullprecision
        if includeright
            names{1}(1) = '[';
        else
            names{end}(end) = ']';
        end
    end
    
end

if length(unique(names)) < length(names)
    error(message('MATLAB:categorical:DuplicatedCatNamesDatetime'));
end

end


function fmt = increaseFormatSubsecondPrecision(fmt, edges)
%numUniqueEdges = numel(unique(dateshift(edges,'start','second','current')));
edgePrecision = min(diff(edges));
if edgePrecision < seconds(1) % Potential to get subsecond degenerate bin edges
    [timeStart, timeEnd, timeStruct] = regexp(fmt,'(?<hms>(?i:HH)\Wmm\Wss)(?<subSec>\W?S+)?','start', 'end', 'names');
    % Only add fractional seconds if the existing fmt has time components.
    if ~isempty(timeStart)
        % Figure out number of digits of subsecond precision. 
        totS = -floor(log10(seconds(edgePrecision)));
        % Add S's if need more than the existing subsecond precision (which
        % may not exist).
        if totS > max([strlength(timeStruct.subSec) - 1, 0])
            if isempty(timeStruct.subSec) % no sub-second .SSS
                % use '.' as default fractional second separator
                fmt = [fmt(1:timeEnd), '.', repmat('S',[1,totS]), fmt(timeEnd+1:end)];
            else % already has some sub-seconds
                fmt = [fmt(1:timeStart-1), timeStruct.hms, timeStruct.subSec(1),repmat('S',[1,totS]), fmt(timeEnd+1:end)];
            end
        end
    end
end
end

