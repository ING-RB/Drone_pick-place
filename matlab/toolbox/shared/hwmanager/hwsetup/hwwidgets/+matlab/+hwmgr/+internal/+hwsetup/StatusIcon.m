classdef StatusIcon < uint16
    % STATUSICON - Enumeration class for icons. Creates an HTML tag for
    % icons to be displayed in the Hardware Setup App window.
    % Supported Icons-
    % Fail
    % Pass
    % Warn
    % Help
    % Question
    % Busy
    % MATLAB
    % NilStat
    % f = matlab.hwmgr.internal.hwsetup.StatusIcon.Fail.dispIcon() returns
    % the html tag for displaying an icon to denote a failed step
    % m = matlab.hwmgr.internal.hwsetup.StatusIcon.MATLAB.dispIcon() returns
    % the html tag for displaying the icon for MATLAB
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    enumeration
        Fail    (0)
        Pass    (1)
        Warn    (2)
        Help    (3)
        Question(4)
        Busy    (5) % or InProgress
        MATLAB  (6)
        NilStat (7)
    end
    
    methods
        function data = dispIcon(obj)
            switch (obj)
                case 0
                    img = 'error_16.svg';
                    data = obj.htmlImportImage(img);
                case 1
                    img = 'pass_16.svg';
                    data = obj.htmlImportImage(img);
                case 2
                    img = 'warning_16.svg';
                    data = obj.htmlImportImage(img);
                case 3
                    img = 'help_16.svg';
                    data = obj.htmlImportImage(img);
                case 4
                    img = 'quest_16.svg';
                    data = obj.htmlImportImage(img);
                case 5
                    img = 'busy_gif.gif';
                    data = obj.htmlImportImage(img);
                case 6
                    img = 'MatlabIcon.svg';
                    data = obj.htmlImportImage(img);
                case 7
                    img = 'nil_16.svg';
                    data = obj.htmlImportImage(img);
            end
        end
        
        function data = htmlImportImage(~, imgFileName)
            %htmlImportImage- prepare html to display image
            tech = matlab.hwmgr.internal.hwsetup.util.WidgetTechnology.getTechnology();
            % IconsFactory.createInstance({
            %   id: 'add',
            %   iconsLocation: 'ui/icons/',
            %   registryLocation: 'ui/icons/registry.json',
            %   resolvePath: Remote.createWorkerRoutingHostUrl
            % });
            if strcmp(tech, 'appdesigner')
                filePath = fullfile('/', 'toolbox', 'shared', 'hwmanager',...
                    'hwsetup','hwwidgets','resources', imgFileName);
                filePath = strrep(filePath, '\', '/');
                data = ['<img src="' filePath '" style="height:16px; width:16px;"/>'];
            else
                filePath = fullfile(matlabroot, 'toolbox', 'shared', 'hwmanager',...
                    'hwsetup','hwwidgets','resources', imgFileName);
                filePath = strrep(['file:/' filePath],'\','/');
                if isunix
                    filePath = strrep(filePath, '//' , '/');
                end
                data = ['<img src="' filePath '" height="16" width="16"></img>'];
            end
        end
    end 
end