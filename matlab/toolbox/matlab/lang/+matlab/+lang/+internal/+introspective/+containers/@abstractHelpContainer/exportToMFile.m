function outputMFilePath = exportToMFile(this, outputDir)
    % EXPORTTOMFILE - takes a HelpContainer object as input and generates
    % a MATLAB file containing all the help comments stored in this object.
    %
    % Example:
    % filePath = which('addpath');
    % helpContainer = matlab.lang.internal.introspective.containers.HelpContainerFactory.create(filePath);
    % outputDir = pwd;
    % outputMFilePath = helpContainer.exportToMFile(outputDir);
    
    % Copyright 2009-2024 The MathWorks, Inc.

    narginchk(2,2);
    
    if ~ischar(outputDir) || ~isfolder(outputDir)
        error(message('MATLAB:introspective:exportToMFile:InvalidOutputDirectory'));
    end
    
    % Need to extract method name from package and/or class qualified name
    fileName = regexp(this.mFileName, '\w*$', 'match', 'once');
    
    outputMFilePath = fullfile(outputDir, append(fileName, '.m'));
    
    outputFileHandle = fopen(outputMFilePath, 'w');
    
    if outputFileHandle < 0
        error(message('MATLAB:introspective:exportToMFile:MFileCreationFailed', outputDir));
    end
    
    closeFile = onCleanup(@()fclose(outputFileHandle));
    
    if this.isClassHelpContainer
        writeClassHelpMFile(this, outputFileHandle, fileName);
    else
        if ~writeFunctionHelpMFile(this, outputFileHandle)
            fprintf(outputFileHandle, '%%');
        end
        writeCopyrightText(this, outputFileHandle);
    end
    
end

%% ------------------------------
function hasMainHelp = writeFunctionHelpMFile(helpContainer, outputFileHandle)
    % writeFunctionHelpMFile - outputs the main help string stored in
    % HelpContainer to the output file as a comment.
    mainHelpStr = helpContainer.getHelp;
    
    hasMainHelp = mainHelpStr ~= "";
    if hasMainHelp
        mainHelpStr = regexprep(mainHelpStr, '^.', '%', 'lineanchors');
        if ~endsWith(mainHelpStr, newline)
            mainHelpStr = append(mainHelpStr, newline);
        end
        fprintf(outputFileHandle, '%s', mainHelpStr);
    end
end

%% ------------------------------
function writeCopyrightText(helpContainer, outputFileHandle)
    copyrightText = helpContainer.getCopyrightText;
    if copyrightText ~= ""
        fprintf(outputFileHandle, '\n %s\n\n', copyrightText);
    end
end


%% ------------------------------
function writeClassHelpMFile(helpContainer, outputFileHandle, className)
    
    fprintf(outputFileHandle, 'classdef %s', className);
    if helpContainer.superClassList ~= ""
        fprintf(outputFileHandle, '< %s', helpContainer.superClassList);        
    end
    fprintf(outputFileHandle, '\n');
    
    if writeFunctionHelpMFile(helpContainer, outputFileHandle)
        % if class has main help then append newline followed by copyright
        writeCopyrightText(helpContainer, outputFileHandle);
        writeClassMembers(helpContainer, outputFileHandle);
    else
        % otherwise write the copyright at the bottom of the class file
        writeClassMembers(helpContainer, outputFileHandle);
        writeCopyrightText(helpContainer, outputFileHandle);
    end
    
end

