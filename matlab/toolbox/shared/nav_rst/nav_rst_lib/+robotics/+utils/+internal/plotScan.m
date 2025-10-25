function plotHandles = plotScan(metaClassObj, cart, cartAngles, defaults, varargin)
%This function is for internal use only. It may be removed in the future.

%plotScan Plot a laser scan in an existing or new figure

%   Copyright 2017-2019 The MathWorks, Inc.

    args = parsePlotArguments(metaClassObj, defaults, varargin{:});

    isThisANewplot = isempty(get(args.Parent, 'Children'));

    % Display laser scan as a set of points
    plotHandles = plot(args.Parent, cart(:,1), cart(:,2), '.', 'MarkerSize', 8);

    if isThisANewplot
        axis(args.Parent, 'equal');
    end

    % Lower y-Limit is determined by scan angles of laser. If any
    % beams are in quadrants 3 or 4, the plot will be extended
    % there.
    minY = 0;
    if any(abs(cartAngles) > pi/2 + 1e-6)
        minY = -args.MaximumRange;
    end

    % Ensure resizing does not curtail the previous plots
    existingXAxisMax = args.Parent.XLim(2);
    if isThisANewplot || (args.MaximumRange > existingXAxisMax)
        ylim(args.Parent, [-args.MaximumRange args.MaximumRange]);
        xlim(args.Parent, [minY args.MaximumRange]);
    end

    if isThisANewplot
        grid(args.Parent, 'on');
        if contains(lower(metaClassObj.Name), 'laser')
            title(args.Parent, message('shared_robotics:robotcore:laserscan:LaserScan').getString);
        elseif contains(lower(metaClassObj.Name), 'lidar')
            title(args.Parent, message('shared_robotics:robotcore:laserscan:LidarScan').getString);
        end
        % Rotate by 90 degrees counter-clockwise to align with ROS
        % coordinate frame
        view(args.Parent, -90, 90);
        xlabel(args.Parent, 'X');
        ylabel(args.Parent, 'Y');
    end
end


function args = parsePlotArguments(metaClassObj, defaults, varargin)
%parsePlotArguments Parse arguments for plot function

% Parse inputs
    parser = inputParser;

    % Cannot make any assumptions about data type here
    % More detailed type check at the end of this method
    addParameter(parser, 'Parent', defaults.Parent);

    if contains(lower(metaClassObj.Name), 'laser')
        % Parse the maximum range setting
        addParameter(parser, 'MaximumRange', defaults.MaximumRange, ...
                     @(x) validateattributes(x, {'numeric'}, ...
                                             {'scalar', 'positive', 'nonempty'}, 'LaserScan', 'MaximumRange'));
    end

    % Return data
    parse(parser, varargin{:});

    if contains(lower(metaClassObj.Name), 'laser')
        args.MaximumRange = parser.Results.MaximumRange;
    else
        args.MaximumRange = defaults.MaximumRange;
    end

    args.Parent = parser.Results.Parent;

    % Delay the creation of a window before until all other inputs are
    % parsed
    if isequal(args.Parent, defaults.Parent)
        args.Parent = newplot;
    end

    % Check that parent is a graphics Axes handle
    robotics.internal.validation.validateAxesUIAxesHandle(args.Parent);
end
