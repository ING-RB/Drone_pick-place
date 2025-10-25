function help_actions = helpActions(topic, helpstr, docTopic, found, commandOption)
    %

    %   Copyright 2020-2024 The MathWorks, Inc.

    % TODO: Rename this file to match what it actually does.
    % TODO: Create struct at the beginning then add data to the struct as I go.

    % Copied this from help2xml.m and modified.
    classInfo = [];
    titleFormat = getString(message('MATLAB:help2xml:MATLABFileHelpFormat'));
    viewFormat = getString(message('MATLAB:help2xml:ViewCodeFormat'));
    openFunction = 'edit';
    nameForTitle = '';

    [localTopic, hasLocalFunction] = matlab.lang.internal.introspective.fixLocalFunctionCase(topic);

    if hasLocalFunction
        fcnName = matlab.lang.internal.diagnostic.getStandardFunctionName(localTopic, extractAfter(localTopic, filemarker));
        qualifiedTopic = localTopic;
    else
        classInfo = matlab.internal.help.helpwin.classInfo4topic(topic, false);
        if ~isempty(classInfo) && classInfo.isMethod
            nameForTitle = buildMethodTitleName(classInfo);
        end
        if ~isempty(classInfo)
            fcnName = classInfo.fullTopic;
            if classInfo.isPackage
                viewFormat = [];
            else
                % For local methods and properties, we won't have a file path
                % here, so replace the method name with .m to see if we have
                % a MATLAB file containing help.
                location = which(regexprep(classInfo.definition, '>[^>]*$', ''));
                [~,~,viewFormat,openFunction] = prepareHeader(location);
            end
            qualifiedTopic = fcnName;
        else
            % Create the formats that we will use for the header text.
            [fcnName,~,viewFormat,openFunction] = prepareHeader(topic);

            % If there is a format to view, there needs to be a path to view
            if isempty(viewFormat)
                qualifiedTopic = topic;
            else
                [qualifyingPath, fcnName, extension] = fileparts(fcnName);
                [fcnName, qualifyingPath] = matlab.lang.internal.introspective.fixFileNameCase(append(fcnName, extension), qualifyingPath);
                qualifiedTopic = fullfile(qualifyingPath, fcnName);
            end
        end
    end

    if ~found
        title = 'MATLAB File Help';
        nameForTitle = fcnName;
        headerStruct = headerActionStruct(title, {}, {});
        classStruct = struct;
        helpStruct = buildStruct(nameForTitle, fcnName, title, found, headerStruct, classStruct);
        help_actions = helpStruct;
        return;
    end

    if isempty(topic)
        title = getString(message('MATLAB:help2xml:MATLABFileHelpDefaultTopics'));
    else
        if isempty(nameForTitle)
            nameForTitle = fcnName;
        end
        title = sprintf(titleFormat, nameForTitle);
    end

    headerText = {};
    headerActions = {};

    % Setup the left side link (view code for...)
    if ~isempty(qualifiedTopic)
        if ~isempty(viewFormat)
            headerText = {sprintf(viewFormat, fcnName)};
            headerActions = {matlab.internal.help.makeDualCommand(openFunction, qualifiedTopic)};
        end
    end

    if ~isempty(docTopic)
        headerText = [headerText, {getString(message('MATLAB:help2xml:GoToOnlineDoc', fcnName))}];
        headerActions = [headerActions, {matlab.internal.help.makeDualCommand('doc', docTopic)}];
    end

    headerStruct = headerActionStruct(title, headerText, headerActions);

    classStruct = struct;

    if matlab.internal.help.helpwin.displayClass(classInfo)
        % We'll display class information even if no help was found, since
        % there is likely to be interesting information in the metadata.
        try
            [fcnName, classStruct] = handleClassInfo(classInfo,fcnName,commandOption);
        catch
            % revert to function help
            found = ~isempty(helpstr);
        end
    end

    helpStruct = buildStruct(nameForTitle, fcnName, title, found, headerStruct, classStruct);
    help_actions = helpStruct;

end

%==========================================================================
function help_struct = buildStruct(nameForTitle, fcnName, title, found, headerStruct, classStruct)
    help_struct = struct;

    help_struct.nameForTitle = nameForTitle;
    help_struct.fcnName = fcnName;
    help_struct.title = title;
    help_struct.found = found;
    help_struct.headers = headerStruct;
    help_struct.classinfo = classStruct;
end

