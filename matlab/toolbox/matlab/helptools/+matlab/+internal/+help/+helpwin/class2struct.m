classdef (Hidden) class2struct
    % CLASS2STRUCT a helper class used to export class metadata and help to
    % structured data used by helpwin.
    
    % Copyright 2020-2022 The MathWorks, Inc.
    properties (Access=private)
        helpContainer;
        classMetaData;
        commandOption;
    end
    
    methods
        function this = class2struct(helpContainer, commandOption)
            % CLASS2STRUCT constructor takes two input arguments:
            % a class file HelpContainerFactory object
            % a command option used when building matlab: links on the page
            this.helpContainer = helpContainer;            
            this.classMetaData = helpContainer.mainHelpContainer.metaData;
            this.commandOption = fixCommandOption(commandOption);
        end
        
        function class_struct = buildClassStruct(this)
            % BUILDCLASSSTRUCT builds a structured data representation of a
            % class.
            classInfo = struct;
            
            % First get some basic attributes of the class.
            className = this.classMetaData.Name;
            atts = struct(...
                'name',className,...
                'hidden',mat2str(this.classMetaData.Hidden),...
                'sealed',mat2str(this.classMetaData.Sealed),...
                'constructonload',mat2str(this.classMetaData.ConstructOnLoad));

            classDetails = struct;
            classDetails.type = 'classdetails';
            classDetails.title = getString(message('MATLAB:helpUtils:class2json:ClassTitle'));

            % Build struct for superclasses, sealed, and constructonload.
            data = struct;

            if ~isempty(this.classMetaData.SuperClasses)                
                superclasses = struct;
                superclasses.type = 'superclasses';
                superclasses.title = 'Superclasses';                            
                superClassData = createSuperClassData(this.classMetaData, this.commandOption);
                superclasses.data = superClassData;
                data.superclasses = superclasses;            
            end            

            sealed = struct;
            sealed.type = 'sealed';
            sealed.title = 'Sealed';
            sealed.data = atts.sealed;            
            data.sealed = sealed;            

            constructonload = struct;
            constructonload.type = 'constructonload';
            constructonload.title = 'Construct on load';
            constructonload.data = atts.constructonload;            
            data.constructonload = constructonload;            

            classDetails.data = data;

            classInfo.classdetails = classDetails;

            %---------------- setup constructors ----------------            
            constructorIterator = this.helpContainer.getConstructorIterator();
            createConstructorParentHandle = @(~)createConstructorParentStruct();
            createConstructorMemberHandle = @(~, constructorMeta, commandOption)createConstructorMemberStruct(constructorMeta, commandOption);
            classConstructors = this.createClassMemberStruct(constructorIterator, this.commandOption, createConstructorMemberHandle, createConstructorParentHandle);
            classInfo.constructors = classConstructors;

            %---------------- setup simple elements -------------
            classProperties = this.createSimpleElementStruct('properties', this.commandOption, @createPropertyStruct);
            classInfo.properties = classProperties;                
            classEvents = this.createSimpleElementStruct('events', this.commandOption, @createEventStruct);
            classInfo.events = classEvents;      
            classEnumeration = this.createSimpleElementStruct('enumeration', this.commandOption, @createEnumerationStruct);
            classInfo.enumeration = classEnumeration;                      

            %---------------- setup methods ---------------------
            methodIterator = this.helpContainer.getMethodIterator();
            createMethodParentHandle = @(~)createMethodParentStruct();
            createMethodMemberHandle = @(classMetaData, metaMethod, commandOption)createMethodMemberStruct(classMetaData, metaMethod, commandOption);
            classMethods = this.createClassMemberStruct(methodIterator, this.commandOption, createMethodMemberHandle, createMethodParentHandle);            
            classInfo.methods = classMethods;    
                
            class_struct = classInfo;            
        end        
    end
    
    methods (Static)
        function constructor_struct = buildConstructorStruct(constructorMeta, commandOption)
            % BUILDCONSTRUCTORSTRUCT - builds a structured data 
            % representation of a class constructor.            
            constructorStruct = createConstructorParentStruct();
            dataStruct = createConstructorMemberStruct(constructorMeta, commandOption);            
            constructorStruct.data = num2cell(dataStruct);
            constructor_struct = constructorStruct;                        
        end

        function method_struct = buildMethodStruct(classMetaData, metaMethod, commandOption)
            % BUILDMETHODSTRUCT - builds a structured data 
            % representation of a class method.                        
            methodStruct = createMethodParentStruct();
            dataStruct = createMethodMemberStruct(classMetaData, metaMethod, commandOption);            
            methodStruct.data = num2cell(dataStruct);
            method_struct = methodStruct;                                        
        end

        function class_struct = buildPropertyStruct(classMetaData, propMeta, commandOption)
            % BUILDPROPERTYSTRUCT - builds a structured data 
            % representation of a class property.            
            classInfo = struct;            
            
            propertyStruct = struct;
            propertyStruct.type = 'properties';
            propertyStruct.title = getString(message('MATLAB:helpUtils:class2json:TitleDetailsproperties'));            
            propertyStruct.renderdetails = true;            
            
            dataStruct = createPropertyStruct(classMetaData, propMeta, commandOption);            
            propertyStruct.data = num2cell(dataStruct);
            
            classInfo.properties = propertyStruct;
            
            class_struct = classInfo;                                        
        end

        function class_struct = buildEventStruct(classMetaData, eventMeta, commandOption)
            % BUILDEVENTSTRUCT - builds a structured data 
            % representation of a class event.            
            classInfo = struct;            
            
            eventStruct = struct;
            eventStruct.type = 'events';
            eventStruct.title = getString(message('MATLAB:helpUtils:class2json:TitleDetailsevents'));            
            eventStruct.renderdetails = true;            
            
            dataStruct = createEventStruct(classMetaData, eventMeta, commandOption);            
            eventStruct.data = num2cell(dataStruct);
            
            classInfo.events = eventStruct;
            
            class_struct = classInfo;                                        
        end

        function class_struct = buildEnumerationStruct(classMetaData, enumMeta, commandOption)
            % BUILDENUMERATIONSTRUCT - builds a structured data 
            % representation of a class enumeration.            
            classInfo = struct;            
            
            enumerationStruct = struct;
            enumerationStruct.type = 'enumeration';
            enumerationStruct.title = getString(message('MATLAB:helpUtils:class2json:TitleDetailsenumeration'));            
            enumerationStruct.renderdetails = true;            
            
            dataStruct = createEnumerationStruct(classMetaData, enumMeta, commandOption);            
            enumerationStruct.data = num2cell(dataStruct);
            
            classInfo.enumeration = enumerationStruct;
            
            class_struct = classInfo;                                        
        end        
    end
    
    methods (Access=private)
        
        function member_struct = createSimpleElementStruct(this, elementKeyword, commandOption, createMemberStructHandle)
            % CREATESIMPLEELEMENTSTRUCT - creates a struct for a simple
            % element.            
            memberIterator = this.helpContainer.getSimpleElementIterator(elementKeyword);
            if memberIterator.hasNext
                memberStruct = this.createSimpleElementParentStruct(elementKeyword);            
                dataStruct = this.createStructForChildren(memberIterator, commandOption, createMemberStructHandle);
                memberStruct.data = num2cell(dataStruct);
            else
                memberStruct = struct;
            end            
            
            member_struct = memberStruct;
        end
        
        function parent_struct = createSimpleElementParentStruct(~, elementKeyword)
            % CREATESIMPLEELEMENTPARENTSTRUCT - creates a struct for the 
            % parent to a simple element.
            parentStruct = struct;
            parentStruct.type = elementKeyword;            
            parentStruct.title = getString(message(['MATLAB:helpUtils:class2json:Title',elementKeyword]));  
            parentStruct.rendersummary = true;
            parent_struct = parentStruct;                        
        end        

        function member_struct = createClassMemberStruct(this, memberIterator, commandOption, createMemberStructHandle, createParentStructHandle)
            % CREATECLASSMEMBERSTRUCT - Creates a struct for a class
            % member. i.e. methods and properties.            
            memberStruct = createParentStructHandle(this.classMetaData);

            if memberIterator.hasNext
                dataStruct = this.createStructForChildren(memberIterator, commandOption, createMemberStructHandle);
            else
                dataStruct = struct;
            end
            
            memberStruct.data = num2cell(dataStruct);
            member_struct = memberStruct;
        end
        
        function structs_for_children = createStructForChildren(this, memberIterator, commandOption, createMemberStructHandle)
            % CREATESTRUCTFORCHILDREN - iterates through all the class
            % member help containers creating a struct for each
            % object through the method CREATECHILDSTRUCT.            
            structsForChildren = struct('name',{},'link',{},'attributes',{},'helpStr',{},'h1Flag',{});
                                    
            while memberIterator.hasNext()
                memberHelpContainerObj = memberIterator.next();  
                memberStruct = createChildStruct(this, memberHelpContainerObj, commandOption, createMemberStructHandle);
                structsForChildren(end+1) = memberStruct;                
            end
            
            structs_for_children = structsForChildren;
        end
        
        function member_struct = createChildStruct(this, memberHelpContainerObj, commandOption, createMemberStructHandle)
            % CREATECHILDSTRUCT - takes a class member help container 
            % object and creates a struct.
            memberStruct = createMemberStructHandle(this.classMetaData, memberHelpContainerObj.metaData, commandOption);            
            helpStr = memberHelpContainerObj.getHelp;            
            h1Flag = ~this.helpContainer.onlyLocalHelp;            
            if h1Flag
                helpStr = matlab.internal.help.extractPurposeFromH1(helpStr, memberHelpContainerObj.Name);
            end
            memberStruct.helpStr = matlab.internal.help.fixsymbols(helpStr);
            memberStruct.h1Flag = h1Flag; 
            member_struct = memberStruct;
        end
        
    end
