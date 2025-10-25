function ax = plotTransforms(varargin)
%plotTransforms Plot 3D transforms described by translations and rotations
%   AX = PLOTTRANSFORMS(TRANSLATIONS, ROTATIONS) draws transform frames
%   according to the given TRANSLATIONS and ROTATIONS relative to the
%   inertial frame. The z-axis of the plot always points upward
%   regardless the Z direction of the inertial frame. TRANSLATIONS is
%   an Nx3 matrix representing xyz-position of the transform relative
%   to the inertial frame. ROTATIONS is an Nx1 quaternion vector or Nx4
%   numeric matrix, an N-element SO2 array, or an N-element SO3 array.
%   ROTATIONS represents the rotations that transforms points
%   from the transform frame to the inertial frame.
%
%   AX = plotTransforms(T) draws a transform frame for the SE2 or SE3 object, T.
%   The corresponding translation and rotation will be extracted from T.
%   T can be an object array of arbitrary size to draw multiple frames.
%
%   AX = PLOTTRANSFORMS(___, Name, Value) provides additional options
%   specified by Name-Value pair arguments. Available argument names:
%
%      'FrameSize'            - Positive numeric that determines the
%                               size of the plotted transform frame and
%                               the mesh attached to the transform.
%
%      'FrameColor'           - Color of the plotted frame. When specified
%                               as a string or RGB triplet, the frame will be
%                               of uniform color. When specifying "rgb", the
%                               frame will be colored in red (x), green (y), and
%                               blue (z).
%                               Default: "rgb"
%
%      'FrameAxisLabels'      - Add x,y,z labels to the axes of the coordinate frame.
%                               Valid options are "on" and "off".
%                               Default: "off".
%
%      'FrameLabel'           - Add a label for the coordinate frame. This label will also be
%                               Added as subscript to the frame axis labels. This can be a single
%                               string (applied to all frames) or a string array of length N
%                               (one string per frame).
%                               Default: "".
%
%      'AxisLabels'           - Add X,Y,Z labels to the plotting axes.
%                               Valid options are "on" and "off".
%                               Default: "off".
%
%      'InertialZDirection'    - A string that indicates whether the
%                               z-axis of the inertial frame points
%                               upward or downward. Must be either
%                               "up" or "down". The default value is
%                               "up"
%
%      'MeshColor'            - Either a string or an RGB triplet that
%                               describes the color of the plotted
%                               mesh. Default is [1 0 0] or "red".
%
%      'MeshFilePath'         - File path to the mesh file to be
%                               attached to the transform frames. The
%                               file path can be absolute path,
%                               relative path or on the MATLAB path.
%
%      'View'                 - A string or 3-element vector indicating the
%                               desired plot view. Valid options are "2D",
%                               "3D", or the 3-element vector [x y z] that
%                               sets the view angle in Cartesian
%                               coordinates. The magnitude of vector Z, Y,
%                               Z is ignored. The default value is "3D".
%
%      'Parent'               - A handle to an axis upon which this
%                               plot would be drawn.
%   Example:
%      % plot three multirotor UAV with different poses
%      plotTransforms(eye(3), [eye(3), zeros(3,1)], MeshFilePath="multirotor.stl")
%      light
%
%      % plot three fixed-wing UAV with different poses
%      plotTransforms(eye(3), [eye(3), zeros(3,1)], MeshFilePath="fixedwing.stl")
%      light
%
%      % plot three mobile robots with different poses
%      plotTransforms(eye(3), [eye(3), zeros(3,1)], MeshFilePath="groundvehicle.stl")
%      light
%
%      % plot se3 transformations
%      plotTransforms([se3 se3(eul2rotm([pi/4 0 0]), [2 1 0])], ...
%         FrameColor="r", AxisLabels="on")
%
%      % plot so3 rotations with frame labels
%      plotTransforms([1 0 0; 2 1 0], [so3, so3(eul2rotm([pi/3 0.1 0]))], ...
%          FrameLabel=["1", "2"], FrameAxisLabels="on")
%
%   See also: SE3, SO3, quaternion.

