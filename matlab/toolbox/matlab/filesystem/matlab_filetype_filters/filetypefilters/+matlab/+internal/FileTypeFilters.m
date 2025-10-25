% Copyright 2021-2022 The MathWorks, Inc.
classdef FileTypeFilters
    % this class returns the default file type filter list and
    % descriptors matching a given pattern

    properties (Constant, Access = private)
        openFileTypeFilters =  ["*.m;*.mlx;*.mat;*.mlapp;*.c;*.cpp;*.fig;*.h;*.mdl;*.mk;*.mlappinstall;*.mldatx;*.mlproj;*.mltbx;*.prj;*.rpt;*.rtw;*.sldd;*.slx;*.ssc;*.tlc;*.tmf;*.v;*.vhd", getResourceString('filesystem_services:filetypelabels:allMatlabFiles');
            "*.m;*.mlx", getResourceString('filesystem_services:filetypelabels:matlabCodeFiles');
            "*.fig", getResourceString('filesystem_services:filetypelabels:figures');
            "*.mat", getResourceString('filesystem_services:filetypelabels:matFiles');
            "*.mlapp", getResourceString('filesystem_services:filetypelabels:mlappFiles');
            "*.mlappinstall", getResourceString('filesystem_services:filetypelabels:mlappInstallFiles');
            "*.mldatx", getResourceString('filesystem_services:filetypelabels:dataExportFiles');
            "*.mltbx", getResourceString('filesystem_services:filetypelabels:toolboxFiles');
            "*.mlproj", getResourceString('filesystem_services:filetypelabels:projectArchiveFiles');
            "*.prj", getResourceString('filesystem_services:filetypelabels:projectFiles');
            "*.sldd", getResourceString('filesystem_services:filetypelabels:slDatadictFiles');
            "*.slx;*.mdl", getResourceString('filesystem_services:filetypelabels:slModelFiles');
            "*.rtw;*.tlc;*.tmf;*.c;*.cpp;*.h;*.mk;*.vhd;*.v", getResourceString('filesystem_services:filetypelabels:codeGenFiles');
            "*.rpt", getResourceString('filesystem_services:filetypelabels:rptGenFiles');
            "*.ssc", getResourceString('filesystem_services:filetypelabels:simscapeFiles');
            "*.sfx", getResourceString('filesystem_services:filetypelabels:sfxFiles');
            "*.*", getResourceString('filesystem_services:filetypelabels:allFiles')]; % Do not change All Files filter
        saveFileTypeFilters =  ["*.m;*.mlx;*.mat;*.mlapp;*.c;*.cpp;*.fig;*.h;*.mdl;*.mk;*.mlappinstall;*.mldatx;*.mlproj;*.mltbx;*.prj;*.rpt;*.rtw;*.sldd;*.slx;*.ssc;*.tlc;*.tmf;*.v;*.vhd", getResourceString('filesystem_services:filetypelabels:allMatlabFiles');
            "*.m", getResourceString('filesystem_services:filetypelabels:malabScriptFile');
            "*.mlx", getResourceString('filesystem_services:filetypelabels:matlabLiveScriptFile');
            "*.fig", getResourceString('filesystem_services:filetypelabels:figures');
            "*.mat", getResourceString('filesystem_services:filetypelabels:matFiles');
            "*.mlapp", getResourceString('filesystem_services:filetypelabels:mlappFiles');
            "*.mlappinstall", getResourceString('filesystem_services:filetypelabels:mlappInstallFiles');
            "*.mldatx", getResourceString('filesystem_services:filetypelabels:dataExportFiles');
            "*.mltbx", getResourceString('filesystem_services:filetypelabels:toolboxFiles');
            "*.mlproj", getResourceString('filesystem_services:filetypelabels:projectArchiveFiles');
            "*.prj", getResourceString('filesystem_services:filetypelabels:projectFiles');
            "*.sldd", getResourceString('filesystem_services:filetypelabels:slDatadictFiles');
            "*.slx", getResourceString('filesystem_services:filetypelabels:slxModelFiles');
            "*.mdl",  getResourceString('filesystem_services:filetypelabels:mdlModelFiles');
            "*.c", getResourceString('filesystem_services:filetypelabels:cFile');
            "*.cpp", getResourceString('filesystem_services:filetypelabels:cppFile');
            "*.h", getResourceString('filesystem_services:filetypelabels:headerFile');
            "*.mk", getResourceString('filesystem_services:filetypelabels:makeFile');
            "*.v", getResourceString('filesystem_services:filetypelabels:verilogFile');
            "*.vhd", getResourceString('filesystem_services:filetypelabels:vhdlFile');
            "*.tmf", getResourceString('filesystem_services:filetypelabels:templateMakeFile');
            "*.rtw", getResourceString('filesystem_services:filetypelabels:realTimeWorkshopFile');
            "*.tlc", getResourceString('filesystem_services:filetypelabels:targetLangCompilerFile');
            "*.rpt", getResourceString('filesystem_services:filetypelabels:rptGenFiles');
            "*.ssc", getResourceString('filesystem_services:filetypelabels:simscapeFiles');
            "*.sfx", getResourceString('filesystem_services:filetypelabels:sfxFiles');
            "*.*", getResourceString('filesystem_services:filetypelabels:allFiles')]; % Do not change All Files filter
    end

    methods
        function openFilters  = getOpenFileExtensionFilters(this)
            openFilters = this.openFileTypeFilters;
        end

        function saveFilters  = getSaveFileExtensionFilters(this)
            saveFilters = this.saveFileTypeFilters;
        end

        function descLabel = getFilterDescription(this, pattern)
            descLabel = "";
            % first check open filters
            index = ismember(this.openFileTypeFilters(:,1), pattern);
            if sum(index)
                descLabel = this.openFileTypeFilters(index,2);
            else
                % then check save filters
                index = ismember(this.saveFileTypeFilters(:,1), pattern);
                if sum(index)
                    descLabel = this.saveFileTypeFilters(index,2);
                end
            end
        end
    end
end

function string = getResourceString (id)
string = message(id).getString();
end