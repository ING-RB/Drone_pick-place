classdef (Hidden) MockContext < handle
    % This class is undocumented and will change in a future release.
    
    % MockContext - Context to create mock objects.
    %
    %   Use MockContext to construct a mock object subclass for a
    %   specified class. The mock object subclass implements all abstract
    %   methods of the specified superclass with configurable behavior. The
    %   context also records information about interactions with the methods of
    %   the mock for later qualification.
    %
    %   By default, the mock object is tolerant, meaning that interactions with
    %   the mock object that have no predefined behavior return a value of []
    %   (empty double) for each output argument. Create a strict mock by
    %   specifying the Strict name/value pair. For a strict mock, interactions
    %   with the mock that have no predefined behavior produce an assertion
    %   failure.
    %
    %   MockContext methods:
    %       MockContext   - Class constructor
    %       constructMock - Construct mock object
    %
    %   MockContext properties:
    %       Strict                - Boolean indicating if the mock is strict or tolerant
    %       AddedMethods          - Methods added to the mock object
    %       AddedProperties       - Properties added to the mock object
    %       AddedEvents           - Events added to the mock object
    %       ConstructorInputs     - Cell array of input arguments passed to superclass constructor
    %       DefaultPropertyValues - Struct specifying property default values
    %       Behavior              - Object used to specify mock object behavior and verify interactions
    %       Mock                  - Mock object subclass instance
    %
    
    % Copyright 2015-2024 The MathWorks, Inc.
    
    properties (SetAccess=immutable)
        % Strict - Boolean indicating if the mock is strict or tolerant
        %
        %   The Strict property is a Boolean indicating if the mock is strict or
        %   tolerant. By default, the mock is tolerant. Set the value of the
        %   Strict property through the constructor using the Strict name/value
        %   pair.
        %
        Strict logical;
        
        % MockedMethods - Methods that can be mocked
        %
        %   The MockedMethods property is a string array representing the names of
        %   methods that can be mocked. By default, MockedMethods is the set of
        %   added methods, abstract superclass methods, and concrete superclass
        %   methods that are overridable. Set the value of MockedMethods through
        %   the MockContext constructor using the MockedMethods name/value pair.
        %   A value of <missing> indicates that the name/value pair was not
        %   explicitly specified.
        %
        MockedMethods string;
        
        % AddedMethods - Methods added to the mock object
        %
        %   The AddedMethods property is a string array representing the names of
        %   methods implemented by the mock object subclass. By default, the
        %   context adds no methods to the mock. Set the value of AddedMethods
        %   through the MockContext constructor using the AddedMethods name/value
        %   pair.
        AddedMethods string;
        
        % AddedProperties - Properties added to the mock object
        %
        %   The AddedProperties property is a string array representing the names
        %   of properties implemented by the mock object. By default, the context
        %   adds no properties to the mock object. Set the value of AddedProperties
        %   through the MockContext constructor using the AddedProperties
        %   name/value pair.
        AddedProperties string;
        
        % AddedEvents - Events added to the mock object
        %
        %   The AddedEvents property is a string array representing the names of
        %   events defined by the mock object. By default, the context adds no
        %   events to the mock object. Set the value of AddedEvents through the
        %   MockContext constructor using the AddedEvents name/value pair.
        AddedEvents string;
        
        % ConstructorInputs - Cell array of input arguments passed to superclass constructor
        %
        %   The ConstructorInputs property is a cell array of input arguments which
        %   are passed to the mock object's superclass constructor when
        %   constructing the mock object instance. By default, the context passes
        %   no arguments to the constructor. Set the value of the ConstructorInputs
        %   property through the MockContext constructor using the
        %   ConstructorInputs name/value pair.
        ConstructorInputs cell;
        
        % DefaultPropertyValues - Struct specifying property default values
        %
        %   The DefaultPropertyValues property is a scalar structure where each
        %   field refers to the name of a property implemented on the mock class,
        %   and the corresponding value represents the default value for that
        %   property.
        DefaultPropertyValues (1,1) struct
    end
    
    properties (SetAccess=private, Transient)
        % Behavior - Object used to specify mock object behavior and verify interactions
        %
        %   The Behavior is an object that implements all methods of the mock
        %   object for which behavior can be defined and interactions can be
        %   observed. Behavior methods return a MethodCallBehavior instance that is
        %   used to define behavior for mock object methods and properties. The
        %   MethodCallBehavior is also used to qualify mock object method and
        %   property interactions.
        %
        %   See also:
        %       matlab.mock.MethodCallBehavior
        Behavior;
        
        % Mock - Mock object subclass instance
        %
        %   The Mock instance performs behaviors and records interactions. The
        %   class of the Mock is a subclass of the class passed to the MockContext
        %   constructor.
        %
        Mock;
    end
    
    properties (Constant, Hidden)
        Parser (1,1) inputParser = createParser;
        BehaviorNamespace = "matlab.mock.classes";
        MockNamespace = "matlab.mock.classes";
        PrototypeNamespace = "matlab.mock.prototypes";
        IgnoredMethodAttributes = ["Abstract", "Access", "DefiningClass", "Description", "DetailedDescription", ...
            "ExplicitConversion", "Hidden", "InputNames", "Name", "OutputNames", "Sealed", "Static"];
        IgnoredPropertyAttributes = ["Abstract", "DefaultValue", "DefiningClass", "Dependent", "Description", ...
            "DetailedDescription", "GetAccess", "GetMethod", "HasDefault", "Name", "SetAccess", "SetMethod", "Validation"];
    end
    
    properties (Access=private, Transient)
        ClassContext matlab.mock.internal.ClassContext;
        StaticMethodNames (1,:) string;
        InteractionCatalog (1,1) matlab.mock.internal.InteractionCatalog;
    end
    
    properties (Access=private)
        SuperclassNames (1,:) string;
        ResolvedSuperclassNames (1,:) string;
    end

    properties (Access=private, WeakHandle)
        Assertable matlab.unittest.qualifications.Assertable;
    end
    
    properties (Access=private, Dependent)
        Superclasses (1,:) meta.class;
        MockedMethodsSpecified (1,1) logical;
    end

    properties (SetAccess=immutable, GetAccess=private)
        AbstractMethods (1,:) meta.method;
        AbstractProperties (1,:) meta.property;
        UseCustomMetaData (1,1) logical;
    end
    
    methods
        function context = MockContext(assertable, varargin)
            % MockContext - Class constructor
            %
            %   context = MockContext(assertable) constructs a mock context. The mock
            %   object has no superclasses, methods, properties, or events.
            %
            %   context = MockContext(assertable, ?MyClass) constructs a context that
            %   defines a mock subclass of MyClass.
            %
            %   context = MockContext(__, "Strict", true) constructs a
            %   context that defines a strict mock subclass of MyClass.
            %
            %   context = MockContext(__, "AddedMethods", ["method1", "method2", ...])
            %   constructs a context that adds method1, method2, etc. to the mock object.
            %
            %   context = MockContext(__, "AddedProperties", ["Prop1", "Prop2", ...])
            %   constructs a context that adds Prop1, Prop2, etc. to the mock object.
            %
            %   context = MockContext(__, "AddedEvents", ["Event1", "Event2", ...])
            %   constructs a context that adds Event1, Event2, etc. to the mock object.
            %
            %   context = MockContext(__, "ConstructorInputs", {in1, in2, ...})
            %   constructs a context that passes in1 as the first input, in2 as
            %   the second input, etc. to the MyClass constructor when constructing the
            %   MyClass mock object subclass instance.
            %
            %   context = MockContext(__, "DefaultPropertyValues,struct("Prop1",value1, "Prop2",value2, ...))
            %   constructs a context where property Prop1 is assigned a default value
            %   value1, property Prop2 is assigned a default value value2, etc.
            %
            
            import matlab.mock.internal.MockSuperclassAnalyzer;

            context.Assertable = assertable;
            
            parser = context.Parser;
            
            % onCleanup to avoid holding a reference to any DefaultPropertyValues handle objects
            c = onCleanup(@()parser.parse);
            parser.parse(varargin{:});
            
            metaclasses = parser.Results.Superclass;
            strict = parser.Results.Strict;
            mockedMethods = parser.Results.MockedMethods;
            addedMethods = parser.Results.AddedMethods;
            addedProperties = parser.Results.AddedProperties;
            addedEvents = parser.Results.AddedEvents;
            constructorInputs = parser.Results.ConstructorInputs;
            defaultPropertyValues = parser.Results.DefaultPropertyValues;

            [abstractMethods, abstractProperties] = MockSuperclassAnalyzer.getAbstractMembers(metaclasses);
            useCustomMetaData = any(arrayfun(@(cls)metaclass(cls) ~= ?meta.class, metaclasses));
            
            validateAbstractProperties(abstractProperties, useCustomMetaData);
            validateAbstractMethods(abstractMethods, useCustomMetaData);
            validateAddedMethodsValue(addedMethods, metaclasses);
            validateMockedMethodsValue(mockedMethods, addedMethods, metaclasses, abstractMethods, useCustomMetaData)
            validateAddedPropertiesValue(addedProperties, metaclasses);
            validateAddedEventsValue(addedEvents, metaclasses);
            defaultPropertyValues = validateDefaultPropertyValuesValue(defaultPropertyValues, addedProperties, abstractProperties);
            
            context.Superclasses = metaclasses;
            context.Strict = strict;
            context.MockedMethods = mockedMethods;
            context.AddedMethods = addedMethods;
            context.AddedEvents = addedEvents;
            context.AddedProperties = addedProperties;
            context.ConstructorInputs = constructorInputs;
            context.DefaultPropertyValues = defaultPropertyValues;

            context.AbstractMethods = abstractMethods;
            context.AbstractProperties = abstractProperties;
            context.UseCustomMetaData = useCustomMetaData;
        end
        
        function constructMock(context)
            import matlab.mock.internal.MockSuperclassAnalyzer;
            import matlab.mock.internal.UniqueMarker;
            import matlab.mock.internal.validateMethodAttributes;
            import matlab.mock.internal.validatePropertyAttributes;
            
            superClasses = context.Superclasses;
            
            overriddenConcreteMethods = MockSuperclassAnalyzer.getOverridableConcreteMethods(superClasses, context.UseCustomMetaData);
            mockedConcreteMethods = overriddenConcreteMethods;
            if context.MockedMethodsSpecified
                [~, idx] = intersect({mockedConcreteMethods.Name}, context.MockedMethods);
                mockedConcreteMethods = toRow(mockedConcreteMethods(idx));
            end
            
            mockObjectMethods = [mockedConcreteMethods, getAdditionalMethodsToOverrideButNotMock(superClasses)];
            
            mockMethodInfo = context.getMockMethodInformation(mockObjectMethods);
            behaviorMethodInfo = context.getBehaviorMethodInformation(mockedConcreteMethods);
            mockPropertyInfo = context.getMockPropertyInformation;
            behaviorPropertyInfo = context.getBehaviorPropertyInformation;
            
            marker = UniqueMarker;
            context.createCatalog(mockMethodInfo, mockPropertyInfo);
            
            context.createBehavior(marker, behaviorMethodInfo, behaviorPropertyInfo);
            context.defineDefaultActionsForOverriddenMethods(mockObjectMethods, mockedConcreteMethods);
            context.defineDefaultActionsForNewlyImplementedMethods;
            context.defineDefaultActionsForNewlyImplementedProperties(behaviorPropertyInfo);
            
            context.createMockObject(marker, mockMethodInfo, mockPropertyInfo);
            
            superclassMetaMethods = [context.AbstractMethods, mockedConcreteMethods];
            validateMethodAttributes(superclassMetaMethods, context.Mock, context.IgnoredMethodAttributes);
            
            validatePropertyAttributes(context.AbstractProperties, context.Mock, context.IgnoredPropertyAttributes);
            
            % For performance reasons, determine and store the list of static
            % method names for efficient lookup at mock method invocation time
            staticMethods = superclassMetaMethods.findobj("Static",true);
            context.StaticMethodNames = {staticMethods.Name};
        end
        
        function delete(context)
            context.InteractionCatalog.disableRecordTracking;
            context.InteractionCatalog.clearAllRecords;
            context.InteractionCatalog = matlab.mock.internal.InteractionCatalog;
            arrayfun(@destroyAllInstances, context.ClassContext);
        end
        
        function metaclasses = get.Superclasses(context)
            metaclasses = arrayfun(@meta.class.fromName, context.ResolvedSuperclassNames, ...
                "UniformOutput",false);
            metaclasses = toRow([meta.class.empty, metaclasses{:}]);
        end
        
        function set.Superclasses(context, metaclasses)
            context.SuperclassNames = {metaclasses.Name};
            context.ResolvedSuperclassNames = {metaclasses.ResolvedName};
        end

        function bool = get.MockedMethodsSpecified(context)
            bool = mockedMethodsSpecified(context.MockedMethods);
        end
    end
    
    methods (Access=private)
        function createCatalog(context, methodInfo, propertyInfo)
            import matlab.mock.internal.InteractionCatalog;
            
            mockClassName = context.createUniqueClassName(context.MockNamespace, "Mock");
            visibleMethodNames = [string.empty, methodInfo(~[methodInfo.Hidden]).Name];
            visiblePropertyNames = [string.empty, propertyInfo(~[propertyInfo.Hidden]).Name];
            context.InteractionCatalog = InteractionCatalog(mockClassName, visibleMethodNames, visiblePropertyNames); %#ok<CPROPLC>
        end
        
        function createBehavior(context, marker, methodInfo, propertyInfo)
            import matlab.mock.internal.ClassContext;
            import matlab.mock.internal.BehaviorRole;
            
            catalog = context.InteractionCatalog;
            behaviorClassName = context.createUniqueClassName(context.BehaviorNamespace, "Behavior");
            contextWeakRef = matlab.lang.WeakReference(context);
                
            classContext = ClassContext(context.BehaviorNamespace, behaviorClassName, ...
                string.empty, methodInfo, @(methodCallData)behaviorMethodCallback(methodCallData, catalog, contextWeakRef.Handle), ...
                propertyInfo, ...
                @(name, value)behaviorPropertyGetCallback(name,value,catalog), ...
                @behaviorPropertySetCallback, ...
                string.empty, BehaviorRole(marker, catalog)); %#ok<CPROPLC>
            context.ClassContext(end+1) = classContext;
            context.Behavior = classContext.createInstance;
        end
        
        function createMockObject(context, marker, methodInfo, propertyInfo)
            import matlab.mock.internal.ClassContext;
            import matlab.mock.internal.MockObjectRole;
            
            catalog = context.InteractionCatalog;
            className = catalog.MockObjectSimpleClassName;
            contextWeakRef = matlab.lang.WeakReference(context);

            classContext = ClassContext(context.MockNamespace, className, context.ResolvedSuperclassNames, ...
                methodInfo, @(methodCallData)mockMethodCallback(methodCallData, contextWeakRef.Handle, catalog, className), propertyInfo, ...
                @(name, obj)mockPropertyGetCallback(name, obj, className, catalog), ...
                @(name, obj, value) mockPropertySetCallback(name, obj, value, className, catalog), ...
                context.AddedEvents, MockObjectRole(marker, catalog)); %#ok<CPROPLC>
            context.ClassContext(end+1) = classContext;
            context.Mock = classContext.createInstance(context.ConstructorInputs{:});
        end

        function uniqueClassName = createUniqueClassName(context, namespace, roleName)
            import matlab.mock.internal.MockSuperclassAnalyzer;
            import matlab.unittest.internal.getSimpleParentName;

            existingClassNames = MockSuperclassAnalyzer.getExistingClassNames(namespace);
            className = "";
            if ~isempty(context.SuperclassNames)
                className = getSimpleParentName(context.SuperclassNames(1));
            end
            uniqueClassName = createName(className);
            
            function uniqueClassName = createName(shortClassName)
                import matlab.lang.makeUniqueStrings;
                
                desiredName = shortClassName + roleName;
                uniqueClassName = makeUniqueStrings(desiredName, existingClassNames, namelengthmax);
                
                % If the uniquely generated name doesn't contain the full
                % role name, try again with a shorter class name.
                if isempty(regexp(uniqueClassName, roleName + "(_\d*)?$", "once"))
                    shorterClassName = shortClassName.extractBefore(strlength(shortClassName));
                    uniqueClassName = createName(shorterClassName);
                end
            end
        end
        
        function defineDefaultActionsForNewlyImplementedMethods(context)
            import matlab.mock.MethodCallBehavior;
            import matlab.mock.AnyArguments;
            
            catalog = context.InteractionCatalog;
            
            for method = context.AbstractMethods
                when(MethodCallBehavior(catalog, method.Name, method.Static, {AnyArguments}), ...
                    context.getDefaultMethodCallActionFor(method.Name));
            end
            
            for methodName = context.AddedMethods
                when(MethodCallBehavior(catalog, methodName, false, {AnyArguments}), ...
                    context.getDefaultMethodCallActionFor(methodName));
            end
        end
        
        function varargout = produceAssertionFailure(context, msg) %#ok<STOUT>
            import matlab.unittest.internal.diagnostics.MessageDiagnostic;
            context.Assertable.assertFail(MessageDiagnostic(msg));
        end
        
        function action = getDefaultMethodCallActionFor(context, method)
            import matlab.mock.actions.Invoke;
            import matlab.mock.internal.actions.ReturnEmptyDouble;
            import matlab.mock.internal.actions.UnrecordedMethodCallActionDecorator;
            
            if context.Strict
                action = Invoke(@(varargin)context.produceAssertionFailure(message( ...
                    "MATLAB:mock:MockContext:UnexpectedMethodCallForStrictMock", method)));
            else
                action = ReturnEmptyDouble;
            end
            
            if context.MockedMethodsSpecified && ~ismember(method, context.MockedMethods)
                action = UnrecordedMethodCallActionDecorator(action);
            end
        end
        
        function defineDefaultActionsForNewlyImplementedProperties(context, propertyInfo)
            for property = propertyInfo
                propName = property.Name;
                when(get(context.Behavior.(propName)), ...
                    context.getDefaultPropertyGetActionFor(propName));
                when(set(context.Behavior.(propName)), ...
                    context.getDefaultPropertySetActionFor(propName));
            end
        end
        
        function action = getDefaultPropertyGetActionFor(context, property)
            import matlab.mock.internal.actions.Invoke;
            import matlab.mock.actions.ReturnStoredValue;
            
            if context.Strict
                action = Invoke(@(varargin)context.produceAssertionFailure(message( ...
                    "MATLAB:mock:MockContext:UnexpectedPropertyAccessForStrictMock", property)));
            else
                action = ReturnStoredValue;
            end
        end
        
        function action = getDefaultPropertySetActionFor(context, property)
            import matlab.mock.internal.actions.Invoke;
            import matlab.mock.actions.StoreValue;
            
            if context.Strict
                action = Invoke(@(varargin)context.produceAssertionFailure(message( ...
                    "MATLAB:mock:MockContext:UnexpectedPropertySetForStrictMock", property)));
            else
                action = StoreValue;
            end
        end
        
        function defineDefaultActionsForOverriddenMethods(context, overriddenConcreteMethods, mockedConcreteMethods)
            import matlab.mock.MethodCallBehavior;
            import matlab.mock.AnyArguments;
            import matlab.mock.internal.actions.CallSuperclass;
            import matlab.mock.internal.actions.UnrecordedMethodCallActionDecorator;
            
            catalog = context.InteractionCatalog;
            
            overriddenOnly = setdiff(overriddenConcreteMethods, mockedConcreteMethods);
            mocked = intersect(overriddenConcreteMethods, mockedConcreteMethods);
            
            for method = overriddenOnly
                action = UnrecordedMethodCallActionDecorator(CallSuperclass(method.DefiningClass));
                when(MethodCallBehavior(catalog, method.Name, false, {AnyArguments}), action);
            end
            
            for method = mocked
                action = CallSuperclass(method.DefiningClass);
                when(MethodCallBehavior(catalog, method.Name, false, {AnyArguments}), action);
            end
        end
        
        function bool = isStatic(context, methodName)
            bool = any(context.StaticMethodNames == methodName);
        end
        
        function info = getMethodInformation(context, overriddenConcreteMethods, mockedMethods, attributesToRespect)
            import matlab.mock.internal.MethodInformation;
            
            % Added methods have default values for all method attributes
            addedMethods = context.AddedMethods;
            if mockedMethodsSpecified(mockedMethods)
                addedMethods = intersect(addedMethods, mockedMethods);
            end
            addedMethods = arrayfun(@MethodInformation, addedMethods, "UniformOutput",false);
            
            abstractMethods = context.AbstractMethods;
            if mockedMethodsSpecified(mockedMethods)
                methodNames = {abstractMethods.Name};
                [~, idx] = intersect(methodNames, mockedMethods);
                abstractMethods = abstractMethods(idx);
            end
            superclassMethods = [abstractMethods, overriddenConcreteMethods];
            
            superclassMethodInfo = cell(1, numel(superclassMethods));
            for idx = 1:numel(superclassMethods)
                thisMetaMethod = superclassMethods(idx);
                thisMethodInfo = MethodInformation(thisMetaMethod.Name);
                
                % Match the attributes defined in the superclass
                for attribute = attributesToRespect
                    thisMethodInfo.(attribute) = thisMetaMethod.(attribute);
                end
                
                superclassMethodInfo{idx} = thisMethodInfo;
            end
            
            info = [MethodInformation.empty(1,0), addedMethods{:}, superclassMethodInfo{:}];
        end
        
        function info = getMockMethodInformation(context, overriddenConcreteMethods)
            mockedMethods = string(missing);
            attributesToRespect = ["Hidden", "Static", "ExplicitConversion"];
            info = context.getMethodInformation(overriddenConcreteMethods, mockedMethods, attributesToRespect);
        end
        
        function info = getBehaviorMethodInformation(context, overriddenConcreteMethods)
            mockedMethods = context.MockedMethods;
            attributesToRespect = ["Hidden", "Static"];
            info = context.getMethodInformation(overriddenConcreteMethods, mockedMethods, attributesToRespect);
        end
        
        function info = getMockPropertyInformation(context)
            import matlab.mock.internal.PropertyInformation;
            
            % Added properties have default values for all property attributes
            addedProperties = arrayfun(@PropertyInformation, context.AddedProperties, ...
                "UniformOutput",false);
            
            superclassProperties = context.AbstractProperties;
            superclassPropertyInfo = cell(1, numel(superclassProperties));
            for idx = 1:numel(superclassProperties)
                thisMetaProperty = superclassProperties(idx);
                thisPropertyName = thisMetaProperty.Name;
                thisPropertyInfo = PropertyInformation(thisPropertyName);
                
                % Match the attributes defined in the superclass
                thisPropertyInfo.Transient = thisMetaProperty.Transient;
                thisPropertyInfo.Hidden = thisMetaProperty.Hidden;
                thisPropertyInfo.GetObservable = thisMetaProperty.GetObservable;
                thisPropertyInfo.SetObservable = thisMetaProperty.SetObservable;
                thisPropertyInfo.AbortSet = thisMetaProperty.AbortSet;
                thisPropertyInfo.NonCopyable = thisMetaProperty.NonCopyable;
                thisPropertyInfo.PartialMatchPriority = thisMetaProperty.PartialMatchPriority;
                thisPropertyInfo.NeverAmbiguous = thisMetaProperty.NeverAmbiguous;
                
                superclassPropertyInfo{idx} = thisPropertyInfo;
            end
            
            info = [PropertyInformation.empty(1,0), addedProperties{:}, superclassPropertyInfo{:}];
            
            % Assign default values
            defaultPropertyNames = fieldnames(context.DefaultPropertyValues);
            defaultPropertyValues = struct2cell(context.DefaultPropertyValues);
            [~, infoIdx, propIdx] = intersect([info.Name], defaultPropertyNames);
            defaultPropertyValues = defaultPropertyValues(propIdx);
            [info(infoIdx).DefaultValue] = defaultPropertyValues{:};
        end
        
        function info = getBehaviorPropertyInformation(context)
            import matlab.mock.internal.PropertyInformation;
            
            % Added properties have default values for all property attributes
            addedProperties = arrayfun(@PropertyInformation, context.AddedProperties, ...
                "UniformOutput",false);
            
            superclassProperties = context.AbstractProperties.findobj("Constant",false);
            superclassPropertyInfo = cell(1, numel(superclassProperties));
            for idx = 1:numel(superclassProperties)
                thisMetaProperty = superclassProperties(idx);
                thisPropertyName = thisMetaProperty.Name;
                thisPropertyInfo = PropertyInformation(thisPropertyName);
                
                % Match the attributes defined in the superclass
                thisPropertyInfo.Hidden = thisMetaProperty.Hidden;
                
                superclassPropertyInfo{idx} = thisPropertyInfo;
            end
            
            info = [PropertyInformation.empty(1,0), addedProperties{:}, superclassPropertyInfo{:}];
        end
    end
end

function behaviorMethodCallback(methodCallData, catalog, context)
    import matlab.mock.MethodCallBehavior;
    
    methodName = methodCallData.Name;
    inputs = methodCallData.Inputs;
    
    validateAnyArgumentsUsage(inputs);
    validateBehaviorUsage(methodName, inputs);
    validateScalarBehavior(methodName, inputs);
    
    methodCallData.Outputs{1} = MethodCallBehavior(catalog, methodName, ...
        context.isStatic(methodName), inputs);
    methodCallData.ReturnAns = true;
end

function behavior = behaviorPropertyGetCallback(name, ~, catalog)
    import matlab.mock.PropertyBehavior;
    behavior = PropertyBehavior(catalog, name);
end

function behaviorPropertySetCallback(~, ~, ~)
    error(message("MATLAB:mock:MockContext:ModifyProperties", "Behavior"));
end

function mockMethodCallback(methodCallData, context, catalog, className)
    import matlab.mock.history.MethodCall;
    import matlab.mock.history.SuccessfulMethodCall;
    import matlab.mock.history.UnsuccessfulMethodCall;

    methodName = methodCallData.Name;
    static = context.isStatic(methodName);
    inputs = methodCallData.Inputs;
    numOutputs = methodCallData.NumOutputs;

    lookup = MethodCall(className, methodName, static, inputs, numOutputs);

    % Find the action to perform
    actionEntry = catalog.lookupMethodSpecification(lookup);
    action = actionEntry.Value.Action;
    actionEntry.Value.Action = action.NextAction;

    methodCallRecordEntry = action.addMethodCallRecord(catalog, lookup);

    try
        [outputs{1:numOutputs}] = action.callMethod(className, methodName, static, inputs{:});
    catch exception
        methodCallRecordEntry.Value = UnsuccessfulMethodCall(className, methodName, static, inputs, numOutputs, exception);
        rethrow(exception);
    end
    methodCallRecordEntry.Value = SuccessfulMethodCall(className, methodName, static, inputs, numOutputs, outputs);

    methodCallData.Outputs = outputs;
end

function value = mockPropertyGetCallback(name, obj, className, catalog)
    import matlab.mock.history.PropertyAccess;
    import matlab.mock.history.SuccessfulPropertyAccess;
    import matlab.mock.history.UnsuccessfulPropertyAccess;
    
    lookup = PropertyAccess(className, name);
    
    % Find the action to perform
    actionEntry = catalog.lookupPropertyGetSpecification(lookup);
    action = actionEntry.Value.Action;
    actionEntry.Value.Action = action.NextAction;
    
    propertyGetEntry = catalog.addPropertyGetEntry(lookup);
    try
        value = action.getProperty(className, name, obj);
    catch exception
        propertyGetEntry.Value = UnsuccessfulPropertyAccess(className, name, exception);
        rethrow(exception);
    end
    propertyGetEntry.Value = SuccessfulPropertyAccess(className, name, value);
end

function mockPropertySetCallback(name, obj, value, className, catalog)
    import matlab.mock.history.PropertyModification;
    import matlab.mock.history.SuccessfulPropertyModification;
    import matlab.mock.history.UnsuccessfulPropertyModification;
    
    % Record the interaction
    lookup = PropertyModification(className, name, value);
    
    % Find the action to perform
    actionEntry = catalog.lookupPropertySetSpecification(lookup);
    action = actionEntry.Value.Action;
    actionEntry.Value.Action = action.NextAction;
    
    propertySetEntry = catalog.addPropertySetEntry(lookup);
    try
        action.setProperty(className, name, obj, value);
    catch exception
        propertySetEntry.Value = UnsuccessfulPropertyModification(className, name, value, exception);
        rethrow(exception);
    end
    propertySetEntry.Value = SuccessfulPropertyModification(className, name, value);
end

function parser = createParser
parser = matlab.unittest.internal.strictInputParser;
parser.addOptional("Superclass", meta.class.empty, @validateMetaclassInput);
parser.addParameter("Strict", false, @validateStrictInput);
parser.addParameter("MockedMethods", missing, @validateMockedMethodsInput);
parser.addParameter("AddedMethods", string.empty, @validateAddedMethodsInput);
parser.addParameter("AddedEvents", string.empty, @validateAddedEventsInput);
parser.addParameter("AddedProperties", string.empty, @validateAddedPropertiesInput);
parser.addParameter("ConstructorInputs", {}, @validateConstructorInputs);
parser.addParameter("DefaultPropertyValues", struct, @validateDefaultPropertyValues);

    function validateMetaclassInput(mcls)
        if isempty(mcls) && ~isempty(metaclass(mcls)) && (metaclass(mcls) <= ?meta.class)
            error(message("MATLAB:mock:MockContext:ClassNotFound"));
        end
        validateattributes(mcls, {'meta.class'}, {'scalar'});
    end

    function validateStrictInput(strict)
        validateattributes(strict, {'logical'}, {'scalar'});
    end

    function validateMockedMethodsInput(mockedMethods)
        validateStringOrCellstrInput("MockedMethods", mockedMethods);
        
        % Mocked methods must not contain repetitions
        duplicate = findFirstDuplicate(mockedMethods);
        if ~isempty(duplicate)
            error(message("MATLAB:mock:MockContext:RepeatedAddedMethod", ...
                duplicate, "MockedMethods"));
        end
    end

    function validateAddedMethodsInput(addedMethods)
        validateStringOrCellstrInput("AddedMethods", addedMethods);
        addedMethods = string(addedMethods);
        
        % Valid method names consist of an arbitrarily long list of MATLAB variable
        % names joined with dots (for converter methods).
        for thisMethod = addedMethods
            parts = strsplit(thisMethod, ".", "CollapseDelimiters",false);
            allPartsValid = cellfun(@isvarname, cellstr(parts));
            if ~all(allPartsValid)
                error(message("MATLAB:mock:MockContext:InvalidMethodName", thisMethod));
            end
        end
        
        % Added methods must not contain repetitions
        duplicate = findFirstDuplicate(addedMethods);
        if ~isempty(duplicate)
            error(message("MATLAB:mock:MockContext:RepeatedAddedMethod", ...
                duplicate, "AddedMethods"));
        end
    end

    function validateAddedPropertiesInput(addedProperties)
        validateStringOrCellstrInput("AddedProperties", addedProperties);
        addedProperties = string(addedProperties);
        
        % Property names must be valid identifiers
        for prop = addedProperties
            if ~isvarname(prop)
                error(message("MATLAB:mock:MockContext:InvalidPropertyName", prop));
            end
        end
        
        % Added properties must not contain repetitions
        duplicate = findFirstDuplicate(addedProperties);
        if ~isempty(duplicate)
            error(message("MATLAB:mock:MockContext:RepeatedAddedProperty", ...
                duplicate, "AddedProperties"));
        end
    end

    function validateAddedEventsInput(addedEvents)
        validateStringOrCellstrInput("AddedEvents", addedEvents);
        addedEvents = string(addedEvents);
        
        % Event names must be valid identifiers
        for evt = addedEvents
            if ~isvarname(evt)
                error(message("MATLAB:mock:MockContext:InvalidEventName", evt));
            end
        end
        
        % Added events must not contain repetitions
        duplicate = findFirstDuplicate(addedEvents);
        if ~isempty(duplicate)
            error(message("MATLAB:mock:MockContext:RepeatedAddedEvent", ...
                duplicate, "AddedEvents"));
        end
    end

    function validateDefaultPropertyValues(defaultPropertyValues)
        validateattributes(defaultPropertyValues, {'struct'}, {'scalar'});
    end

    function validateStringOrCellstrInput(name, value)
        if ~isequal(value,{}) && ~isequal(value, string.empty)
            validateattributes(value, {'cell', 'string'}, {'row'});
        end
        if ~isstring(value) && ~(iscellstr(value) && all(cellfun(@isrow, value(:))))
            error(message("MATLAB:mock:MockContext:MustBeStringOrCellOfCharacterVectors", name));
        end
        if any(ismissing(string(value)))
            error(message("MATLAB:mock:MockContext:MissingString"));
        end
    end
end

function validateAbstractProperties(abstractProperties, useCustomMetaData)
import matlab.mock.internal.MockContext;
import matlab.mock.internal.MockSuperclassAnalyzer;

[nonDefaultMask, nonDefaultAttributes] = MockSuperclassAnalyzer.findMembersWithNonDefaultCustomAttributes( ...
    abstractProperties, MockContext.IgnoredPropertyAttributes, useCustomMetaData);
if any(nonDefaultMask)
    properties = abstractProperties(nonDefaultMask);
    attributes = nonDefaultAttributes(nonDefaultMask);
    error(message("MATLAB:mock:MockContext:NonDefaultPropertyAttributeValue", ...
        properties(1).Name, attributes(1)));
end
end

function validateAbstractMethods(abstractMethods, useCustomMetaData)
% Mock object superclasses cannot specify an Abstract subsref method or
% have abstract methods with non-default custom metadata attribute values.

import matlab.mock.internal.MockContext;
import matlab.mock.internal.MockSuperclassAnalyzer;

possibleAbstractSubsrefMethod = abstractMethods.findobj("Name","subsref");
if ~isempty(possibleAbstractSubsrefMethod)
    definingClass = possibleAbstractSubsrefMethod.DefiningClass;
    error(message("MATLAB:mock:MockContext:ForbiddenAbstractMethod", ...
        definingClass.Name, "subsref"));
end

[nonDefaultMask, nonDefaultAttributes] = MockSuperclassAnalyzer.findMembersWithNonDefaultCustomAttributes( ...
    abstractMethods, MockContext.IgnoredMethodAttributes, useCustomMetaData);
if any(nonDefaultMask)
    methods = abstractMethods(nonDefaultMask);
    attributes = nonDefaultAttributes(nonDefaultMask);
    error(message("MATLAB:mock:MockContext:NonDefaultMethodAttributeValue", ...
        methods(1).Name, attributes(1)));
end
end

function validateAddedMethodsValue(addedMethods, metaclasses)
import matlab.mock.internal.MockSuperclassAnalyzer;

if isempty(addedMethods)
    % Early return when no validation is needed
    return;
end

if ismember("subsref", addedMethods)
    error(message("MATLAB:mock:MockContext:UnableToAddMethod", "AddedMethods", "subsref"));
end

for mcls = metaclasses
    existingNonPrivateMethods = MockSuperclassAnalyzer.getAllVisibleSuperclassMethods(mcls);
    repeatedMethods = intersect(addedMethods, {existingNonPrivateMethods.Name});
    if ~isempty(repeatedMethods)
        error(message("MATLAB:mock:MockContext:UnableToAddExistingMethod", ...
            "AddedMethods", repeatedMethods{1}, mcls.Name));
    end
end
end

function validateMockedMethodsValue(mockedMethods, addedMethods, metaclasses, abstractMethods, useCustomMetaData)
import matlab.mock.internal.MockSuperclassAnalyzer;

if ~mockedMethodsSpecified(mockedMethods) || isempty(mockedMethods)
    % Early return when no validation is needed
    return;
end

concreteMethods = MockSuperclassAnalyzer.getOverridableConcreteMethods(metaclasses, useCustomMetaData);
allowedMockedMethods = [addedMethods, abstractMethods.Name, concreteMethods.Name];

unmockableMethods = setdiff(mockedMethods, allowedMockedMethods);
if ~isempty(unmockableMethods)
    error(message("MATLAB:mock:MockContext:UnableToMockMethod", "MockedMethods", unmockableMethods(1)));
end
end

function validateAddedPropertiesValue(addedProperties, metaclasses)
if isempty(addedProperties)
    % Early return when no validation is needed
    return;
end

for mcls = metaclasses
    existingNonPrivateProperties = mcls.PropertyList.findobj('-not', ...
        {'GetAccess','private','-and',{'SetAccess','private','-or','SetAccess','immutable','-or','SetAccess','none'}});
    repeatedProperties = intersect(addedProperties, {existingNonPrivateProperties.Name});
    if ~isempty(repeatedProperties)
        error(message("MATLAB:mock:MockContext:UnableToAddExistingProperty", ...
            "AddedProperties", repeatedProperties{1}, mcls.Name));
    end
end
end

function validateAddedEventsValue(addedEvents, metaclasses)
if isempty(addedEvents)
    % Early return when no validation is needed
    return;
end

% Events can only be added to handle subclasses
if ~any(metaclasses <= ?handle)
    error(message("MATLAB:mock:MockContext:HandleClassRequiredToAddEvents"));
end
end

function defaultPropertyValues = validateDefaultPropertyValuesValue(defaultPropertyValues, addedPropertyNames, abstractProperties)
abstractPropertyNames = {abstractProperties.Name};
defaultPropertyNames = toRow(string(fieldnames(defaultPropertyValues)));

extraProperties = setdiff(defaultPropertyNames, [abstractPropertyNames, addedPropertyNames]);
if ~isempty(extraProperties)
    error(message("MATLAB:mock:MockContext:UnableToSpecifyDefaultValueForNonexistentProperty", ...
        "DefaultPropertyValues", extraProperties{1}));
end

for thisProperty = toRow(abstractProperties)
    propertyName = thisProperty.Name;
    
    try % validate the Validation for all abstract properties
        validation = thisProperty.Validation;
    catch cause
        exception = MException(message("MATLAB:mock:MockContext:InvalidPropertyValidation", ...
            propertyName, thisProperty.DefiningClass.Name));
        exception = exception.addCause(cause);
        throwAsCaller(exception);
    end
    
    if any(propertyName == defaultPropertyNames)
        for validation = toRow(validation)
            % Validate and coerce default property values according to the property
            % validation defined in the superclass definition of each property.
            try
                defaultPropertyValues.(propertyName) = validation.validateValue(defaultPropertyValues.(propertyName));
            catch cause
                exception = MException(message("MATLAB:mock:MockContext:InvalidPropertyDefaultValue", propertyName));
                exception = exception.addCause(cause);
                throwAsCaller(exception);
            end
        end
    end
end
end

function duplicate = findFirstDuplicate(str)
[~, uniqueIdx] = unique(str);
mask = true(1,numel(str));
mask(uniqueIdx) = false;
duplicate = str(find(mask,1));
end

function validateConstructorInputs(value)
if ~isequal(value,{})
    validateattributes(value, {'cell'}, {'row'});
end
end

function bool = mockedMethodsSpecified(mockedMethods)
bool = ~any(ismissing(mockedMethods));
end

function methods = getAdditionalMethodsToOverrideButNotMock(mcls)
allSuperclassMethods = vertcat(meta.method.empty, mcls.MethodList);

% Invisible methods
invisibleSuperclassMethods = mcls.findobj("-isa","meta.method", "Static",false);
methods = toRow(setdiff(invisibleSuperclassMethods, allSuperclassMethods));
end

function validateAnyArgumentsUsage(inputs)
for idx = 1:numel(inputs)-1
    if builtin("metaclass",inputs{idx}) == ?matlab.mock.AnyArguments
        error(message("MATLAB:mock:MockContext:AnyArgumentsMustBeLast", "AnyArguments"))
    end
end
end

function validateBehaviorUsage(methodName, inputs)
for idx = 1:numel(inputs)
    label = builtin("_getMockLabel", inputs{idx});
    if isa(label, "matlab.mock.internal.MockObjectRole")
        error(message("MATLAB:mock:MockContext:UnexpectedInput", ...
            "Mock", methodName, "Behavior"));
    end
end
end

function validateScalarBehavior(methodName, inputs)
for idx = 1:numel(inputs)
    label = builtin("_getMockLabel", inputs{idx});
    if isa(label, "matlab.mock.internal.BehaviorRole") && ~isequal(builtin("size",inputs{idx}), [1,1])
        error(message("MATLAB:mock:MockContext:NonScalarInput", "Behavior", methodName));
    end
end
end

function value = toRow(value)
value = reshape(value, 1, []);
end

% LocalWords:  mcls lang Overridable overridable isstring assertable CPROPLC noop
% LocalWords:  superclass's ismissing metaclasses cls func unittest Cancelable
% LocalWords:  strsplit CPROP isequaln unmockable evt strlength
