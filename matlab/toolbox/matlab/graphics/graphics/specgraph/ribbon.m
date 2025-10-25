function hh = ribbon(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

narginchk(1,inf);
[cax, args] = axescheck(varargin{:});
[args, pvpairs] = parseparams(args);
nargs = numel(args);
if nargs > 3
    error(message('MATLAB:narginchk:tooManyInputs'))
end

% Parse input arguments.
if nargs<3
    width = .75;
    [msg,x,y] = xychk(args{1:nargs},'plot');
else
    width = args{3};
    [msg,x,y] = xychk(args{1:2},'plot');
end

if ~isempty(msg)
    error(msg);
end
if isscalar(x) || isscalar(y)
    error(message('MATLAB:ribbon:ScalarInputs'));
end

cax = newplot(cax);
nextPlot = cax.NextPlot;

m = size(y,1);
zz = [-ones(m,1) ones(m,1)]/2;
cc = ones(size(y,1),2);

n = size(y,2);
h = gobjects(n,1);
for n=1:size(y,2)
    h(n) = surface(zz*width+n,[x(:,n) x(:,n)],[y(:,n) y(:,n)],n*cc, ...
        'Parent', cax, pvpairs{:});
end

switch nextPlot
    case {'replaceall','replace'}
        view(cax,3);
        grid(cax,'on');
    case {'replacechildren'}
        view(cax,3);
end

if nargout>0
    hh = h; 
end

