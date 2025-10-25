function output = rosbag(operation, filePath)

    narginchk(1,2)

    try
        % Parse the specified operation and additional arguments
        if nargin == 1
            % Syntax: rosbag('FILEPATH')
            filePath = operation;
            filePath = convertStringsToChars(filePath);
            bagSelect = ros.Bag.parse(filePath);
            output = bagSelect;
            return;
        else
            % Syntax: rosbag info FILEPATH
            supportedOperations = {'info'};
            validOperation = validatestring(operation, supportedOperations, 'rosbag', 'operation');

            % Find bag file anywhere on the MATLAB path
            filePath = convertStringsToChars(filePath);
            if ~isempty(filePath) && isequal(filePath(1),'"') && isequal(filePath(end),'"')
                filePath = filePath(2:end-1);
            end
            absFilePath = robotics.internal.validation.findFilePath(filePath);

            if nargout == 0
                rosbagImpl(validOperation, absFilePath);
            else
                output = rosbagImpl(validOperation, absFilePath);
            end
        end

    catch ex
        % Save stack traces and exception causes internally, but do not
        % print them to the console
        rosex = ros.internal.ROSException.fromException(ex);
        throwAsCaller(rosex);
    end

end

function output = rosbagImpl(operation, param)
    switch operation
      case 'info'
        % Load rosbag
        filePath = param;
        %setupPaths for rosbag
        cleanPath = ros.internal.setupRosEnv(); %#ok<NASGU>
        bag = roscpp.bag.internal.RosbagWrapper(filePath);

        if nargout == 1
            % If output argument specified, return
            output = bag.infoStruct;
        else
            % Otherwise, print on console
            disp(bag.info);
        end
    end
end

%   Copyright 2022 The MathWorks, Inc.
