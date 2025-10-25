classdef Container < handle
    %   matlab.hwmgr.internal.hwsetup.Container is an abstract interface
    %   for container widgets.
    
    %   Copyright 2016-17 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?matlab.hwmgr.internal.hwsetup.Widget})
        % Children - Cell-array of widgets of type 
        % matlab.hwmgr.internal.hwsetup.Widgetthat are parented to the
        % container 
        Children = {};
    end
    
    methods (Access=?matlab.unittest.TestCase)
        function out = getChildren(obj)
            % getChildren() - Returns the child widgets parented to the
            % container widget
            out = obj.Children;
        end
    end
end