%==========================================================================
function [fcnName,titleFormat,viewFormat,openFunction] = prepareHeader(fcnName)
    % determine the class of help, and prepare header strings for it
    titleFormat = getString(message('MATLAB:help2xml:MATLABFileHelpFormat'));
    viewFormat = '';
    openFunction = 'edit';
    switch exist(fcnName, 'file')
    case 0
        % do nothing
    case 2
        % M File or text file
        viewFormat = getString(message('MATLAB:help2xml:ViewCodeFormat'));
    case 4
        % MDL File
        viewFormat = getString(message('MATLAB:help2xml:OpenModelFormat'));
        titleFormat = getString(message('MATLAB:help2xml:ModelHelpFormat'));
        openFunction = 'open';
    case 6
        % P File
        mFcnName = which(fcnName);
        mFcnName(end) = 'm';
        if exist(mFcnName, 'file')
            % P File with the M File still available
            % This should always be the case, since there is no help without the M
            viewFormat = getString(message('MATLAB:help2xml:ViewCodeFormat'));
            % strip the .p extension if it had been specified
            fcnName = regexprep(fcnName, '\.p$', '');
        end
    otherwise
        % this item exists, but is not viewable, so there is no location or format
        % however, fcnName can still be case corrected if there is a which value
        newFcnName = matlab.lang.internal.introspective.extractCaseCorrectedName(which(fcnName), fcnName);
        if ~isempty(newFcnName)
            fcnName = newFcnName;
        end
    end
end

%==========================================================================
function header_struct = headerActionStruct(title,headerText,headerActions)
    header_struct = struct;
    header_struct.title = title;

    rightStruct = struct;
    leftStruct = struct;

    switch length(headerText)
    case 0
        % do nothing
    case 1
        % set data for positon right
        rightStruct.text = headerText{1};
        if ~isempty(headerActions{1})
            rightStruct.action = matlab.internal.help.helpwin.formatMatlabLink(headerActions{1});
        else
            rightStruct.action = '';
        end
    otherwise
        % length 2 or more, set data for positons left and right, using
        % the last element for positon right
        leftStruct.text = headerText{1};
        if ~isempty(headerActions{1})
            leftStruct.action = matlab.internal.help.helpwin.formatMatlabLink(headerActions{1});
        else
            leftStruct.action = '';
        end
        lengthHeaderText = length(headerText);
        rightStruct.text = headerText{lengthHeaderText};
        if ~isempty(headerActions{lengthHeaderText})
            rightStruct.action = matlab.internal.help.helpwin.formatMatlabLink(headerActions{lengthHeaderText});
        else
            rightStruct.action = '';
        end
    end

    header_struct.rightside = rightStruct;
    header_struct.leftside = leftStruct;
end

%==========================================================================
function [topic, class_atts] = handleClassInfo(classInfo,topic,commandOption)
    className = matlab.lang.internal.introspective.makePackagedName(classInfo.packageName, classInfo.className);

    metacls = meta.class.fromName(className);
    if ~isempty(metacls)
        if classInfo.isConstructor
            topic = classInfo.className;
            constructorMeta = findClassMemberMeta(metacls.Methods, topic);
            class_atts = matlab.internal.help.helpwin.class2struct.buildConstructorStruct(constructorMeta, commandOption);
        elseif classInfo.isMethod
            methodName = classInfo.element;
            methodMeta = matlab.lang.internal.introspective.getMethod(metacls, methodName);
            class_atts = matlab.internal.help.helpwin.class2struct.buildMethodStruct(metacls, methodMeta, commandOption);
        elseif classInfo.isSimpleElement
            elementName = classInfo.element;
            [classElement, elementKeyword] = matlab.lang.internal.introspective.getSimpleElement(metacls, elementName);
            switch elementKeyword
            case 'properties'
                class_atts = matlab.internal.help.helpwin.class2struct.buildPropertyStruct(metacls, classElement, commandOption);
            case 'events'
                class_atts = matlab.internal.help.helpwin.class2struct.buildEventStruct(metacls, classElement, commandOption);
            case 'enumeration'
                class_atts = matlab.internal.help.helpwin.class2struct.buildEnumerationStruct(metacls, classElement, commandOption);
            end

        elseif classInfo.isClass
            classFilePath = classInfo.minimizePath;
            c2s = getClass2StructObj(classFilePath, metacls, commandOption);
            class_atts = c2s.buildClassStruct();
        end
    end
end

%==========================================================================
function class2structObj = getClass2StructObj(classFilePath, metaInfo, commandOption)
    % GETCLASS2STRUCTOBJ - helper method that constructs a matlab.internal.help.helpwin.class2struct
    % object.
    helpContainerObj = matlab.lang.internal.introspective.containers.HelpContainerFactory.create(classFilePath, 'metaInfo', metaInfo);
    class2structObj = matlab.internal.help.helpwin.class2struct(helpContainerObj, commandOption);
end

%==========================================================================
function metaData = findClassMemberMeta(metaArray, memberName)
    % FINDCLASSMEMBERMETA - given an array of class member meta data objects,
    % FINDCLASSMEMBERMETA returns the meta data object with the name
    % MEMBERNAME.
    metaData = metaArray{cellfun(@(c)strcmp(c.Name, memberName), metaArray)};

    % Truncate to only first found meta data object because class members may appear multiple
    % times.
    metaData = metaData(1);
end

%==========================================================================
function nameForTitle = buildMethodTitleName(classInfo)
    nameForTitle = sprintf('%s (%s)', classInfo.element, classInfo.fullClassName);
end
