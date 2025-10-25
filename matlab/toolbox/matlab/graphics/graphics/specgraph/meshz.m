function h=meshz(arg1, arg2, arg3, arg4, arg5, propArgs)
%

%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    arg1 = [];
    arg2 = [];
    arg3 = [];
    arg4 = [];
    arg5 = [];
    propArgs.?matlab.graphics.chart.primitive.Surface
end
propCell = namedargs2cell(propArgs);

args = {arg1, arg2, arg3, arg4, arg5};
[~, cax, args] = parseplotapi(args{1:nargin}, '-mfilename', mfilename);

if isfield(propArgs,'Parent') % Always honor the 'Parent' PVPair value
    cax = propArgs.Parent;
end

nargs = length(args);

if nargs < 1
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif nargs > 4
    error(message('MATLAB:narginchk:tooManyInputs'));
end

if nargs==1  % Generate x,y matrices for surface z.
  x = args{1};
  if min(size(x)) == 1 || ischar(x) || isstring(x)
      error(message('MATLAB:meshz:InvalidInput'))
  end
  z = args{1};
  z = matlab.graphics.chart.internal.datachk(z,'numeric');
  [m,n] = size(z);
  [x,y] = meshgrid(0:n-1,0:m-1);
  c = z;

elseif nargs==2
  x = args{1};  y = args{2};
  if ischar(x) || isstring(x) || ischar(y) || isstring(y)
    error(message('MATLAB:meshz:InvalidInput'))
  end
  if min(size(x)) == 1 || min(size(y)) == 1
      error(message('MATLAB:meshz:InvalidInput'))
  end
  z = x; c = y;
  z = matlab.graphics.chart.internal.datachk(z,'numeric');
  c = matlab.graphics.chart.internal.datachk(c,'numeric');
  [m,n] = size(z);
  [x,y] = meshgrid(0:n-1,0:m-1);
  if ~isequal(size(c),size(z))
      error(message('MATLAB:meshz:InvalidInput'))
  end

elseif nargs>=3
  [x,y,z] = deal(args{1:3});
  if ischar(x) || isstring(x) || ischar(y) || isstring(y) || ischar(z) || isstring(z) 
      error(message('MATLAB:meshz:InvalidInput'))
  end
  x = matlab.graphics.chart.internal.datachk(x,'numeric');
  y = matlab.graphics.chart.internal.datachk(y,'numeric');
  z = matlab.graphics.chart.internal.datachk(z,'numeric');
  [m,n] = size(z);
  [mx,nx] = size(x);
  [my,ny] = size(y);
  if m == 1 || n == 1
      error(message('MATLAB:meshz:InvalidInput'))
  end

  if min(mx,nx)==1 && max(mx,nx)==n
      %we have a vector of the right size
      x=x(:)';  %make sure we have a row vector
      x=x(ones(m,1),:);
  elseif ~isequal(size(x),size(z))
      xmin = min(min(x));
      xmax = max(max(x));
      
      x=xmin:(xmax-xmin)/(n-1):xmax;
      x=x(ones(m,1),:);
  end
  
  
  if min([my,ny])==1 && max([my,ny])==m
      %we have a vector of the right size: matrixize it
      y=y(:); %make sure we have a column vector
      y = y(:,ones(1, n));
      
  elseif ~isequal(size(y),size(z))
      % Create x and y vectors that are the same size as z.
      ymin = min(min(y));
      ymax = max(max(y));
      
      y = (ymin:(ymax-ymin)/(n-1):ymax)';
      y = y(:,ones(1, n));
      
      
  end
  
  if nargs > 3
      c = args{4};
  else
      c = z;
  end
  
  if ~isequal(size(c),size(z))
      error(message('MATLAB:meshz:InvalidInput'))
  end
  if ~isequal(size(z),size(x)) || ~isequal(size(z),size(y))
      error(message('MATLAB:meshz:InvalidInput'))
  end
end

if ischar(c) || isstring(c)
      error(message('MATLAB:meshz:InvalidInput'))
end

% Define position of curtains
zref = min(min(z(isfinite(z))));

% Define new x,y,z and then call mesh.
zrow = zref*ones(1,n); zcol = zref*ones(m,1);
d = [1 1]; mm = [m m]; nn = [n n];
newZ = [zref zref   zrow   zref   zref;
        zref zref   z(1,:) zref   zref;
        zcol z(:,1) z      z(:,n) zcol;
        zref zref   z(m,:) zref   zref;
        zref zref   zrow   zref   zref];
        
newX = [x(d,d),x(d,:),x(d,nn);x(:,d),x,x(:,nn);x(mm,d),x(mm,:),x(mm,nn)];
newY = [y(d,d),y(d,:),y(d,nn);y(:,d),y,y(:,nn);y(mm,d),y(mm,:),y(mm,nn)];

cref = (max(max(c(isfinite(c))))+min(min(c(isfinite(c)))))/2;
crow = cref*ones(2,n); ccol = cref*ones(m,2); cref = cref*ones(2,2);
c = [cref,crow,cref;ccol,c,ccol;cref,crow,cref];

if isempty(cax)
    cax = gca;
end
try
    hm=mesh(cax,newX,newY,newZ,c, propCell{:});
    set(hm,'Tag','meshz');
catch e
    throw(e);
end

if nargout > 0
    h = hm;
end
end

