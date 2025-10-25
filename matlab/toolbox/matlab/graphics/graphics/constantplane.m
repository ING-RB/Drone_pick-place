function constPlanes = constantplane(varargin)
    %

    %   Copyright 2024 The MathWorks, Inc.

    narginchk(2,inf);

    [parentAxes, args] = matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent(varargin);
    [posargs, pvpairs] = matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV(args, 2, false);

    % Extract the normals and offsets from the positional arguments
    [normals, offsets] = extractNormalsAndOffsets(posargs);

    % NormalVector must be a numeric Nx3 or 3xN matrix
    % Offset must be a Nx1 or 1xN vector
    szNormals = size(normals);
    if ~ismatrix(normals) || ~any(szNormals == 3) || ~isnumeric(normals)
        error("MATLAB:graphics:constantplane:InvalidNormalVectorSyntax", ...
            getString(message("MATLAB:graphics:constantline:InvalidNormalVectorSyntax")))
    end
    if ~isvector(offsets) || ~isnumeric(offsets)
        error("MATLAB:graphics:constantplane:InvalidOffsetSyntax", ...
            getString(message("MATLAB:graphics:constantline:InvalidOffsetSyntax")))
    end

    % Ensure that each NormalVector is specified as a row-vector
    if width(normals) ~= 3
        normals = normals';
    end

    Nos = numel(offsets);
    Nnv = height(normals);

    % Implicitly expand NormalVector and Offset to match other's length if
    % they are a vector or scalar, respectively
    if Nos ~= Nnv && Nos ~= 1 && Nnv ~= 1
        error("MATLAB:graphics:constantplane:IncompatibleNormalVectorOffset", ...
            getString(message("MATLAB:graphics:constantline:IncompatibleNormalVectorOffset")))
    elseif Nos == 1 && Nnv ~= 1
        offsets = repmat(offsets, Nnv);
    elseif Nos ~= 1 && Nnv == 1
        normals = repmat(normals, Nos, 1);
    end

    [parentAxes, hasParent] = matlab.graphics.chart.internal.inputparsingutils.getParent(parentAxes, pvpairs, 2);
    % Now that the data is validated, create an axes if necessary
    if ~hasParent
        parentAxes = gca;
    end

    % ConstantPlane only supports CartesianAxes as a parent
    if isscalar(parentAxes) && ~isa(parentAxes, "matlab.graphics.axis.Axes")
        error("MATLAB:graphics:constantplane:InvalidParent", ...
            getString(message("MATLAB:graphics:constantline:InvalidParent")))
    end

    if isscalar(parentAxes)
        % Try to switch the rulers to numeric
        matlab.graphics.internal.configureAxes(parentAxes, 1, 1, 1);
        if ~isa([parentAxes.ActiveXRuler parentAxes.ActiveYRuler parentAxes.ActiveZRuler], ...
                "matlab.graphics.axis.decorator.NumericRuler")
            error("MATLAB:graphics:constantplane:IncompatibleRulers", ...
                getString(message("MATLAB:graphics:constantline:IncompatibleRulers")))
        end

        % If the Axes are empty and none of the view/camera properties have
        % been changed, then set the view to 3D
        viewModes = ["View" "CameraPosition" "CameraViewAngle" "CameraTarget" "CameraUpVector"] + "Mode";
        if all(get(parentAxes, cellstr(viewModes)) == "auto") 
            parentAxes.View_I = [-37.5 30];
        end
    end

    obj = gobjects(height(normals), 1);
    for i = 1:height(normals)
        obj(i) = matlab.graphics.chart.decoration.ConstantPlane( ...
            'Parent', parentAxes, ...
            'NormalVector', normals(i,:), ...
            'Offset', offsets(i), ...
            pvpairs{:});
    end

    if nargout > 0
        if isempty(obj)
            constPlanes = matlab.graphics.chart.decoration.ConstantPlane.empty(size(obj));
        else
            constPlanes = obj;
        end
    end
end

function [normals, offsets] = extractNormalsAndOffsets(posargs)
    normals = posargs{1};
    offsets = posargs{2};
    % If it is not a scalar or vector of strings do not process
    if ~(isstring(normals) || ischar(normals) || iscellstr(normals)) || ~isvector(normals)
        return
    end
    % If the normal is specified by strings, convert to corresponding
    % axis vectors
    normalStrings = lower(string(normals));
    normals = zeros(numel(normalStrings), 3);
    for i = 1:numel(normalStrings)
        switch normalStrings(i)
            case "x"
                normals(i,:) = [1 0 0];
            case "y"
                normals(i,:) = [0 1 0];
            case "z"
                normals(i,:) = [0 0 1];
            otherwise
                % Return unprocessed string and error
                normals = normalStrings;
                return
        end
    end
end