function varargout = view(varargin)
%VIEW   3-D graph viewpoint specification.
%   VIEW(AZ,EL) and VIEW([AZ,EL]) set the angle of the view from which an
%   observer sees the current 3-D plot.  AZ is the azimuth or horizontal
%   rotation and EL is the vertical elevation (both in degrees). Azimuth
%   revolves about the z-axis, with positive values indicating counter-
%   clockwise rotation of the viewpoint. Positive values of elevation
%   correspond to moving above the object; negative values move below.
%   VIEW([X Y Z]) sets the view angle in Cartesian coordinates. The
%   magnitude of vector X,Y,Z is ignored.
%
%   Here are some examples:
%
%   AZ = -37.5, EL = 30 is the default 3-D view.
%   AZ = 0, EL = 90 is directly overhead and the default 2-D view.
%
%   VIEW(2) sets the default 2-D view, AZ = 0, EL = 90.
%   VIEW(3) sets the default 3-D view, AZ = -37.5, EL = 30.
%
%   [AZ,EL] = VIEW returns the current azimuth and elevation.
%
%   VIEW(AX,...) uses axes AX instead of the current axes.
%
%   See also VIEWMTX.

%   Copyright 1984-2022 The MathWorks, Inc.

narginchk(0,3);
nargoutchk(0, 2);

% Identify the target axes and arguments to ViewCore
viewArgs = {};
switch nargin
    case 0
        % [az,el] = view;
        % viewmtx = view;
        hAxes = gca;
    case { 1, 2 }
        if isAxesHandle(varargin{1})
            % view(target)
            % view(target, v)
            % view(target, dim)
            hAxes = validateAxes(varargin{1});
            viewArgs = varargin(2:end);
        else
            % view(v)
            % view(dim)
            % view(az, el)
            hAxes = gca;
            viewArgs = varargin(1:end);
        end
    case 3
        % view(target, az, el)
        hAxes = validateAxes(varargin{1});
        viewArgs = varargin(2:end);
end

if ~isscalar(hAxes)
    switch nargout
        case 0 
            for i = 1:numel(hAxes)
                view(hAxes(i), viewArgs{:})
            end
            return
        case 1 
            error(message('MATLAB:nargoutchk:notEnoughOutputs'))
        case 2
            varargout{1} = nan(size(hAxes));
            varargout{2} = nan(size(hAxes));
            for i = 1:numel(hAxes)
                [varargout{1}(i), varargout{2}(i)] = view(hAxes(i), viewArgs{:});
            end
            return
        otherwise 
            error(message('MATLAB:nargoutchk:tooManyOutputs'))
    end
end

if isa(hAxes,'matlab.graphics.chart.Chart')
    try
        [varargout{1:nargout}] = hAxes.view(varargin{:});
    catch e
        throw(e)
    end
    return
end

% Set the view
if ~isempty(viewArgs)
    if ~all(cellfun(@isnumeric,viewArgs),'all')
        error(message('MATLAB:view:InvalidInputs'));
    end
    ViewCore(hAxes, viewArgs{:});
end

% Construct the return args, return the azimuth and elevation for 2 lhs args,
% otherwise, return the transformation matrix.
switch nargout
    case {0,1}
        if( nargin == 0 || nargout == 1)
            % If VIEW is called without any input
            % arguments, then it is treated as a query
            % command. In which case always return the
            % view matrix.
            % If one output argument is specified, always
            % return the view matrix.
            assert(isa(hAxes, 'matlab.graphics.axis.Axes'), ...
                message('MATLAB:view:OneOutputNotSupported'))
            varargout{1} = getAxesTransformationMatrix(hAxes);
        end
    case 2
        axView = get(hAxes, 'View');
        varargout{1} = axView(1);
        varargout{2} = axView(2);
end

%
%==============================================================================
% ViewCore - actual code that sets the axes view
%
function ViewCore(hAxes, arg1, arg2)

matlab.graphics.internal.markFigure(hAxes);

