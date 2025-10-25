classdef DesignTimeProperties < handle
    %DESIGNTIMEPROPERTIES This is a class that handles
    % AppDesigner specific design time properties for the component,
    % such as generating code, CodeName or GroupId.

    % Copyright 2015-2021 The MathWorks, Inc.

    properties
        % AppDesigner specific design time properties for the
        % component
        % CodeName of the component
        CodeName = '';

        % GroupId of the component belongs to
        GroupId = '';

        % AppDesigner specific design time properties for the
        % component code generation
        ComponentCode = {};

        % ContextMenu property requires a handle, ContextMenuId is what we
        % pass so our controller can translate peerNode Id to handle
        ContextMenuId = '';

        % The ImageRelativePath property stores the relative path from the
        % MLAPP file to the ImageSource or Icon image
        ImageRelativePath = '';

        % Struct of component property names and string-ified values that have been
        % dirtied while authoring an app
        DirtyProps = struct;
    end

end