%% ------------------------------
function writeClassMembers(helpContainer, outputFileHandle)
    % writeClassMembers - prints the help content of a ClassHelpContainer
    % related to methods (including constructor) and properties into the
    % output file.

    % Write 'methods' block
    strIndent = getIndent(1);
    fprintf(outputFileHandle, append(strIndent, 'methods\n'));

    % Print the constructor
    printConstructorFcnHandle = @(constructorHelpContainer) printMethodHelp(outputFileHandle, ...
            constructorHelpContainer, 'out=%s');

    printAllMembersHelp(helpContainer.getConstructorIterator, printConstructorFcnHandle);

    % Print all the methods
    printMethodsFcnHandle = @(methodHelpContainer) printMethodHelp(outputFileHandle, ...
            methodHelpContainer, 'out=%s(~) %%#ok<STOUT>');

    printAllMembersHelp(helpContainer.getConcreteMethodIterator, printMethodsFcnHandle);
    
    fprintf(outputFileHandle, append(strIndent, 'end\n'));
    
    if helpContainer.hasAbstractHelp
        % Write abstract methods block
        fprintf(outputFileHandle, append(strIndent, 'methods (Abstract)\n'));

        % Print all the abstract methods as if they are properties
        printAbstractFcnHandle = @(abstractHelpContainer) printPrefixHelp(outputFileHandle, abstractHelpContainer);

        printAllMembersHelp(helpContainer.getAbstractMethodIterator, printAbstractFcnHandle);

        fprintf(outputFileHandle, append(strIndent, 'end\n'));
    end
    
    for elementType = matlab.lang.internal.introspective.getSimpleElementTypes            
        printSimpleElementHelp(outputFileHandle, strIndent, elementType.keyword, helpContainer);
    end
    
    fprintf(outputFileHandle, 'end\n');
end

%% ------------------------------
function printSimpleElementHelp(outputFileHandle, strIndent, elementKeyword, helpContainer)
    elementIterator = helpContainer.getSimpleElementIterator(elementKeyword);
    
    if elementIterator.hasNext
        % Write block header
        fprintf(outputFileHandle, append(strIndent, elementKeyword, '\n'));

        % Print all the elements
        printFcnHandle = @(elementHelpContainer) printPrefixHelp(outputFileHandle, elementHelpContainer);

        printAllMembersHelp(elementIterator, printFcnHandle);

        fprintf(outputFileHandle, append(strIndent, 'end\n'));
    end
end

%% ------------------------------
function printAllMembersHelp(memberIterator, printMember)
    % printAllMembersHelp - iterates through and prints the help content of
    % the ClassMemberHelpContainers
    while memberIterator.hasNext
        memberHelpContainer = memberIterator.next;
        printMember(memberHelpContainer);
    end    
end

%% ------------------------------
function printMethodHelp(outputFileHandle, memberHelpContainerObj, functionFormat)
    % printMethodHelp - writes help comments for a class method to the
    % output file.
    twoTabIndent = getIndent(2);
    
    functionFormat = sprintf('%s%s %s\n', twoTabIndent, 'function', functionFormat);
    fprintf(outputFileHandle, functionFormat, memberHelpContainerObj.Name);
    
    methodHelp = memberHelpContainerObj.getHelp;
    
    if methodHelp ~= ""
        threeTabIndent = getIndent(3);
        methodHelp = formatHelpString(methodHelp, append(threeTabIndent, '%'));
        fprintf(outputFileHandle, '%s', methodHelp);
    end
    
    fprintf(outputFileHandle, '%send\n\n', twoTabIndent);
end

%% ------------------------------
function printPrefixHelp(outputFileHandle, prefixHelpContainerObj)
    % printPrefixHelp - writes help comments followed by the identifier name
    prefixHelp = prefixHelpContainerObj.getHelp;
    indent = getIndent(2);
    if prefixHelp ~= ""
        formattedStr = formatHelpString(prefixHelp, append(indent, '%'));
        fprintf(outputFileHandle, '%s', formattedStr);
    end
    fprintf(outputFileHandle, '%s%s;\n\n', indent, prefixHelpContainerObj.Name);
end

%% ------------------------------
function formattedHelp = formatHelpString(origHelpStr, commentIndent)
    % formatHelpString - helper method to format help comments
    formattedHelp = regexprep(origHelpStr, '^.', commentIndent, 'lineanchors');
    
end

%% ------------------------------
function outputStr = getIndent(numTabs)
    % getIndent - helper function to format the indents for help comments
    % in generated file
    outputStr = repmat(' ', 1, numTabs * 4); % tab defined as four spaces
end
