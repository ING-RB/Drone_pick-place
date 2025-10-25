function helpText = modifyInheritedHelp(classInfo, helpText, hotLinkCommand)
    helpSections = matlab.internal.help.HelpSections(helpText);
    if ~isempty(helpSections.SeeAlso)
        fullSubClassName =  classInfo.fullClassName;
        subClassName = removePackagesFromName(fullSubClassName);
        superClassName = removePackagesFromName(classInfo.fullSuperClassName);
        newMethodName = @(sep, oldMethodName)conditionalMethodName(sep, oldMethodName, subClassName, superClassName);  %#ok<NASGU>
        modifiedSeeAlso = regexprep(helpSections.SeeAlso.helpStr, append('(?<=[\s,]|^)', classInfo.fullSuperClassName, '\>(.)?(\w*\>)'), append(fullSubClassName, '${newMethodName($1,$2)}'), 'ignorecase');

        helpSections.SeeAlso.helpStr = modifiedSeeAlso;
        helpText = helpSections.getFullHelpText;
    end

    if classInfo.superWrapper.hasClassHelp
        elementName = makeStrong(classInfo.fullTopic, hotLinkCommand);
        superClassName = hyperName(classInfo.fullSuperClassName, hotLinkCommand);
        inheritedMessage = getString(message('MATLAB:introspective:displayHelp:HelpInheritedFromSuperclass', elementName, superClassName));
        if ~endsWith(helpText, newline)
            helpText = append(helpText, newline);
        end
        helpText = append(helpText, newline, inheritedMessage);
    end
end

function newMethodName = conditionalMethodName(sep, oldMethodName, subClassName, superClassName)
    if strcmpi(oldMethodName, superClassName)
        % this "method" is the constructor for the superClass, replace with
        % the className so that it is still the constructor
        newMethodName = append(sep, subClassName);
    else
        newMethodName = append(sep, oldMethodName);
    end
end

function className = removePackagesFromName(className)
    className = regexp(className, '\w*$', 'match', 'once');
end

function className = hyperName(className, hotLinkCommand)
    if hotLinkCommand ~= ""
        className = matlab.internal.help.createMatlabLink(hotLinkCommand, className, className);
    end
end

function name = makeStrong(name, hotLinkCommand)
    if hotLinkCommand ~= ""
        name = matlab.internal.help.makeStrong(name, true, true);
    end
end


%   Copyright 2024 The MathWorks, Inc.
