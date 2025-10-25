function hDataTip = datatip(hTarget,varargin)
% DATATIP  Creates a data tip
%
%    DATATIP (target) displays a data tip on the first plotted data point of
%    the specified target object. You can create data tips on objects with a DataTipTemplate 
%    property, for example line and scatter objects.
%
%    DATATIP (target,x,y) displays a data tip on the 2-D plotted data point
%    specified by x and y.
%
%    DATATIP (target,x,y,z) displays a data tip on the 3-D plotted data point
%    specified by x, y, and z.
%
%    DATATIP (target,'DataIndex',n) displays a data tip at the nth index in
%    the plotted data set.
%
%    DATATIP (___,Name,Value) specifies data tip properties using one
%    or more name-value pair arguments. Specify name-value pairs after all
%    other input arguments.
%
%    dt = DATATIP (___) returns a DataTip object. This syntax is useful for
%    controlling the properties of the data tip.
%
%   Example 1: Display a data tip at the first plotted data point
%
%      p = plot(1:10);
%      dt = datatip(p);
%
%   Example 2: Display a data tip at a specified data point
%      x = 1:10;
%      y = x.^2;
%      sc = scatter(x,y);
%      dt = datatip(sc,4,16);
%
%   Example 3: Display a data tip on the third plotted data point
%      x = 1:10;
%      y = x.^2;
%      sc = scatter(x,y);
%      dt = datatip(sc,'DataIndex',3);
%

% Copyright 2019-2022 The MathWorks, Inc.

% Make sure the inputs are valid. If no arguments are passed, error.
% d = datatip()
narginchk(1,inf);

% Below logic validates first argument to the datatip function.
% Make sure the first argument is a valid charting object that
% supports a data tip or is a datatip object. If the first argument
% is a datatip object -> its brought to front.
% Syntax: datatip(plot(1:10))

% Example of invalid syntax: datatip([]) or datatip({gcf})
if ~matlab.graphics.datatip.DataTip.isValidParent(hTarget)
    if isa(hTarget, 'matlab.graphics.datatip.DataTip')
        % Syntax: datatip(hDataTip) -> if user calls datatip function passing
        % datatip object then bring it to front.
        % User should not specify any pvpairs when passing DataTip object,
        % therefore, error in that case.
        if nargin > 1
            error(message('MATLAB:graphics:datatip:IncorrectInputArgs'));
        end
        hDataTip = hTarget;
        % Bring the current data tip to front
        hDataTip.bringToFront();
        % Return early since we don't want to perform any other
        % validations.
        return;
    elseif ~isempty(hTarget) && ...
            length(hTarget) == 1 && ...
            ~isnumeric(hTarget) && ...
            ~isgraphics(hTarget)
        % Error out appropriately when first argument is not a valid
        % graphics object
        error(message('MATLAB:graphics:datatip:InvalidFirstArgument'));
    else
        error(message('MATLAB:graphics:datatip:InvalidParent'));
    end
end

% Construct DataTip object so that we can perform pvpair validation to
% check if the pvpair is a valid property name for the DataTip object
hDataTip = matlab.graphics.datatip.DataTip(hTarget);

% Get the object's dimension names to form properties (pvpairs) as needed.
% For object in a cartesian axes - 'X','Y','Z'
% For object in a polar axes - 'Theta','R','Z'
% For object in a geo axes - 'Latitude','Longitude','Z'
objDimensionNames = hTarget.DimensionNames;

% Find the axes ancestor for the datatip. This is needed for cases when a user can specify
% a string value for the x-coordinate e.g. datatip(h,'oranges',4).
ax = ancestor(hTarget,'matlab.graphics.axis.AbstractAxes');