azIn     = [];
elIn     = [];

switch (nargin)

  %
  %--------------------------------------------------------
  % 2 arg - cases are:
  %   view(hAxes, 2)
  %   view(hAxes, 3)
  %   view(hAxes, [az, el])
  %   view(hAxes, [x y z])
  %
 case 2
  [r, c] = size(arg1);
  if (r == 1) && (c == 1)
    %
    % view(2) or view(3)
    %
    switch arg1
     case 2
      azIn = 0;
      elIn = 90;
      if hasCameraProperties(handle(hAxes))
          if ~strcmpi(get(hAxes,'CameraUpVectorMode'),'auto')
              if strcmpi(get(hAxes,'YDir'),'normal')
                  set(hAxes,'CameraUpVector',[0 1 0]);
              else
                  set(hAxes,'CameraUpVector',[0 -1 0]);
              end
          end
      end

     case 3
      azIn = -37.5;
      elIn = 30;
      if hasCameraProperties(handle(hAxes)) && ~strcmpi(get(hAxes,'CameraUpVectorMode'),'auto')
          set(hAxes,'CameraUpVector',[0 0 1]);
      end
      
     otherwise
      error(message('MATLAB:view:InvalidScalarArgument'));
    end
  elseif (r == 1) && (c == 2)
    %
    % view([az, el]
    %
    azIn = arg1(1);
    elIn = arg1(2);
  elseif r*c == 3
    %
    % view([x, y, z])
    %
    unit = arg1/norm(arg1);
    azIn = atan2(unit(1),-unit(2))*180/pi;
    elIn = atan2(unit(3),sqrt(unit(1)^2+unit(2)^2))*180/pi;
  else
    error(message('MATLAB:view:InvalidArgument'));
  end

  %
  %--------------------------------------------------------
  % 3 args - cases are
  %   view(hAxes, az, el)
  %
 case 3
  if (length(arg1) == 1) && (length(arg2) == 1)
    azIn = arg1;
    elIn = arg2;
  else
    error(message('MATLAB:view:InvalidArgumentType'))
    
  end

end

% there is one  case at this point:
%  The azimuth and elevation are defined

if ~isempty(azIn) && ~isempty(elIn)
    set(hAxes, 'View', [azIn, elIn]);
end


function ax = validateAxes(ax)
% Validate that ax is a homogenous axes/chart type, throw appropriate
% exception if not.
if all(isgraphics(ax),'all')
    ax = handle(ax);
end

isAxes = @(ax) isa(ax,'matlab.graphics.axis.Axes') || ...
    isa(ax, 'matlab.graphics.axis.PolarAxes') || ...
    isa(ax, 'matlab.graphics.axis.GeographicAxes') || ...
    isa(ax,'map.graphics.axis.MapAxes') || ...
    isa(ax, 'matlab.graphics.chart.Chart');

if ~isAxes(ax) || any(~isvalid(ax),'all')
    if isscalar(ax) || ~any(arrayfun(isAxes,ax))
        % Nothing in ax is one of the "axes" types, maybe view(line,...)
        throwAsCaller(MException(message('MATLAB:view:InvalidFirstArgument')));
    end
    % At least one of the four types, maybe a mix:
    throwAsCaller(MException(message('MATLAB:rulerFunctions:MixedAxesVector')));
end


function yesno = isAxesHandle(ax)
% Check whether ax is a potential target, i.e. an array axes/chart objects,
% but don't throw if it's not.

if all(isgraphics(ax),'all')
    ax = handle(ax);
end
isAxes = @(ax) isa(ax,'matlab.graphics.axis.Axes') || ...
    isa(ax, 'matlab.graphics.axis.PolarAxes') || ...
    isa(ax, 'matlab.graphics.axis.GeographicAxes') || ...
    isa(ax,'map.graphics.axis.MapAxes') || ...
    isa(ax, 'matlab.graphics.chart.Chart');

yesno=all(arrayfun(isAxes, ax), 'all');
