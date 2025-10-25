function getPackageHelp(hp)
    if ~matlab.internal.feature('mpm')
        return;
    end

    package = mpmlist(Name=hp.topic);

    if isempty(package)
        return;
    end

    package = package(1);
    packageName = matlab.internal.help.makeStrong(hp.topic, hp.wantHyperlinks, hp.commandIsHelp);
    noContentHelp = " " + packageName + newline;
    if package.Summary == ""
        hp.helpStr = noContentHelp;
    else
        hp.helpStr = " " + packageName + " - " + package.Summary + newline;
    end
    if package.Description ~= ""
        hp.helpStr = append(hp.helpStr, matlab.internal.help.indentAndWrap(package.Description, hp.wantHyperlinks));
    end

    if ~ismissing(package.PackageRoot)
        topicContents = what(package.PackageRoot);
        banner = getString(message('MATLAB:help:PackageBanner', packageName));
        mainHelpStr = getFolderHelp(hp, topicContents, banner);
        if mainHelpStr ~= ""
            mainHelpStr = matlab.internal.help.indentBlock(mainHelpStr);
            hp.helpStr = append(hp.helpStr, newline, mainHelpStr);
        end

        for publicMember = package.Folders
            publicFolder = publicMember.Path;
            publicInfo = what(fullfile(package.PackageRoot, publicFolder));
            banner = getString(message('MATLAB:help:ContentsBanner', publicFolder));
            publicHelpStr = getFolderHelp(hp, publicInfo, banner);
            if publicHelpStr ~= ""
                publicHelpStr = matlab.internal.help.indentBlock(publicHelpStr);
                hp.helpStr = append(hp.helpStr, newline, publicHelpStr);
            end
        end
    end

    if hp.helpStr == noContentHelp
        hp.helpStr = '';
    end
end

function helpStr = getFolderHelp(hp, folderInfo, banner)
    if matlab.internal.help.folder.hasContents(folderInfo)
        helpStr = hp.getContentsMHelp(folderInfo, false);
    else
        helpStr = matlab.internal.help.folder.getDefaultHelp(folderInfo, banner, hp.wantHyperlinks, hp.command);
    end
end

%   Copyright 2022-2024 The MathWorks, Inc.
