function [bins, edges] = discretize(x, edges, varargin)
%   Syntax:
%      BINS = discretize(X,EDGES)
%      [BINS,EDGES] = discretize(X,N)
%      [___] = discretize(X,DUR)
%      [___] = discretize(___,VALUES)
%
%      [___] = discretize(___,"categorical")
%      [___] = discretize(___,"categorical",DISPLAYFORMAT)
%      [___] = discretize(___,"categorical",CATEGORYNAMES)
%
%      [___] = discretize(___,IncludedEdge=SIDE)
%
%   For more information, see documentation

%   Copyright 1984-2024 The MathWorks, Inc.

nin = nargin;

if ~(isnumeric(x) || islogical(x)) || ~isreal(x)
    error(message('MATLAB:discretize:invalidType'));
end

if ~(isnumeric(edges) || islogical(edges)) || ~isvector(edges) || ~isreal(edges) ...
        || ~issorted(edges) || anynan(edges) % nondecreasing check
    if isscalar(edges)
        error(message('MATLAB:discretize:InvalidN'));
    else
        error(message('MATLAB:discretize:InvalidSecondInput'));
    end
end

if isscalar(edges)
    numbins = double(edges);
    if fix(numbins) ~= numbins || numbins < 1 || ~isfinite(numbins)
        error(message('MATLAB:discretize:InvalidN'));
    end
    xfinite = x(isfinite(x));
    xmin = min(xfinite);
    xmax = max(xfinite);
    xrange = xmax - xmin;
    edges = matlab.internal.math.binpicker(xmin,xmax,numbins,...
        xrange/numbins);
elseif isempty(edges)
    error(message('MATLAB:discretize:EmptyOrScalarEdges'));
end

% make sure edges are non-sparse, handle subclass of builtin class
if isobject(x)
    x = castToBuiltinSuperclass(x);
end
if isobject(edges)
    edges = castToBuiltinSuperclass(edges);
end
edges = full(edges);
nbins = numel(edges)-1;

if nin > 2 && checkCharString(varargin{1}) && startsWith("categorical",varargin{1},'IgnoreCase',true)
    % create categorical output
    catnames_provided = false;
    right = false;
    if nin > 3
        idx = 2;
        % Convert scalar string to char in certain cases to distinguish
        % IncludedEdge NV pair from catnames
        if isstring(varargin{idx}) && isscalar(varargin{idx})
            if nbins ~= 1
                % catnames is not scalar, treat as NV-pair
                varargin{idx} = char(varargin{idx});
            elseif strcmpi("IncludedEdge",varargin{idx})
                % exact match, treat as NV-pair
                varargin{idx} = char(varargin{idx});
            end
        end

        % Parse catnames input
        if (iscellstr(varargin{idx}) || isstring(varargin{idx})) && isvector(varargin{idx})
            catnames_provided = true;
            catnames = varargin{idx};
            idx = idx+1;
            if length(catnames) ~= nbins
                error(message('MATLAB:discretize:CategoryNamesInvalidSize',nbins));
            end
        end

        % Parse NV pair
        if rem(nargin-idx+1,2) == 0
            right = parseNVpair(varargin, right, idx);
        elseif catnames_provided
            error(message('MATLAB:discretize:KeyWithoutValue'));
        else
            error(message('MATLAB:discretize:InvalidCatnames'));
        end
    end

    if ~catnames_provided
        catnames = matlab.internal.datatypes.numericBinEdgesToCategoryNames(edges,right);
    end

    bins = matlab.internal.math.discretize(x, edges, right);

    bins = categorical(bins, 1:nbins, catnames, 'Ordinal', true);
else
    % create numerical output
    values_provided = false;
    right = false;
    if nin > 2
        idx = 1;
        % Parse values
        if isvector(varargin{idx}) && ~isempty(varargin{idx}) && ...
                ~ischar(varargin{idx}) && ~(isstring(varargin{idx}) && isscalar(varargin{idx})) ...
                && ~isa(varargin{idx},'function_handle')
            values_provided = true;
            values = varargin{idx};
            idx = idx+1;
            if numel(values) ~= nbins
                error(message('MATLAB:discretize:ValuesInvalidSize',nbins));
            end
        end

        % Parse NV pair
        if rem(nargin-idx+1,2) == 0
            right = parseNVpair(varargin, right, idx);
        elseif values_provided
            error(message('MATLAB:discretize:KeyWithoutValue'));
        else
            error(message('MATLAB:discretize:InvalidValues'));
        end
    end

    bins = matlab.internal.math.discretize(x, edges, right);
    if values_provided
        nanbins = isnan(bins);
        if any(nanbins(:))
            try
                values(end+1) = NaN;
            catch
                error(message('MATLAB:discretize:ValuesClassNoNaN',class(values)));
            end
            bins(nanbins) = numel(values);
        end
        % reshape needed when x and values are vectors of different orientation
        bins = reshape(values(bins),size(x));
    end

end

end

function flag = checkCharString(inputName)
flag = (ischar(inputName) && isrow(inputName)) || (isstring(inputName) && isscalar(inputName) ...
    && strlength(inputName) ~= 0);
end

function right = parseNVpair(nvpairs, right, idx)
% Parse 'IncludedEdge'
for j = idx:2:numel(nvpairs)
    name = nvpairs{j};
    if ~checkCharString(name)
        error(message('MATLAB:discretize:ParseFlags'));
    elseif startsWith("IncludedEdge",name,'IgnoreCase',true)
        if checkCharString(nvpairs{j+1})
            if startsWith("right",nvpairs{j+1},'IgnoreCase',true)
                right = true;
            elseif startsWith("left",nvpairs{j+1},'IgnoreCase',true)
                right = false;
            else
                error(message('MATLAB:discretize:InvalidIncludedEdgeValue'));
            end
        else
            error(message('MATLAB:discretize:InvalidIncludedEdgeValue'));
        end
    else
        error(message('MATLAB:discretize:ParseFlags'));
    end
end
end

function y = castToBuiltinSuperclass(x)
% castToBuiltinSuperclass cast objects of
% a subclass of a builtin type to their builtin superclass.
if isa(x, 'double')
    y = double(x);
elseif isa(x, 'single')
    y = single(x);
elseif isa(x, 'uint8')
    y = uint8(x);
elseif isa(x, 'int8')
    y = int8(x);
elseif isa(x, 'uint16')
    y = uint16(x);
elseif isa(x, 'int16')
    y = int16(x);
elseif isa(x, 'uint32')
    y = uint32(x);
elseif isa(x, 'int32')
    y = int32(x);
elseif isa(x, 'uint64')
    y = uint64(x);
elseif isa(x, 'int64')
    y = int64(x);
elseif isa(x, 'logical')
    y = logical(x);
else
    error(message('MATLAB:castToBuiltinSuperclass:UnsupportedType'));
end
end