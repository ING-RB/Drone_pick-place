classdef ClassHelpContainer < matlab.lang.internal.introspective.containers.abstractHelpContainer
    % CLASSHELPCONTAINER - stores help and class information related to a
    % MATLAB Object System class
    %
    % Remark:
    % Creation of this object should be made by the static 'create' method
    % of matlab.lang.internal.introspective.containers.HelpContainerFactory class.
    %
    % Example:
    % filePath = which('RandStream');
    % helpContainer = matlab.lang.internal.introspective.containers.HelpContainerFactory.create(filePath);
    %
    % The code above constructs a ClassHelpContainer object.

    % Copyright 2009-2024 The MathWorks, Inc.

    properties (Access = private)
        % SimpleElementHelpContainers stores metadata & help comments
        % for simple elements in a struct where each field corresponds to
        % a simple element type, containing a struct in which each field has one
        % ClassMemberHelpContainer.
        SimpleElementHelpContainers;

        % MethodHelpContainers - stores metadata & help comments for
        % methods in a dictionary where each field corresponds to one
        % ClassMemberHelpContainer.
        MethodHelpContainers;

        % AbstractHelpContainers - stores metadata & help comments
        % for abstract methods in a dictionary where each field corresponds to
        % one ClassMemberHelpContainer.
        AbstractHelpContainers;

        % ConstructorHelpContainer - stores metadata & help comments for constructor
        ConstructorHelpContainer;

        minimalPath; % minimal path to class

        classInfo; % used to extract help comments for class members

        cacheCleanup; % to hold the cache open
    end

    properties (SetAccess = private)
        % onlyLocalHelp - boolean flag determines two things:
        % 1. To store entire help or just H1 line
        % 2. to store help information for inherited methods and properties
        onlyLocalHelp;

        noSuperClassHelp; % for this class, and it's own @folder members

        superClassList; % used to assuage code analyzer
    end

    methods
        %% ---------------------------------
        function this = ClassHelpContainer(filePath, classMetaData, onlyLocalHelp, noSuperClassHelp)
            % constructor takes three input arguments:
            % 1. filePath - Full file path to MATLAB file
            % 2. classMetaData - ?className
            % 3. onlyLocalHelp - a boolean flag to determine whether to
            % include inherited methods/properties and methods defined
            % outside the classdef file.

            mFileName = classMetaData.Name;
            nameResolver = matlab.lang.internal.introspective.resolveName(mFileName, JustChecking=false, FindBuiltins=true);
            ci = nameResolver.classInfo;
            helpStr = ci.getHelp(~onlyLocalHelp);

            mainHelpContainer = matlab.lang.internal.introspective.containers.ClassMemberHelpContainer(...
                'classHelp', helpStr, classMetaData, ~onlyLocalHelp);

            this = this@matlab.lang.internal.introspective.containers.abstractHelpContainer(mFileName, filePath, mainHelpContainer);

            this.minimalPath = matlab.lang.internal.introspective.minimizePath(filePath, false);

            this.classInfo = ci;
            this.superClassList = strjoin({classMetaData.SuperclassList.Name}, ' & ');

            this.onlyLocalHelp = onlyLocalHelp;
            if onlyLocalHelp
                this.noSuperClassHelp = true;
            else
                this.noSuperClassHelp = noSuperClassHelp;
            end

            this.buildMethodHelpContainers;
            this.buildSimpleElementHelpContainers;
        end

        %% ---------------------------------
        function elementIterator = getSimpleElementIterator(this, elementKeyword)
            % GETSIMPLEELEMENTITERATOR - returns iterator for simple help objects
            elementIterator = matlab.lang.internal.introspective.containers.ClassMemberIterator(this.SimpleElementHelpContainers.(elementKeyword));
        end

        %% ---------------------------------
        function methodIterator = getMethodIterator(this)
            % GETMETHODITERATOR - returns iterator for method help objects
            methodIterator = matlab.lang.internal.introspective.containers.ClassMemberIterator(this.MethodHelpContainers, this.AbstractHelpContainers);
        end

        %% ---------------------------------
        function methodIterator = getConcreteMethodIterator(this)
            % GETCONCRETEMETHODITERATOR - returns iterator for non-abstract method help objects
            methodIterator = matlab.lang.internal.introspective.containers.ClassMemberIterator(this.MethodHelpContainers);
        end

        %% ---------------------------------
        function methodIterator = getAbstractMethodIterator(this)
            % GETABSTRACTMETHODITERATOR - returns iterator for abstract method help objects
            methodIterator = matlab.lang.internal.introspective.containers.ClassMemberIterator(this.AbstractHelpContainers);
        end

        %% ---------------------------------
        function constructorIterator = getConstructorIterator(this)
            % GETCONSTRUCTORITERATOR - returns iterator for constructor helpContainer
            constructors = dictionary;
            constructorHelpContainer = this.getConstructorHelpContainer;

            if ~isempty(constructorHelpContainer)
                constructors(this.classInfo.className) = constructorHelpContainer;
            end

            constructorIterator = matlab.lang.internal.introspective.containers.ClassMemberIterator(constructors);
        end
        %% ---------------------------------
        function conHelp = getConstructorHelpContainer(this)
            % GETCONSTRUCTORHELPOBJ - returns constructor help container object
            conHelp = this.ConstructorHelpContainer;
        end

        %% ---------------------------------
        function elementHelpContainer = getSimpleElementHelpContainer(this, elementKeyword, elementName)
            % GETSIMPLEELEMENTHELPCONTAINER - returns help container object for simple element
            elementHelpContainer = getMemberHelpContainer(this.SimpleElementHelpContainers.(elementKeyword), elementName);
        end

        %% ---------------------------------
        function methodHelpContainer = getMethodHelpContainer(this, methodName)
            % GETMETHODHELPCONTAINER - returns the help container object for method
            try
                methodHelpContainer = getMemberHelpContainer(this.MethodHelpContainers, methodName);
            catch %#ok<CTCH>
                methodHelpContainer = getMemberHelpContainer(this.AbstractHelpContainers, methodName);
            end
        end

        %% ---------------------------------
        function result = hasNoHelp(this)
            % ClassHelpContainer is considered empty if all of the
            % following have null help comments:
            % - Main class
            % - Constructor
            % - All properties and methods
            result = hasNoHelp@matlab.lang.internal.introspective.containers.abstractHelpContainer(this);
            result = result && hasNoMemberHelp(this.getMethodIterator);
            for elementType = matlab.lang.internal.introspective.getSimpleElementTypes
                result = result && hasNoMemberHelp(this.getSimpleElementIterator(elementType.keyword));
            end
        end

        %% ---------------------------------
        function list = getHelpTopics(this)
            className = string(this.mainHelpContainer.Name);
            list = strings(0);
            if ~this.mainHelpContainer.hasNoHelp
                list(end+1) = className;
            end
            list = [list, getMemberTopicList(className, this.getMethodIterator)];
            for elementType = matlab.lang.internal.introspective.getSimpleElementTypes
                list = [list, getMemberTopicList(className, this.getSimpleElementIterator(elementType.keyword))]; %#ok<AGROW>
            end
        end

        %% ---------------------------------
        function result = hasAbstractHelp(this)
            % hasAbstractHelp - returns true if there is abstract method
            % help for this class.
            result = ~hasNoMemberHelp(this.getAbstractMethodIterator);
        end

        %% ---------------------------------
        function result = isClassHelpContainer(this) %#ok<MANU>
            % ISCLASSHELPCONTAINER - returns true because object is of
            % type ClassHelpContainer
            result = true;
        end
    end

    methods (Access = private)
        %% ---------------------------------
        function buildSimpleElementHelpContainers(this)
            % BUILDSIMPLEELEMENTHELPCONTAINERS - initializes the struct
            % SimpleElementHelpContainers to store all the
            % ClassMemberHelpContainer objects for simple elements that meet the
            % requirements as specified in the
            % matlab.lang.internal.introspective.containers.HelpContainerFactory help comments.

            this.buildSimpleElementHelpContainer(this.mainHelpContainer.metaData.PropertyList, 'properties', this.noSuperClassHelp);
            this.buildSimpleElementHelpContainer(this.mainHelpContainer.metaData.EventList, 'events', this.noSuperClassHelp);
            this.buildSimpleElementHelpContainer(this.mainHelpContainer.metaData.EnumerationMemberList, 'enumeration', false);
        end

        function buildSimpleElementHelpContainer(this, metaData, elementKeyword, skipInherited)
            metaData = cullMetaData(metaData, elementKeyword);

            if ~isempty(metaData) && skipInherited
                % Remove any elements inherited from super classes
                metaData(arrayfun(@(c)~strcmp(c.DefiningClass.Name, this.mFileName), metaData)) = [];
            end

            this.SimpleElementHelpContainers.(elementKeyword) = this.getClassMembersContainer(elementKeyword, metaData);
        end

        %% ---------------------------------
        function buildMethodHelpContainers(this)
            % BUILDMETHODHELPCONTAINERS - does 2 things:
            %    1. Creates the dictionary MethodHelpContainers storing all
            %    the method ClassMemberHelpContainers.
            %    2. Creates the dictionary AbstractHelpContainers storing
            %    all the abstract method ClassMemberHelpContainers.
            %    3. Invokes buildConstructorHelpContainer to build a
            %    ClassMemberHelpContainer object for the constructor.
            %
            % Remark:
            % Refer to matlab.lang.internal.introspective.containers.HelpContainerFactory help for details on
            % requirements for methods that give rise to
            % ClassMemberHelpContainer objects.

            % enable the directory hashtable
            this.cacheCleanup = matlab.lang.internal.introspective.cache.enable;

            methodMetaData = cullMetaData(this.mainHelpContainer.metaData.MethodList, 'methods');

            constructorMeta = methodMetaData(strcmp({methodMetaData.Name}, regexp(this.mFileName, '\w+$', 'match', 'once')));

            this.buildConstructorHelpContainer(constructorMeta);

            superConstructorIndices = arrayfun(@(c)~strcmp(c.Name, regexp(c.DefiningClass.Name, '\w+$', 'match', 'once')), methodMetaData);

            methodMetaData = methodMetaData(superConstructorIndices);

            if this.noSuperClassHelp
                % remove all inherited methods
                methodMetaData(arrayfun(@(c)~strcmp(c.DefiningClass.Name, this.mFileName), methodMetaData)) = [];
            end

            % get abstract methods out before local methods are removed
            % since abstract methods are not recognized by which -subfun
            abstractIndices = [methodMetaData.Abstract];
            abstractMetaData = methodMetaData(abstractIndices);
            methodMetaData(abstractIndices) = [];

            if this.onlyLocalHelp
                classMethodNames = which('-subfun', this.minimalPath);
                [~, className] = fileparts(this.minimalPath);
                localMethods = extractAfter(classMethodNames, className + ".");

                % remove non-local methods
                [~, ia] = intersect({methodMetaData.Name}, localMethods);
                methodMetaData = methodMetaData(ia');
            end

            this.MethodHelpContainers = this.getClassMembersContainer('methods', methodMetaData);
            this.AbstractHelpContainers = this.getClassMembersContainer('methods', abstractMetaData);
        end

        %% ---------------------------------
        function classMemberContainer = getClassMembersContainer(this, memberKeyword, memberMetaArray)
            % getClassMembersContainer - returns a 1x1 struct storing all the
            % ClassMemberHelpContainer objects individually as fields.

            classMemberContainer = dictionary;

            for memberMeta = memberMetaArray
                memberHelp = this.getMemberHelp(memberKeyword, memberMeta);
                memberName = memberMeta.Name;

                classMemberContainer(memberName) = ...
                    matlab.lang.internal.introspective.containers.ClassMemberHelpContainer(memberKeyword, ...
                    memberHelp, memberMeta, ~this.onlyLocalHelp);
            end
        end

        %% ---------------------------------
        function buildConstructorHelpContainer(this, constructorMeta)
            % BUILDCONSTRUCTORHELPOBJ - initializes constructor help
            % container object
            if ~isempty(constructorMeta)
                constructorMeta = constructorMeta(1);
                constructorHelp = this.getMemberHelp('constructor', constructorMeta);
                this.ConstructorHelpContainer = ...
                    matlab.lang.internal.introspective.containers.ClassMemberHelpContainer('constructor', ...
                    constructorHelp, constructorMeta, ~this.onlyLocalHelp);
            else
                % create empty ClassMemberHelpContainer array
                this.ConstructorHelpContainer = matlab.lang.internal.introspective.containers.ClassMemberHelpContainer;
                this.ConstructorHelpContainer(end) = [];
            end
        end

        %% ---------------------------------
        function helpStr = getMemberHelp(this, memberKeyword, memberMeta)
            % GETMEMBERHELP - this function centralizes all the methods of
            % extracting help for a particular class member.
            isConstructor = false;
            switch memberKeyword
            case 'methods'
                elementInfo = this.classInfo.getMethodInfo(memberMeta, ~this.onlyLocalHelp);

            case {'properties', 'events', 'enumeration'}
                elementInfo = this.classInfo.getSimpleElementInfo(memberMeta, memberKeyword, ~this.onlyLocalHelp);

            case 'constructor'
                elementInfo = this.classInfo.getConstructorInfo(false);
                isConstructor = true;
            end

            if ~isempty(elementInfo)
                if ~isConstructor
                    elementInfo.inheritHelp = ~this.noSuperClassHelp;
                end
                helpStr = elementInfo.getHelp(~this.onlyLocalHelp);
                if ~this.noSuperClassHelp && helpStr == ""
                    helpStr = elementInfo.getDescription(~this.onlyLocalHelp);
                end
            else
                % True for built-in class members.
                % Eg: RandStream.advance method
                helpStr = '';
            end
        end
    end
end

%% ---------------------------------
function memberHelpContainer = getMemberHelpContainer(memberContainer, memberName)
    % GETMEMBERHELPCONTAINER - helper function to retrieve specific help
    % container for a class member
    if memberContainer.isConfigured && isKey(memberContainer, memberName)
        memberHelpContainer = memberContainer(memberName);
    else
        error(message('MATLAB:introspective:classHelpContainer:UndefinedClassMember', mat2str( memberName )));
    end

end

%% ---------------------------------
function metaData = cullMetaData(metaData, elementKeyword)
    % CULLMETADATA - filters out members that are private:

    metaData = metaData';
    metaData(arrayfun(@(c)~matlab.lang.internal.introspective.isAccessible(c, elementKeyword), metaData)) = [];
    [~, uniqueIndices] = unique({metaData.Name});
    metaData = metaData(uniqueIndices);
end

%% ---------------------------------
function result = hasNoMemberHelp(memberIterator)
    % HASNOMEMBERHELP - given an iterator to class member help
    % containers, hasNoMemberHelp returns false if at least one of the
    % class members has non-null help.  It returns true otherwise.
    result = true;

    while memberIterator.hasNext
        memberHelpContainer = memberIterator.next;

        if memberHelpContainer.getH1Line ~= ""
            result = false;
            return;
        end
    end
end

%% ---------------------------------
function list = getMemberTopicList(className, memberIterator)
    list = strings(0);

    while memberIterator.hasNext
        memberHelpContainer = memberIterator.next;
        if ~memberHelpContainer.hasNoHelp
            list(end+1) = className + "/" + memberHelpContainer.Name; %#ok<AGROW>
        end
    end
end
