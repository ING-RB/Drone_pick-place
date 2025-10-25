classdef (Abstract) DesktopAction < handle
% DESKTOPACTION A class representing an action that is external
% to the App Designer desktop, is user initiated, and depends
% on the App Designer desktop being fully initialized.

% Copyright 2018-2020 The MathWorks, Inc.

    methods
        % Required method for DesktopAction
        %
        % Perform whatever action is to be done once
        % the App Designer desktop is initialized.
        runAction(obj, proxyView)
    end
end
