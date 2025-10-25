function sensorFrameOutParamsCallback(subsysh,ParameterName,ExcludeParameters) %#ok<INUSL>
%sensorFrameOutParamsCallback controls the params visibility on the top
%mask based on the sensor mask

%   Copyright 2022 The MathWorks, Inc.
% Return if simulation is paused or running or during external mode.
if strcmpi(get_param(bdroot, 'SimulationStatus'), 'paused') || ...
        strcmpi(get_param(bdroot, 'SimulationStatus'), 'running') ||...
        strcmpi(get_param(bdroot,"ExtModeConnected"),'on')
    return;
end
if nargin < 3
    ExcludeParameters = [];
else
    ExcludeParameters = convertCharsToStrings(ExcludeParameters);
    validateattributes(ExcludeParameters,{'char','string'},{'nonempty'},'sensorFrameOutParamsCallback','ExcludeParameters',3);
end
    % Lower block path whose parameters are promoted
    sensorInSubsysh =  find_system(subsysh,'SearchDepth',1,'LookUnderMasks','on','FollowLinks','on','Name','Base sensor block');
    % Get mask object of top subsystem
    CurrentBlockMask = Simulink.Mask.get(subsysh);
    % Get mask object of lower block
    LowerBlockMask = Simulink.Mask.get(sensorInSubsysh);
    PropNames = {LowerBlockMask.Parameters.Name};
    % Get system object of lower block
    matlabsystem = get_param(sensorInSubsysh,'System');
    % Perform evaluation only when lower block is a System object
    ChangeVisibility = false;
    if exist(matlabsystem,'class')
        % Ignore if system object errors. Suppress warnings from slResolve.
        swarn = warning('off');
        cleanupObj = onCleanup(@() warning(swarn));
        try
            % Evaluate system object
            sysobj = eval(matlabsystem);
            sysobjProps = properties(sysobj);
            idxs = find(ismember({CurrentBlockMask.Parameters.Name},sysobjProps));
            % Set values of promoted properties to system object to check
            % visibility of parameters
            for j = 1:numel(idxs)
                i = idxs(j);
                ParamName = CurrentBlockMask.Parameters(i).Name;
                % Ignore if any error during set
                try
                    if isprop(sysobj,ParamName) && ~isInactiveProperty(sysobj,ParamName)
                            propvalue = get_param(subsysh,ParamName);
                            % Check whether the property is a checkbox
                            if isequal(LowerBlockMask.Parameters(ismember(PropNames,ParamName)).Type,'checkbox')
                                propvalue = isequal(propvalue,'on');
                            end
                        if ~isempty(propvalue)
                            set(sysobj,ParamName,propvalue);
                        end
                    end
                    ChangeVisibility = true;
                catch
                end
            end
        catch exc %#ok<NASGU>

        end
    end
    if ChangeVisibility
        containerVisibility = containers.Map;
        for i = 1:numel(CurrentBlockMask.Parameters)
            ParamName = CurrentBlockMask.Parameters(i).Name;
            % Change visibility of the parameter if the parameter is a
            % property of corresponding system object.
            if isprop(sysobj,ParamName) && ~(~isempty(ExcludeParameters) && contains(ParamName,ExcludeParameters))
                [~,phandleTopMask] =  CurrentBlockMask.getDialogControl(ParamName);
                if ~isKey(containerVisibility,phandleTopMask.Name)
                    containerVisibility(phandleTopMask.Name) = false;
                end
                if ~isInactiveProperty(sysobj,ParamName)
                    CurrentBlockMask.Parameters(i).Visible = 'on';
                    CurrentBlockMask.Parameters(i).Enabled = 'on';
                    phandleTopMask.Visible = 'on';
                    containerVisibility(phandleTopMask.Name) = true;
                else
                    CurrentBlockMask.Parameters(i).Visible = 'off';
                    CurrentBlockMask.Parameters(i).Enabled = 'off';
                    if containerVisibility(phandleTopMask.Name) == false
                        phandleTopMask.Visible = 'off';
                    end
                end
            end
        end
    end
end