%   Copyright 2018-2024 The MathWorks, Inc.

    narginchk(1, 20);

    arg1 = varargin{1};
    if isa(arg1, "se3")
        % Syntax: plotTransforms(T)
        % Extract 3D translations and rotations
        translations = trvec(arg1);
        rotations = quaternion(rotm(arg1), "rotmat", "point");

        nvResults = validateNameValuePairs(varargin{2:end});

        % Always enable grid and equal axes for SE inputs
        setupPerspective = true;
        is2D = false;

    elseif isa (arg1, "se2")
        % Syntax: plotTransforms(T)
        % Extract 2D translations and rotations and change to 3D
        rotations = so2ToQuatCol(arg1);
        translations = trvec(arg1);
        translations = [translations zeros(size(translations,1),1,"like",translations)];

        nvResults = validateNameValuePairs(varargin{2:end});

        % Always enable grid and equal axes for SE inputs
        setupPerspective = true;
        is2D = true;

    else
        % Syntax: plotTransforms(TRANSLATIONS, ROTATIONS)

        translations = varargin{1};
        rotations = varargin{2};

        % validate rotations
        [rotations, is2D] = validateRotations(rotations);

        % validate translations. Allow 2D translations for SO2 inputs.
        translations = validateTranslations(translations, is2D);

        if (size(translations, 1)~=size(rotations, 1))
            error(message('shared_robotics:robotcore:plotTransforms:MismatchTranslationRotation'));
        end

        nvResults = validateNameValuePairs(varargin{3:end});

        if isa(varargin{2}, "matlabshared.spatialmath.internal.SOBase")
            setupPerspective = true;
        else
            setupPerspective = false;
        end
    end

    % validate mesh file path if it is not empty
    if ~isempty(nvResults.MeshFilePath)
        meshPath = robotics.internal.validation.findFilePath(convertStringsToChars(nvResults.MeshFilePath), 'plotTransforms', 'MeshFilePath');
    else
        meshPath = '';
    end

    % validate inertial z direction
    inertialZDirection = validatestring(nvResults.InertialZDirection, {'up', 'down'}, 'plotTransforms', 'InertialZDirection');

    % validate axes labels
    axisLabels = char(validatestring(nvResults.AxisLabels, {'on', 'off'}, 'plotTransforms', 'AxisLabels'));
    frameAxisLabels = char(validatestring(nvResults.FrameAxisLabels, {'on', 'off'}, 'plotTransforms', 'FrameAxisLabels'));
    frameLabel = cellstr(nvResults.FrameLabel);
    if isscalar(frameLabel) && size(rotations, 1) > 1
        % Use the same label for all frames
        frameLabel = repmat(frameLabel,1,size(rotations, 1));
    end
    frameColor = nvResults.FrameColor;

    % prepare ax for plotting
    if isempty(nvResults.Parent)
        parentAx = newplot;
    else
        parentAx = nvResults.Parent;
    end

    % Only change axis/light settings if hold is "off" for the given axes
    setupPerspective = setupPerspective && ~ishold(parentAx);

    % prepare transform painter
    painter = robotics.core.internal.visualization.TransformPainter(parentAx, meshPath, setupPerspective);
    painter.Color = nvResults.MeshColor;
    painter.Size = nvResults.FrameSize;
    painter.InertialZDownward = strcmp(inertialZDirection, 'down');
    painter.enableAxisLabels(axisLabels);

    % paint transform at given translations and orientations
    for i = 1:size(translations, 1)
        hMeshTransform = painter.paintAt(translations(i, :), rotations(i), is2D);
        painter.labelAndColorFrame(hMeshTransform, frameAxisLabels, frameLabel{i}, frameColor, is2D);
    end

    % optionally output the plot ax
    if nargout == 1
        ax = parentAx;
    end

    % Optionally change the view if the user has provided that input
    if ~isempty(nvResults.View)
        viewAzEl = validateViewInput(nvResults.View);
        view(parentAx, viewAzEl(1), viewAzEl(2));
    elseif is2D
        % If we are dealing with 2D transformations, always show X-Y view
        view(0,90);
    end
end

function selectedView = validateViewInput(inputViewValue)
%validateViewInput Validate the input the "View" Name/Value pair
%   The earlier check verifies that the user-specified input is nonempty,
%   but the default value (no input provided) is empty. This function
%   converts the input options to a 2-element vector [AZ EL] containing the
%   azimuth and elevation angles that are passed to the view command
%   downstream.

    if isnumeric(inputViewValue) && ~isempty(inputViewValue)
        % If the input is numeric, extract azimuth and elevation angles
        validateattributes(inputViewValue, {'numeric'}, {'vector', 'numel', 2, 'finite'}, 'plotTransforms', 'View');
        selectedView = inputViewValue;
    else
        % If the input is a string, it should specify 2D or 3D. Convert
        % these two azimuth and elevation angles
        viewStr = validatestring(inputViewValue, {'2D', '3D'}, 'plotTransforms', 'View');
        if strcmp(viewStr, '2D')
            [az, el] = view(2);
        else
            [az, el] = view(3);
        end
        selectedView = [az el];
    end

