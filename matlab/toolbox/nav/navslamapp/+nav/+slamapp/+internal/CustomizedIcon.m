classdef CustomizedIcon < handle
%CUSTOMIZEDICON

% Copyright 2018-2023 The MathWorks, Inc.

    methods (Static)
        function icon = IMPORT_FROM_FILE_24
            icon = matlab.ui.internal.toolstrip.Icon('import');
        end

        function icon = IMPORT_FROM_FILE_16
            icon = matlab.ui.internal.toolstrip.Icon('import');
        end

        function icon = IMPORT_FROM_WORKSPACE_16
            icon = matlab.ui.internal.toolstrip.Icon('workspace');
        end

        function icon = SYNC_MAP_24
            icon = matlab.ui.internal.toolstrip.Icon('swap');
        end

        function icon = SYNC_MAP_FAST_24
            icon = matlab.ui.internal.toolstrip.Icon('lightning_swap');
        end

        function icon = OCC_MAP_24
            icon = matlab.ui.internal.toolstrip.Icon('occMap');
        end

        function icon = AUTO_LOOPCLOSURE_24
            icon = matlab.ui.internal.toolstrip.Icon('test_loopClosure');
        end

        function icon = AUTO_INCREMENTAL_24
            icon = matlab.ui.internal.toolstrip.Icon('text_incremental');
        end

        function icon = MODIFY_LOOPCLOSURE_24
            icon = matlab.ui.internal.toolstrip.Icon('edit_LoopClosure');
        end

        function icon = MODIFY_INCREMENTAL_24
            icon = matlab.ui.internal.toolstrip.Icon('edit_incremental');
        end

        function icon = IGNORE_SCANMATCH_16
            icon = matlab.ui.internal.toolstrip.Icon('unmodified');
        end

        function icon = LINEAR_24
            icon = matlab.ui.internal.toolstrip.Icon('pan_scan');
        end

        function icon = ANGULAR_24
            icon = matlab.ui.internal.toolstrip.Icon('rotate_scan');
        end

        function icon = SNAP_24
            icon = matlab.ui.internal.toolstrip.Icon('snap_scan');
        end

        function icon = LAYOUT_THREE_24
            icon = matlab.ui.internal.toolstrip.Icon('splitPanelLayout');
        end

        function icon = GENERATE_MATLAB_SCRIPT_16
            icon = matlab.ui.internal.toolstrip.Icon('export_script');
        end
    end
end
