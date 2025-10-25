classdef VEColumnConstants < handle
    %Constants for various column widths in the Variable Editor

    % Copyright 2017 The MathWorks, Inc.
     properties (Constant)
        datetimeColumnWidth = 120;
        complexNumDefaultWidth = 120;
        defaultColumnWidth = 70;
        % TODO: Tech Debt: Remove once we switch to client side computation of default widths
        defaultLiveEditorColumnWidth = 75;
        categoricalMinWidth = 45;
     end
end