% For even number of arguments (where charting object is the first
% specified parameter), check if the user has specified x,y coordinates for
% a 2D object or x,y,z coordinates for a 3D object. Example,
% datatip(plot(1:10),2,3) or datatip(surf(peaks),2,3,4)
if nargin > 1
    % This is needed to find out if the second argument (which is a string/char)
    % is actually x/y/z coordinates and not pvpairs e.g. datatip(h,'oranges',4)
    firstAxisPropName = [objDimensionNames{1} 'Axis'];
    iscategoricalXRuler = ~isempty(ax) && isprop(ax,firstAxisPropName) ...
        && isa(ax.(firstAxisPropName),'matlab.graphics.axis.decorator.CategoricalRuler');
    arg1 = varargin{1};
    % Validate if the argument after hTarget is a valid property name.
    % Example: b = bar(categorical([1,2,3]),rand(1,3)); datatip(b,'DataIndex',2);
    % Here, arg1 which is 'DataIndex' is a valid property name for DataTip
    % object.
    isPropertyArg = (ischar(arg1) || isstring(arg1)) && isprop(hDataTip,arg1);
    % Validate if the parameter passed are coordinates and not pvpairs
    if (iscategoricalXRuler && ~isPropertyArg && (ischar(arg1) || isstring(arg1) || iscategorical(arg1))) || ...
            (~ischar(arg1) && ~isstring(arg1))
        % For a 3D charting object, ensure that user specified all 3 x,y,z,
        % coordinates; e.g. datatip(surf(peaks),2,3) -> error in this case.
        % Another invalid case, e.g. datatip(surf(peaks),2,3,2,2)
        if ~isempty(ax) && ~is2D(ax)
            if numel(varargin) < 3 || ...
                    (numel(varargin) > 3 && ~ischar(varargin{4}) && ~isstring(varargin{4}))
                error(message('MATLAB:graphics:datatip:Invalid3DCoordinates'));
            end
            % Add pvpair to use the arguments as coordinates X and Y and update
            % the args with the new pvpair
            % Example of what below logic does: varargin = ['X',2'Y',3','Z',4];
            varargin = [{objDimensionNames{1},varargin{1},...
                objDimensionNames{2},varargin{2},...
                objDimensionNames{3},varargin{3}} varargin(4:end)];
        else
            % For a 2D charting object, ensure that user specified both x and y,
            % coordinates; e.g. datatip(plot(1:10),2) -> error in this
            % case. Another invalid case, e.g. datatip(plot(1:10),2,2,2)
            if numel(varargin) < 2 || ...
                    (numel(varargin) > 2 && ~ischar(varargin{3}) && ~isstring(varargin{3}))
                error(message('MATLAB:graphics:datatip:Invalid2DCoordinates'));
            end
            % Add pvpair to use the arguments as coordinates X and Y and update
            % the args with the new pvpair
            % Example of what below logic does: varargin = ['X',2,'Y',3];
            varargin = [{objDimensionNames{1},varargin{1},objDimensionNames{2},varargin{2}} varargin(3:end)];
        end
    end
end

% Converts a cell array containing strings values, or a string
% array, to a cell array of character vectors. To convert a scalar string to a
% character vector use the char function. This function is necessary
% because various functions (like set, get, etc.) do not currently
% accept strings.
pvPairs = matlab.graphics.internal.convertStringToCharArgs(varargin);
numOf3DCoord = 0;

% Validate pvpairs which define property/value pairs to the datatip
% function
% Example: datatip(plot(1:10),'DataIndex',1,'Location','southeast')
% pvPairs must be an even number of string,value pairs.
% check that every p is a property
numPvPairs = length(pvPairs);
try
    for index=1:2:numPvPairs
        if ~ischar(pvPairs{index})
            error(message('MATLAB:graphics:datatip:InvalidPropertyName'));
        elseif ~isprop(hDataTip,pvPairs{index})
            error(message('MATLAB:graphics:datatip:UnknownProperty',pvPairs{index}));
        elseif strcmpi(pvPairs{index},'Parent') && ~matlab.graphics.datatip.DataTip.isValidParent(pvPairs{index+1})
            error(message('MATLAB:graphics:datatip:IncorrectParent'));
        end
        
        % This check is done to ensure that for a 3D object user specifies
        % atleast 2 of the coordinates X,Y,Z.
        if any(strcmpi(pvPairs{index},objDimensionNames))
            objDimensionNames = setdiff(objDimensionNames,pvPairs{index});
            numOf3DCoord = numOf3DCoord + 1;
        end
    end
    
    % Error if user specified just one coordinate for a 2D chart object.
    % Example: datatip(plot(1:10),'X',2);
    if ~isempty(ax)
        if ~is2D(ax) && (numOf3DCoord > 0 && (numOf3DCoord < 3 || numOf3DCoord > 3))
            error(message('MATLAB:graphics:datatip:Invalid3DCoordinates'));
        elseif is2D(ax) && (numOf3DCoord > 0 && (numOf3DCoord < 2 || numOf3DCoord > 2))
            error(message('MATLAB:graphics:datatip:Invalid2DCoordinates'));
        end
    end
    if ~isempty(pvPairs)
        set(hDataTip, pvPairs{:});
    end
catch ex
    delete(hDataTip);
    rethrow(ex);
end