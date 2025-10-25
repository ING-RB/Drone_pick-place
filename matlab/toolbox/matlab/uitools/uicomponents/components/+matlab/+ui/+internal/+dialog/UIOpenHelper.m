classdef UIOpenHelper
    %UIOPENHELPER
    % This class contains static utility methods which is used by uiopen
    % function to support web figures mode. The methods -
    % getFilterListJAVA, setStatusBarJAVA, getPatternAndDescriptionJAVA and its
    % usages can be removed once we switch to web figures.
    

    %Copyright 2022 The MathWorks, Inc.
    methods(Static)
        function filterCell = getFilterList(type)
            if ~matlab.ui.internal.dialog.FileDialogHelper.isWebUI()
                filterCell = matlab.ui.internal.dialog.UIOpenHelper.getFilterListJAVA(type);
                return;
            end

            persistent openFilters
            if isempty(openFilters)
                openFilters = matlab.internal.FileTypeFilters().getOpenFileExtensionFilters();
            end
            persistent fileTypeResourceString
            if isempty(fileTypeResourceString)
                fileTypeResourceString.allMatlabFiles = getResourceString('filesystem_services:filetypelabels:allMatlabFiles');
                fileTypeResourceString.allFiles = getResourceString('filesystem_services:filetypelabels:allFiles');
                fileTypeResourceString.matlabCodeFiles = getResourceString('filesystem_services:filetypelabels:matlabCodeFiles');
                fileTypeResourceString.figures = getResourceString('filesystem_services:filetypelabels:figures');
                fileTypeResourceString.matFiles = getResourceString('filesystem_services:filetypelabels:matFiles');
                fileTypeResourceString.slModelFiles = getResourceString('filesystem_services:filetypelabels:slModelFiles');
            end
            switch(lower(type))
                case 'matlab'
                    filterTypes = [fileTypeResourceString.allMatlabFiles; fileTypeResourceString.matlabCodeFiles; fileTypeResourceString.figures; fileTypeResourceString.allFiles];
                case 'load'
                    filterTypes = [fileTypeResourceString.matFiles; fileTypeResourceString.allMatlabFiles; fileTypeResourceString.allFiles];
                case 'figure'
                    filterTypes = [fileTypeResourceString.figures; fileTypeResourceString.allMatlabFiles; fileTypeResourceString.allFiles];
                case 'simulink'
                    filterTypes = [fileTypeResourceString.slModelFiles; fileTypeResourceString.allMatlabFiles; fileTypeResourceString.allFiles];
                case 'editor'
                    filterTypes = [fileTypeResourceString.allMatlabFiles; fileTypeResourceString.allFiles];
                    [~, idx] = ismember(filterTypes, openFilters(:,2));
                    filterCell = cellstr(openFilters(idx,:));
                    filterCell(idx(1)) = cellstr(regexprep(openFilters(idx(1)), {'*.slx;','*.mat;','*.fig;','*.mlapp;','*.mlappinstall;'}, ''));
                    return;
                otherwise
                    filterCell = type;
                    return;
            end
            [~, idx] = ismember(filterTypes, openFilters(:,2));
            filterCell = cellstr(openFilters(idx,:));
        end

        function setStatusBar(varsCreated)
            if ~matlab.ui.internal.dialog.FileDialogHelper.isWebUI()
                matlab.ui.internal.dialog.UIOpenHelper.setStatusBarJAVA(varsCreated);
                return;
            end

            % If the environment is a web-enabled web app server, bypass
            % "setStatusBar" since there is no front-end desktop
            if isdeployed && matlab.internal.environment.context.isWebAppServer
                return;
            end

            if varsCreated
                theMessage = getString(message('MATLAB:uistring:uiopen:VariablesCreatedInCurrentWorkspace'));
            else
                theMessage = getString(message('MATLAB:uistring:uiopen:NoVariablesCreatedInCurrentWorkspace'));
            end

            mo = matlab.ui.container.internal.RootApp.getInstance();
            mo.Status = theMessage;
        end

    end

    methods (Access = private, Static)

        function filterList = getFilterListJAVA(type)
            allML = matlab.ui.internal.dialog.UIOpenHelper.getPatternAndDescriptionJAVA(com.mathworks.mwswing.FileExtensionFilterUtils.getMatlabProductFilter());
            switch(lower(type))
                case 'matlab'
                    filterList = [
                        allML; ...
                        matlab.ui.internal.dialog.UIOpenHelper.getPatternAndDescriptionJAVA(com.mathworks.mwswing.FileExtensionFilterUtils.getMatlabFileFilter()); ...
                        matlab.ui.internal.dialog.UIOpenHelper.getPatternAndDescriptionJAVA(com.mathworks.mwswing.FileExtensionFilterUtils.getFigFileFilter()); ...
                        {'*.*',   getString(message('MATLAB:uistring:uiopen:AllFiles'))}
                        ];
                case 'load'
                    filterList = [
                        matlab.ui.internal.dialog.UIOpenHelper.getPatternAndDescriptionJAVA(com.mathworks.mwswing.FileExtensionFilterUtils.getMatFileFilter()); ...
                        allML; ...
                        {'*.*',   getString(message('MATLAB:uistring:uiopen:AllFiles'))}
                        ];
                case 'figure'
                    filterList = [
                        matlab.ui.internal.dialog.UIOpenHelper.getPatternAndDescriptionJAVA(com.mathworks.mwswing.FileExtensionFilterUtils.getFigFileFilter()); ...
                        allML; ...
                        {'*.*',   getString(message('MATLAB:uistring:uiopen:AllFiles'))}
                        ];
                case 'simulink'
                    % Simulink filters are the only ones hardcoded here.
                    % This should be changed this in future
                    filterList = [
                        {'*.mdl;*.slx', getString(message('MATLAB:uistring:uiopen:ModelFiles'))}; ...
                        allML; ...
                        {'*.*',   getString(message('MATLAB:uistring:uiopen:AllFiles'))}
                        ];
                case 'editor'
                    % We should be deprecating this usage.
                    % uiopen('editor') is an unused option and does not scale well to new file extenstions
                    % This option primarily used to open a file in the
                    % MATLAB Editor using the EDIT function
                    % According to the documentation we need to remove .mat, .fig, .slx from the list
                    allMLWithoutBinary = {regexprep(allML{1}, {'*.slx;','*.mat;','*.fig;','*.mlapp;','*.mlappinstall;'}, ''), allML{2}};
                    filterList = [
                        allMLWithoutBinary;...
                        {'*.*',   getString(message('MATLAB:uistring:uiopen:AllFiles'))}
                        ];
                otherwise
                    filterList = type;
            end
        end

        function filters = getPatternAndDescriptionJAVA(fileExtensionFilters)
            filters = cell(1,2);

            % PATTERNS
            pattern = fileExtensionFilters.getPatterns;
            if length(pattern)>1
                cellPatterns = arrayfun(@(x) [char(x) ';'], pattern,'UniformOutput',false);
                filters{1,1} = [cellPatterns{:}];
            else
                filters{1,1} = char(pattern);
            end

            % DESCRIPTIONS
            filters{1,2} = char(fileExtensionFilters.getDescription);
        end

        function setStatusBarJAVA(varsCreated)
            if varsCreated
                theMessage = getString(message('MATLAB:uistring:uiopen:VariablesCreatedInCurrentWorkspace'));
            else
                theMessage = getString(message('MATLAB:uistring:uiopen:NoVariablesCreatedInCurrentWorkspace'));
            end

            % The following class reference is undocumented and
            % unsupported, and may change at any time.
            dt = javaMethod('getInstance', 'com.mathworks.mde.desk.MLDesktop');
            if dt.hasMainFrame
                dt.setStatusText(theMessage);
            else
                disp(theMessage);
            end
        end

    end
end

% The purpose of this function is to query the file filter descriptions
function str = getResourceString (id)
    str = convertCharsToStrings(message(id).getString());
end