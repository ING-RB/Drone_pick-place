function [ax, patchObjArray] = showCollisionArray(collisionMeshArray,varargin)
%

%   Copyright 2023-2024 The MathWorks, Inc.

narginchk(1, 5);

    robotics.internal.validation.validateCollisionGeometryArray(collisionMeshArray,'showCollisionArray','collisionMeshArray');

    ax = [];
    colorOrder = [];

    if nargin > 1
        % Convert strings to chars case by case
        charInputs = cell(1,nargin-1);
        [charInputs{:}] = convertStringsToChars(varargin{:});

        % Parse optional inputs
        names = {'Parent', 'ColorOrder'};
        defaults = {[], []};
        parser = robotics.core.internal.NameValueParser(names, defaults);
        parse(parser, charInputs{:});
        ax = parameterValue(parser, names{1});
        colorOrder = parameterValue(parser, names{2});

        % Validate optional inputs
        if ~isempty(ax)
            robotics.internal.validation.validateAxesUIAxesHandle(ax);
        end
        if ~isempty(colorOrder)
            validateattributes(colorOrder, {'numeric'}, {'2d', 'ncols', 3, 'nonnan', 'finite', 'nonnegative'}, 'colorOrder', 'showCollisionArray');
        end
    end

    if isempty(ax)
        ax = newplot();
    end

    if isempty(colorOrder)
        colorOrder = ax.ColorOrder;
    end

    % Plot the meshes and update the view
    outputPatches = plotMeshes(collisionMeshArray, ax, colorOrder);
    patchObjArray = outputPatches(:);
    updateViewToFitContents(ax);
    addLighting(ax);

end

function outputPatches = plotMeshes(collisionMeshArray, ax, colorOrder)
%plotMeshes Plot collision meshes in the axes AX using the specified color order

% Get the current hold status
    tf = ishold(ax);

    outputPatches = [];
    for i = 1:numel(collisionMeshArray)
        localMesh = collisionMeshArray{i};
        [~,resultPatch] = show(localMesh,Parent=ax);

        colorIdx = mod(i-1, size(colorOrder,1))+1;
        resultPatch.FaceColor = colorOrder(colorIdx,:);

        if isempty(outputPatches)
            outputPatches = resultPatch;
        else
            outputPatches(i) = resultPatch; %#ok<AGROW>
        end

        if i == 1
            hold(ax,"on");
        end
    end

    % Reapply original hold status if it changed
    if ~tf
        hold(ax, "off");
    end

end

function updateViewToFitContents(ax)
%updateViewToFitContents Update the axes view to fit the contents

    axis(ax, "auto");
    view(ax, [135 8]);
end

function addLighting(ax)
%addLighting Add lighting so the meshes can be viewed

    xLimits = xlim; zLimits = zlim;
    light('Position',[xLimits(2), 0, zLimits(2)],'Style','local','parent',ax);
end
