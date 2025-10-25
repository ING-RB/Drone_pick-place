
classdef PlotsTabState < handle
    %  This class maintains the state of the Plots Tab
    % The current state of the plots tab is maintained here. This includes the
    % createNewFigure option and the information about which
    % selection(variable editor or workspace browser) is currently
    % reflected in the plots gallery

    % Copyright 2013-2025 The MathWorks, Inc.

    properties
        % indicates which manager(Variable Editor or Workspace Browser is
        % currently used by the Plots Tab)
        currentManagerForPlotsTab;
        % Represents the current state of auto-linking. Used by functions
        % like plotpickerfunc to decide whether to generate linking code.
        % (See PlotsTabListeners logic for property set)
        AutoLinkData logical;
    end

    methods(Static=true)
        function out = getInstance()
            persistent stateInstance;
            mlock;
            if isempty(stateInstance)
                stateInstance = internal.matlab.plotstab.PlotsTabState;
                stateInstance.AutoLinkData = false;
            end
            out = stateInstance;
        end
    end
end