end

function parent_struct = createConstructorParentStruct()
    % CREATECONSTRUCTORPARENTSTRUCT - creates a struct for the class
    % parent constructor.
    parentStruct = struct;
    parentStruct.type = 'constructors';
    parentStruct.title = getString(message('MATLAB:helpUtils:class2json:ConstructorTitle'));
    parent_struct = parentStruct;                        
end

function parent_struct = createMethodParentStruct()
    % CREATEMETHODPARENTSTRUCT - creates a struct for the class
    % parent methods.
    parentStruct = struct;
    parentStruct.type = 'methods';
    parentStruct.title = getString(message('MATLAB:helpUtils:class2json:MethodTitle'));
    parent_struct = parentStruct;                        
end

function constructor_struct = createConstructorMemberStruct(constructorMeta, commandOption)
    % CREATECONSTRUCTORMEMBERSTRUCT - creates a struct for the class member
    % constructors.    
    constructorStruct = struct;
    constructorStruct.name = constructorMeta.Name;
    commandArg = strcat(constructorMeta.DefiningClass.Name, '.', constructorMeta.Name);
    constructorLink = formatMatlabLink(commandOption, commandArg, constructorMeta.Name);
    constructorStruct.link = constructorLink;
    constructorStruct.attributes = '';
    constructor_struct = constructorStruct;
