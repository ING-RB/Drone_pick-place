function h = waterfall(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

[cax,args,nargs] = axescheck(varargin{:});
if nargs < 1
    error(message('MATLAB:narginchk:notEnoughInputs'));
end
[args, pvpairs] = parseparams(args);
nargs = numel(args);

switch nargs
    case 1
        z = args{1};
        c = z;
        x = 1:size(z,2);
        y = 1:size(z,1);
    case 2
        y = args{2};
        z = args{1};
        c = y;
        x = 1:size(z,2);
        y = 1:size(z,1);
    case 3
        [x, y, z] = deal(args{1:3});
        c = z;
    case 4
        [x, y, z, c] = deal(args{1:4});
end

if min(size(x)) == 1 || min(size(y)) == 1
    [x,y]=meshgrid(x,y);
end
x = matlab.graphics.chart.internal.datachk(x,'numeric');
y = matlab.graphics.chart.internal.datachk(y,'numeric');
z = matlab.graphics.chart.internal.datachk(z,'numeric');

% Create the plot
cax = newplot(cax);
nextPlot = cax.NextPlot;

% Add 2 data points to the beginning and three data points at the end
% of each row for a patch.  Two of the points on each side are used
% to make sure the curtain is a constant color under 'interp' or
% 'flat' edge color.  The final point on the right is used to
% make bottom edge invisible.
x = [x(:,[1 1]) x x(:,size(x,2)*[1 1 1])];
y = [y(:,[1 1]) y y(:,size(y,2)*[1 1 1])];
c0 = (max(max(c))+min(min(c)))/2;
z0 = min(min(z));
if z0==max(max(z)) % Special case for a constant surface
    if z0==0
        z0 = -1;
    else
        z0 = z0 - abs(z0)/2;
    end
end

z = [z0*ones(size(x,1),1) z(:,1) z z(:,size(z,2)) z0*ones(size(x,1),2) ];
c = [c0*ones(size(c,1),2)  c c0*ones(size(c,1),2) NaN(size(x,1),1)];

hp = patch(x',y',z',c','EdgeColor','flat','Parent',cax,pvpairs{:});
matlab.graphics.internal.matchBackgroundColor(cax,hp,'FaceColor');

switch nextPlot
    case {'replaceall','replace'}
        view(cax,3);
        grid(cax,'on');
    case {'replacechildren'}
        view(cax,3);
end

% return handles, if requested
if nargout > 0
    h = hp;
end

