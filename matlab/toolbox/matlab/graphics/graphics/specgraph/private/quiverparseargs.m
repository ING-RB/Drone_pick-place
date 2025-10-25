function pvpairs = quiverparseargs(args, isQuiver3)
% identify convenience args for QUIVER and QUIVER3 and return all inputs as a list of PV pairs

%   Copyright 2009-2020 The MathWorks, Inc.

[numericArgs,pvpairs] = parseparams(args);
nargs = length(numericArgs);

if iscell(args{end}) && isempty(args{end})
    error(message('MATLAB:quiver:InvalidCellInput'));
end

validNumInputs = [2 3 4 5];
if isQuiver3
    validNumInputs = [4 5 6 7];
end

% Check number of numeric inputs    
if ~ismember(nargs,validNumInputs)
    % too many numeric input args, nargs must be one of [2,3,4,5}
    error(message('MATLAB:quiver:InvalidNumInputs', num2str( nargs )));    
end

pvpairs = matlab.graphics.internal.convertStringToCharArgs(pvpairs);
extrapv = {};

% separate 'off' (scale) arg from pvpairs - scale must be first non-data arg
foundScaleOff = false;
if length(pvpairs)>=1
    
    % check for 'off' or partial match 'of' (do not accept 'o' as a partial 
    % match, as this would conflict with linespec)
    if strcmpi(pvpairs{1},'off') || strcmpi(pvpairs{1},'of')
        foundScaleOff = true;
        pvpairs(1) = [];
        extrapv = {'AutoScale','off'};
    end
end

% separate 'filled' or LINESPEC from pvpairs 
n = 1;
foundFilled = false;
foundLinespec = false;
while length(pvpairs) >= 1 && n < 3 && matlab.graphics.internal.isCharOrString(pvpairs{1})
    
    arg = lower(pvpairs{1});
    
    % check for 'filled'
    if ~foundFilled
        if arg(1) == 'f'
            foundFilled = true;
            pvpairs(1) = [];
            extrapv = [{'MarkerFaceColor','auto'},extrapv];
        end
    end

    % check for linespec
    if ~foundLinespec && numel(pvpairs)>=1
        [l,c,m,msg]=colstyle(pvpairs{1});
        if isempty(msg)
            foundLinespec = true;
            pvpairs(1) = [];
            if ~isempty(l)
                extrapv = [{'LineStyle',l},extrapv];
            end
            if ~isempty(c)
                extrapv = [{'Color',c},extrapv];
            end
            if ~isempty(m)
                extrapv = [{'ShowArrowHead','off'},extrapv];
                if ~isequal(m,'.')
                    extrapv = [{'Marker',m},extrapv];
                end
            end
        end
    end
    
    if ~(foundFilled || foundLinespec)
        break
    end
    n = n+1;
end

% check for unbalanced pvpairs list
if rem(length(pvpairs),2) ~= 0
    error(message('MATLAB:quiver:UnevenPvPairsCount'));
end

pvpairs = [extrapv pvpairs];

% Deal with quiver(..., AutoScaleFactor) syntax (numeric scale arg)
if nargs == validNumInputs(2) || nargs == validNumInputs(4)
    
    if foundScaleOff % cannot provide scale twice
        error(message('MATLAB:quiver:UnevenPvPairsCount'));
    end
    
    if isa(numericArgs{nargs},'double') && isscalar(numericArgs{nargs})
        if args{nargs} > 0
            pvpairs = [pvpairs,{'AutoScale','on',...
                'AutoScaleFactor',numericArgs{nargs}}];
        else
            pvpairs = [pvpairs,{'AutoScale','off'}];
        end
        numericArgs = numericArgs(1:end-1);
        nargs = length(numericArgs);
    else
        error(message('MATLAB:quiver:InvalidAutoScaleFactor'));
    end
end

numericArgs = matlab.graphics.chart.internal.getRealData(numericArgs); % get the real component if data are complex

% Deal with data arguments. Valid data arguments are: 
% quiver(U, V)              nargs = 2; isQuiver3 = false
% quiver(X, Y, U, V)        nargs = 4; isQuiver3 = false
% quiver3(Z, U, V, W)       nargs = 4; isQuiver3 = true
% quiver3(X, Y, Z, U, V, W) nargs = 6; isQuiver3 = true

xy_pvpairs = {};
zuvw_pvpairs = {};

% UV Data
% 2D - U & V are always the last two args
% 3D - U, V, W are alwasy the last three args
u = matlab.graphics.chart.internal.datachk(numericArgs{nargs-1-isQuiver3});
v = matlab.graphics.chart.internal.datachk(numericArgs{nargs-isQuiver3});

su = size(u);
sv = size(v);

if ~isequal(su,sv)
    error(message('MATLAB:quiver:UVSizeMismatch'));
end

zuvw_pvpairs = {'UData',u,'VData',v};

% ZW Data (3D only)
if isQuiver3
    
    % Z is always 4th to last arg; W is always the last arg
    % quiver3(Z, U, V, W)
    % quiver3(X, Y, Z, U, V, W)
    z = matlab.graphics.chart.internal.datachk(numericArgs{nargs-3});
    w = matlab.graphics.chart.internal.datachk(numericArgs{nargs});
    
    sz = size(z);
    sw = size(w);
    
    if ~isequal(sz,su)
        error(message('MATLAB:quiver:ZUSizeMismatch'));
    elseif ~isequal(sv,sw)
        error(message('MATLAB:quiver:VWSizeMismatch'));
    end
    
    zuvw_pvpairs = [{'ZData',z} zuvw_pvpairs {'WData',w}];
end

% XY Data
if nargs == validNumInputs(3)
    
    % when provided, X&Y are always the first two args
    % quiver(X, Y, U, V)
    % quiver3(X, Y, Z, U, V, W)
    x = matlab.graphics.chart.internal.datachk(numericArgs{1});
    y = matlab.graphics.chart.internal.datachk(numericArgs{2});
    
    if xor(isempty(x), isempty(y))
        error(message('MATLAB:quiver:XYMixedEmpty'));
    end
    
    xy_pvpairs = {'XData',x,'YData',y};
    
    if isempty(x) % handle empty x data
        sx = su;
        sy = su;
    else
        sx = size(x);
        sy = size(y);
    end

    % validate X & Y data size matches
    if ~(isequal(sx,su) || isequal(length(x),su(2)) )
        if isQuiver3
            error(message('MATLAB:quiver:XZSizeMismatch'));
        end
        error(message('MATLAB:quiver:XUSizeMismatch'));
    elseif ~(isequal(sy,su) || isequal(length(y),su(1)) )
        if isQuiver3
            error(message('MATLAB:quiver:YZSizeMismatch'));
        end
        error(message('MATLAB:quiver:YUSizeMismatch'));
    elseif ~(isequal(sx,sy) || (isvector(x) && isvector(y)))
        if isQuiver3
            error(message('MATLAB:quiver:XYMixedFormat', getString( message( 'MATLAB:quiver:XYMixedFormatZ' ) )))
        end
        error(message('MATLAB:quiver:XYMixedFormat', getString( message( 'MATLAB:quiver:XYMixedFormatU' ) )))
    end
end

pvpairs = [pvpairs, xy_pvpairs, zuvw_pvpairs];

end