end

function [rotQCol, is2D] = validateRotations(rotations)
%validateRotations Validate the ROTATIONS input to the function
%   This could either be an so2, so3, quaternion, or numeric matrix.
%   Return in ROTQCOL a quaternion column vector that will be used in the
%   rest of the function.

% validate rotations
    if isa(rotations, "so3")
        % ROTATIONS is an SO object
        % Extract quaternion rotations
        rotQCol = quaternion(rotm(rotations), "rotmat", "point");
        is2D = false;
    elseif isa(rotations, "so2")
        % Extract 2D rotation and change to 3D
        rotQCol = so2ToQuatCol(rotations);
        is2D = true;
    else
        % ROTATIONS is a quaternion
        % validate rotation using internal quaternion validation utility
        robotics.internal.validation.validateQuaternion(rotations, 'plotTransforms', 'rotations');

        if (isa(rotations, 'quaternion') && size(rotations, 2) ~= 1)
            error(message('shared_robotics:robotcore:plotTransforms:RotationMustBeColumn'));
        end

        % convert orientations to quaternions if necessary
        if ~isa(rotations, 'quaternion')
            rotQCol = quaternion(rotations);
        else
            rotQCol = rotations;
        end

        is2D = false;
    end

end

function trvec = validateTranslations(translations, is2D)
%validateTranslations Validate 2D and 3D translation inputs

    if is2D
        % validate translations. Allow 2D translations for SO2 inputs.
        validateattributes(translations, {'numeric'}, {'2d', 'ncols', 2, 'nonempty'}, 'plotTransforms', 'translations');

        % add zero for z
        trvec = [translations zeros(size(translations,1),1,"like",translations)];
    else
        validateattributes(translations, {'numeric'}, {'2d', 'ncols', 3, 'nonempty'}, 'plotTransforms', 'translations');
        trvec = translations;
    end



end


function nvResults = validateNameValuePairs(varargin)
%validateNameValuePairs Validate the name-value pairs passed to the function

% setup input parser
    p = inputParser;

    % optional inputs
    addParameter(p, 'FrameSize', 1, ...
                 @(x)validateattributes(x, {'numeric'}, {'scalar','positive'}, 'plotTransforms', 'FrameSize'));
    addParameter(p, 'Parent', [], ...
                 @(x)validateattributes(x, {'matlab.graphics.axis.Axes'}, {'nonempty', 'scalar'}, 'plotTransforms', 'Parent'));

    % postpone full validation for view, string, file path, and mesh color
    addParameter(p, 'View', [], @(x)validateattributes(x, {'string', 'char', 'numeric'}, {'nonempty'}, 'plotTransforms', 'View'));
    addParameter(p, 'MeshFilePath', '', @(x)validateattributes(x, {'string', 'char'}, {'scalartext'}, 'plotTransforms', 'MeshFilePath'));
    addParameter(p, 'InertialZDirection', 'up', @(x)validateattributes(x, {'string', 'char'}, {'scalartext'}, 'plotTransforms', 'InertialZDirection'));
    addParameter(p, 'MeshColor', [1 0 0]);
    addParameter(p, 'FrameColor', 'rgb');
    addParameter(p, 'FrameLabel', '', @(x)validateattributes(x, {'string', 'char','cell'}, {}, 'plotTransforms', 'FrameLabel'));
    addParameter(p, 'FrameAxisLabels', 'off', @(x)validateattributes(x, {'string', 'char'}, {'scalartext'}, 'plotTransforms', 'FrameAxisLabels'));
    addParameter(p, 'AxisLabels', 'off', @(x)validateattributes(x, {'string', 'char'}, {'scalartext'}, 'plotTransforms', 'AxisLabels'));

    % parse inputs and return results
    parse(p, varargin{:})
    nvResults = p.Results;
end

function qCol = so2ToQuatCol(so2Obj)
%so2ToQuatCol Convert SO2 object to quaternion column

    n = numel(so2Obj);
    t = underlyingType(so2Obj);
    R = repmat(eye(3,t),1,1,n);
    R(1:2,1:2,:) = rotm(so2Obj);
    qCol = quaternion(R, "rotmat", "point");

end
