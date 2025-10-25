function editRelativeNameOrOpen(name, contextFile)
    % This function is internal and may change in future releases.
    try
        removeDot = count(name, '.') == 1;
        if removeDot
            nameResolver = matlab.lang.internal.introspective.resolveName(name);
            removeDot = isempty(nameResolver.classInfo);
        end
        if removeDot
            elementName = extractAfter(name, '.');
        else
            elementName = name;
        end
        if isvarname(elementName) || iskeyword(elementName)
            if ~removeDot && evalin('caller', "exist('" + name + "', 'var')")
                evalin('caller', "openvar('" + name + "', " + name + ");");
                return;
            end
            if which(contextFile) == ""
                % file is not on the path, temporarily add it.
                parentDir = matlab.lang.internal.introspective.separateImplicitDirs(fileparts(contextFile));
                cleanup.path = onCleanup(@()rmpath(parentDir));
                addpath(parentDir);
            end
            nameResolver = matlab.lang.internal.introspective.resolveName(contextFile);
            if ~isempty(nameResolver.classInfo) && (nameResolver.classInfo.isClass || nameResolver.classInfo.isMethod)
                classInfo = nameResolver.classInfo;
                className = matlab.lang.internal.introspective.makePackagedName(classInfo.packageName, classInfo.className);
                qualifiedName = append(className, '.', elementName);
                nameResolver = matlab.lang.internal.introspective.resolveName(qualifiedName);
                if nameResolver.isResolved
                    if nameResolver.isCaseSensitive || isempty(matlab.lang.internal.introspective.safeWhich(name, true))
                        edit(qualifiedName);
                        return;
                    end
                end
            end
        end
        open(name);
    catch
        try
            edit(name);
        catch e
            %  An error dialog popsup with edit command error message.
            errordlg(e.message);
        end
    end
end
%   Copyright 2021-2023 The MathWorks, Inc.