end

function method_struct = createMethodMemberStruct(classMetaData, metaMethod, commandOption)
    % CREATEMETHODMEMBERSTRUCT - creates a struct for the class member
    % methods.
    methodStruct = struct;
    
    methodStruct.name = metaMethod.Name;
    definingclass = metaMethod.DefiningClass.Name;
    if (metaMethod.DefiningClass ~= classMetaData)
        definingclass = classMetaData.Name;
    end

    commandArg = strcat(definingclass, '.', metaMethod.Name);
    methodLink = formatMatlabLink(commandOption, commandArg, metaMethod.Name);
    methodStruct.link = methodLink;
    attributes = createMethodAttributes(metaMethod);
    methodStruct.attributes = attributes;
    
    method_struct = methodStruct;    
end

function method_attributes = createMethodAttributes(metaMethod)
    % CREATEMETHODATTRIBUTES - helper function that creates class
    % method attributes.
    methodAttributes = '';
    
    atts = struct(...
        'access', mat2accStr(metaMethod.Access),...
        'static', mat2str(metaMethod.Static),...
        'abstract', mat2str(metaMethod.Abstract),...
        'sealed', mat2str(metaMethod.Sealed));

    if ~strcmp(atts.access,'public')
        methodAttributes = atts.access;
    end

    if strcmp(atts.static,'true')
        methodAttributes = [methodAttributes,' ','Static'];
    end

    if strcmp(atts.abstract,'true')
        methodAttributes = [methodAttributes,' ','Abstract'];
    end

    if strcmp(atts.sealed,'true')
        methodAttributes = [methodAttributes,' ','Sealed'];
    end        
    
    method_attributes = methodAttributes;
