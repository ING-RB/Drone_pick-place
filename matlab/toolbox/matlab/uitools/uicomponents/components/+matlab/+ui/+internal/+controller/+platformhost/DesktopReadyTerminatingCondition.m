function retval = DesktopReadyTerminatingCondition
    % DESKTOPREADYTERMINATINGCONDITION
    mlock
    persistent rootApp

    % Check environmental conditions and return early if possible
    if isempty(rootApp)
        if ~feature("webui")
            % Return early for Java Desktop
            %disp("!!!!! EARLY RETURN FOR JAVA DESKTOP !!!!!");            
            retval = true;
            return;
        elseif isdeployed || ~feature("HasDisplay") || batchStartupOptionUsed
            % No Desktop integration in deployed apps (short-term), no display, or batch
            %disp("!!!!! ABORTING DESKTOP RUNNING CHECK !!!!!");
            retval = true;
            return;
        end
    end

    % Check status of the Desktop
    rootApp = matlab.ui.container.internal.RootApp.getInstance();
    if rootApp.State == "RUNNING"
        %disp("========== DESKTOP RUNNING ENSURED ==========");
        retval = true;
        rootApp = [];
    else
        %disp("---------- WAITING FOR DESKTOP INITIALIZATION ----------");
        retval = false;
    end
end
