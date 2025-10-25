function h = pcolor(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

%   J.N. Little 1-5-92

% Parse possible Axes input
[cax,args,nargs] = axescheck(varargin{:});
if nargs < 1
    error(message('MATLAB:narginchk:notEnoughInputs'));
end

[args, pvpairs] = parseparams(args);
nargs = numel(args);

if isvector(args{end})
    error(message('MATLAB:pcolor:NonMatrixColorInput'));
end
if nargs == 3 && LdimMismatch(args{1:3})
    error(message('MATLAB:pcolor:InputSizeMismatch'));
end
for k = 1:nargs
    if isnumeric(args{k}) && ~isreal(args{k})
        error(message('MATLAB:pcolor:NonRealInputs'));
    end
end

cax = newplot(cax);
nextPlot = cax.NextPlot;

if isscalar(args)
    x = args{1};
    hh = surface(zeros(size(x)),x,'Parent',cax,pvpairs{:});
    [m,n] = size(x);
    xlims = [1 n];
    ylims = [1 m];
else
    [x,y,c] = deal(args{1:3});
    hh = surface(x,y,zeros(size(c)),c,'Parent',cax, pvpairs{:});
    if iscategorical(x)
        xlims = makeCategoricalLimits(x);
    else
        xlims = [min(min(x)) max(max(x))];
    end
    if iscategorical(y)
        ylims = makeCategoricalLimits(y);
    else
        ylims = [min(min(y)) max(max(y))];
    end
end
set(hh,'AlignVertexCenters','on');

if ismember(nextPlot, {'replace','replaceall'})
    set(cax,'View',[0 90]);
    set(cax,'Box','on');
    if ~iscategorical(xlims) && xlims(2) <= xlims(1)
        xlims(2) = xlims(1)+1;
    end
    if ~iscategorical(ylims) &&  ylims(2) <= ylims(1)
        ylims(2) = ylims(1)+1;
    end

    if strcmp(cax.Type, 'polaraxes')
        rlim(cax, ylims);
    else
        xlim(cax, xlims);
        ylim(cax, ylims);
    end
end
if nargout == 1
    h = hh;
end
end

function ok = LdimMismatch(x,y,z)
[xm,xn] = size(x);
[ym,yn] = size(y);
[zm,zn] = size(z);
ok = (xm == 1 && xn ~= zn) || ...
    (xn == 1 && xm ~= zn) || ...
    (xm ~= 1 && xn ~= 1 && (xm ~= zm || xn ~= zn)) || ...
    (ym == 1 && yn ~= zm) || ...
    (yn == 1 && ym ~= zm) || ...
    (ym ~= 1 && yn ~= 1 && (ym ~= zm || yn ~= zn));
end

function categoricalLimits = makeCategoricalLimits(x)
% Convert the categories to double, estimate limits
% Convert the doubles back to categorical, restoring
% the original categories
cats = categories(x);
x_d = double(x);
xlims_d = [min(min(x_d)), max(max(x_d))];
categoricalLimits = categorical(cats(xlims_d), cats);
end

