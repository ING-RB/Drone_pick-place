function rmwImpl = getCurrentRMWImplementation
%This function is for internal use only. It may be removed in the future.

%getCurrentRMWImplementation Return the ROS Middleware Implementation to be used if not specified
%   Uses the value of the 'RMW_IMPLEMENTATION' stored in preferences, if valid, or
%   returns the ROS 2 default value of 'rmw_fastrtps_cpp' otherwise.

%   Copyright 2021-2022 The MathWorks, Inc.

    defaultRMW = 'rmw_fastrtps_cpp';

    % Ignore invalid rmw Implementation values (no error)
    try
        environmentRMW = ros.internal.ros2.RMWEnvironment;
        if isempty(environmentRMW.RMWImplementation)
            if isempty(getenv('RMW_IMPLEMENTATION'))
                % If both preferences and setenv is not available, return
                % default value as 'rmw_fastrtps_cpp'.
                rmwImpl = defaultRMW;
            else
                % If preferences are not available and setenv is available, return
                % the value from the evironment variable.
                rmwImpl = getenv('RMW_IMPLEMENTATION');
            end
            return;
        end
        validateattributes(environmentRMW.RMWImplementation, ...
                           {'char', 'string'}, ...
                           {'scalartext'})
        rmwImpl = environmentRMW.RMWImplementation;
    catch
        rmwImpl = defaultRMW;
    end

end