end

function property_struct = createPropertyStruct(classMetaData,metaProperty,commandOption)
    % CREATEPROPERTYSTRUCT - creates a struct for the class member
    % properties.    
    propertyStruct = struct;

    propertyStruct.name = metaProperty.Name;
    definingclass = metaProperty.DefiningClass.Name;
    if (metaProperty.DefiningClass ~= classMetaData)
        definingclass = classMetaData.Name;
    end

    commandArg = strcat(definingclass, '.', metaProperty.Name);
    propertyLink = formatMatlabLink(commandOption, commandArg, metaProperty.Name);
    propertyStruct.link = propertyLink;
    attributes = createPropertyAttributes(metaProperty);
    propertyStruct.attributes = attributes;
        
    property_struct = propertyStruct;
end

function property_attributes = createPropertyAttributes(metaProperty)
    % CREATEPROPERTYATTRIBUTES - helper function that creates class
    % property attributes.
    propertyAttributes = struct;
    
    atts = struct(...
        'name', metaProperty.Name,...
        'getaccess', mat2accStr(metaProperty.GetAccess),...
        'setaccess', mat2accStr(metaProperty.SetAccess),...
        'sealed', mat2str(metaProperty.Sealed),...
        'dependent', mat2str(metaProperty.Dependent),...
        'constant', mat2str(metaProperty.Constant),...
        'abstract', mat2str(metaProperty.Abstract),...
        'transient', mat2str(metaProperty.Transient),...
        'hidden', mat2str(metaProperty.Hidden),...
        'getobservable', mat2str(metaProperty.GetObservable),...
        'setobservable', mat2str(metaProperty.SetObservable));
                
        constant = struct;
        constant.type = 'constant';
        constant.title = 'Constant';
        constant.data = atts.constant; 
        propertyAttributes.constant = constant;

        dependent = struct;
        dependent.type = 'dependent';
        dependent.title = 'Dependent';
        dependent.data = atts.dependent; 
        propertyAttributes.dependent = dependent;
        
        sealed = struct;
        sealed.type = 'sealed';
        sealed.title = 'Sealed';
        sealed.data = atts.sealed; 
        propertyAttributes.sealed = sealed;

        transient = struct;
        transient.type = 'transient';
        transient.title = 'Transient';
        transient.data = atts.transient; 
        propertyAttributes.transient = transient;
        
        getaccess = struct;
        getaccess.type = 'getaccess';
        getaccess.title = 'GetAccess';
        getaccess.data = atts.getaccess; 
        propertyAttributes.getaccess = getaccess;

        setaccess = struct;
        setaccess.type = 'setaccess';
        setaccess.title = 'SetAccess';
        setaccess.data = atts.setaccess; 
        propertyAttributes.setaccess = setaccess;        
        
        getobservable = struct;
        getobservable.type = 'getobservable';
        getobservable.title = 'GetObservable';
        getobservable.data = atts.getobservable; 
        propertyAttributes.getobservable = getobservable;

        setobservable = struct;
        setobservable.type = 'setobservable';
        setobservable.title = 'SetObservable';
        setobservable.data = atts.setobservable; 
        propertyAttributes.setobservable = setobservable;        
    
    property_attributes = propertyAttributes;
