function hout=surfl(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

[cax, args] = axescheck(varargin{:});
[args, pvpairs] = parseparams(args);

useLight = ~isempty(pvpairs) && strcmp(pvpairs{1}, "light");
if useLight || ~isempty(pvpairs) && strcmp(pvpairs{1}, "cdata")
    pvpairs(1) = [];
end
nargs = numel(args);

if nargs < 1
    error(message('MATLAB:narginchk:notEnoughInputs'));
end

if nargs==1    % Define x,y
    z = args{1};
    [m,n] = size(z);
    [x,y] = meshgrid(1:n,1:m);
elseif nargs==2
    z = args{1};
    s = args{2};
    [m,n] = size(z);
    [x,y] = meshgrid(1:n,1:m);
elseif nargs>=3
    [x, y, z] = deal(args{1:3});
end
if nargs>=4
    s = args{4};
end
if nargs==5
    k = args{5};
end

if ischar(z) || ischar(x)
    error(message('MATLAB:surfl:InvalidNumberInputs'))
end

if nargs<5 % Define default weighting coefficients
    k = [.55,.6,.4,10]; % Ambient,diffuse,specular,spread
end
if length(k)~=4
    error(message('MATLAB:surfl:InvalidNumberComponents'));
end

[msg,x,y,z] = xyzchk(x,y,z); if ~isempty(msg), error(msg); end
if any(size(z)<[3 3])
    error(message('MATLAB:surfl:InvalidInput'));
end

cax = newplot(cax);

if ~strcmp(cax.NextPlot,'add')
    % Set graphics system for 3-D plot. Even though this is also done by
    % surf, it needs to be done here to get the correct view before
    % calculating the light position.
    view(cax, 3);
end

[vaz,vel] = view(cax);
vaz = vaz*pi/180; vel = vel*pi/180; % Convert to radians

if (nargs==1) || (nargs==3) % Use default S
    phi = 45*pi/180;
    s = zeros(1,3);
    s(1) = cos(vaz)*sin(phi)+sin(vaz)*cos(vel)*cos(phi);
    s(2) = sin(phi)*sin(vaz)-cos(vaz)*cos(vel)*cos(phi);
    s(3) = sin(phi)*sin(vel);
else
    if (length(s)~=2) && (length(s)~=3)
        error(message('MATLAB:surfl:MustSpecifyS'));
    end
end

ms = length(s(:));
if ms==2 % Compute source direction from [AZ,EL]
    az = s(1)*pi/180; el = s(2)*pi/180; % Convert to radians
    s = zeros(1,3);
    s(1) =  sin(az)*cos(el);
    s(2) = -cos(az)*cos(el);
    s(3) =  sin(el);
end

if useLight
    h = surf(cax,x,y,z,'AmbientStrength',k(1),'DiffuseStrength',k(2), ...
        'SpecularStrength',k(3),'SpecularExponent',k(4),pvpairs{:});
    hl = light('position',s,'Color',[1 1 1],'Style','infinite','parent',cax);
else
    % Determine plot scaling factors for a cube-like plot domain.
    h = surf(cax,x,y,z,pvpairs{:});
    a = [get(cax,'xlim') get(cax,'ylim') get(cax,'zlim')];
    Sx = a(2)-a(1);
    Sy = a(4)-a(3);
    Sz = a(6)-a(5);
    scale = max([Sx,Sy,Sz]);
    Sx = Sx/scale; Sy = Sy/scale; Sz = Sz/scale;

    % Compute surface normals.  Rely on ordering to define inside or outside.
    xx = x/Sx; yy = y/Sy; zz = z/Sz;
    [nx,ny,nz] = surfnorm(xx,yy,zz);

    % Compute Lambertian shading + specular + ambient light
    R = (k(1)+k(2)*diffuse(nx,ny,nz,s)+ ...
        k(3)*specular(nx,ny,nz,s,[vaz,vel]*180/pi,k(4)))/ sum(k(1:3));

    % Set reflectance of the surface
    if ~isempty(h) && h.CDataMode == "auto"
        h.CData = R;
    end
    clim(cax,[0,1]);
    hl = [];
end

if nargout > 0
    hout = [h hl];
end
end