end

function event_struct = createEventStruct(classMetaData,metaEvent,commandOption)
    % CREATEEVENTSTRUCT - creates a struct for the class member
    % events.    
    eventStruct = struct;

    eventStruct.name = metaEvent.Name;    
    definingclass = metaEvent.DefiningClass.Name;
    if (metaEvent.DefiningClass ~= classMetaData)
        definingclass = classMetaData.Name;
    end
    
    commandArg = strcat(definingclass, '.', metaEvent.Name);
    propertyLink = formatMatlabLink(commandOption, commandArg, metaEvent.Name);
    eventStruct.link = propertyLink;
    attributes = createEventAttributes(metaEvent);
    eventStruct.attributes = attributes;
        
    event_struct = eventStruct;
end

function event_attributes = createEventAttributes(metaEvent)
    % CREATEEVENTATTRIBUTES - helper function that creates class
    % event attributes.
    eventAttributes = struct;
    
    atts = struct(...
        'name', metaEvent.Name,...
        'notifyaccess', mat2accStr(metaEvent.NotifyAccess),...
        'listenaccess', mat2accStr(metaEvent.ListenAccess),...
        'hidden', mat2str(metaEvent.Hidden));

    listenaccess = struct;
    listenaccess.type = 'listenaccess';
    listenaccess.title = 'ListenAccess';
    listenaccess.data = atts.listenaccess; 
    eventAttributes.listenaccess = listenaccess;        

    notifyaccess = struct;
    notifyaccess.type = 'notifyaccess';
    notifyaccess.title = 'NotifyAccess';
    notifyaccess.data = atts.notifyaccess; 
    eventAttributes.notifyaccess = notifyaccess;
        
    event_attributes = eventAttributes;
end

function enumeration_struct = createEnumerationStruct(classMetaData,metaEnumeration,commandOption)
    % CREATEENUMERATIONSTRUCT - creates a struct for the class member
    % enumerations.    
    enumeratonStruct = struct;
    
    enumeratonStruct.name = metaEnumeration.Name;
    definingclass = classMetaData.Name;
    commandArg = strcat(definingclass, '.', metaEnumeration.Name);
    propertyLink = formatMatlabLink(commandOption, commandArg, metaEnumeration.Name);
    enumeratonStruct.link = propertyLink;
    attributes = struct;
    enumeratonStruct.attributes = attributes;   
    
    enumeration_struct = enumeratonStruct;
end

function super_class_data = createSuperClassData(meta, commandOption)
    % CREATESUPERCLASSDATA - helper function that creates super class
    % information for the class.    
    superClassData = '';
 
    supercls = meta.SuperClasses;
    if ~isempty(supercls)
        for j = 1:length(supercls)
            super = supercls{j}; 
            superClassLink = formatMatlabLink(commandOption, super.Name, super.Name);
            superClassData = [superClassData, ', ', superClassLink];
        end
    end
    
    if ~isempty(superClassData)
        % remove the leading ', '
        superClassData = superClassData(3:end);
    end
    
    super_class_data = superClassData;
end

function matlab_link = formatMatlabLink(command, arg, text)
    % FORMATMATLABLINK - helper function that formats a matlab: link.    
    matlab_link = matlab.internal.help.createMatlabLink(command, arg, text);
end

function str = mat2accStr(accMat)
    % MAT2ACCSTR - helper function to produce an access string from
    % an access attribute value.
    if isa(accMat, 'char')
        str = accMat;
    elseif isempty(accMat)
        str = 'private';
    elseif isa(accMat, 'cell') 
        cnames = cell(length(accMat), 1);
        for k = 1:length(accMat)
            if isa(accMat{k}, 'meta.class')
                cnames{k} = accMat{k}.Name;
            end
        end
        str = sprintf('%s, ', cnames{:});
        str(end-1:end) = [];
    elseif isa(accMat, 'meta.class')
        str = accMat.Name;
    end
end

function str = fixCommandOption(commandOption)
    str = commandOption;
    if commandOption(1) == '-'
        str = commandOption(2:end);
    end
end
