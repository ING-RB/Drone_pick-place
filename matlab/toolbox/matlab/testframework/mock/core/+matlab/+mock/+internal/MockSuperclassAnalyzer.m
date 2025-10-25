classdef (Hidden) MockSuperclassAnalyzer
    %MOCKSUPERCLASSANALYZER Method and property parsing for superclasses
    % used by MockContext and the createMock tab completion.

    % Copyright 2015-2024 The MathWorks, Inc.

    methods (Static)
        function methodList = getMethods(superclass)
            % Used for createMock tab completion. Only return abstract or
            % concrete methods that only have the default or ignored
            % attributes (list of ignored attributes can be found in
            % MockContext).
            import matlab.mock.internal.MockContext;
            import matlab.mock.internal.MockSuperclassAnalyzer;

            if superclass.Sealed
                % If superclass is sealed, don't generate list of methods.
                methodList = {};
            else
                % Attempt to generate list of mockable methods.
                useCustomMetaData = any(arrayfun(@(cls)metaclass(cls) ~= ?meta.class, superclass));
                abstractMethods = MockSuperclassAnalyzer.getAbstractMembers(superclass); % Get all abstract methods
                nonDefaultMask = MockSuperclassAnalyzer.findMembersWithNonDefaultCustomAttributes( ...
                    abstractMethods, MockContext.IgnoredMethodAttributes, useCustomMetaData);
                abstractMethods = abstractMethods(~nonDefaultMask); % Filter all methods that do not have the default attributes
                concreteMethods = MockSuperclassAnalyzer.getOverridableConcreteMethods(superclass, useCustomMetaData); % Get all concrete methods that have default attributes
                methodList = {abstractMethods.Name, concreteMethods.Name};
            end
        end

        function [abstractMethods, abstractProperties] = getAbstractMembers(metaclasses)
            import matlab.mock.internal.MockContext;
            import matlab.mock.internal.MockSuperclassAnalyzer;
            import matlab.mock.internal.ClassContext;
            import matlab.mock.internal.MethodInformation;
            import matlab.mock.internal.PropertyInformation;
            import matlab.lang.makeUniqueStrings;
            import matlab.lang.makeValidName;
            import matlab.lang.internal.uuid;

            % Find an available class name that doesn't overlap with any superclass
            % members or existing classes to avoid accidentally implementing an
            % abstract member.
            reservedNames = arrayfun(@(cls){cls.Name, cls.PropertyList.Name, cls.MethodList.Name}, metaclasses, UniformOutput=false);
            reservedNames = [reservedNames{:}, MockSuperclassAnalyzer.getExistingClassNames(MockContext.PrototypeNamespace)];
            className = makeUniqueStrings(makeValidName("Prototype_" + uuid), reservedNames, namelengthmax);

            noop = @(varargin)[];
            classContext = ClassContext(MockContext.PrototypeNamespace, className, ...
                string({metaclasses.ResolvedName}), MethodInformation.empty, noop, ...
                PropertyInformation.empty, noop, noop, string.empty, []);
            cls = classContext.registerClass;

            abstractMethods = cls.MethodList.findobj(Abstract=true);
            abstractProperties = cls.PropertyList.findobj(Abstract=true);
        end

        function existingClassNames = getExistingClassNames(namespace)
            import matlab.unittest.internal.getSimpleParentName;

            namespaceMetadata = meta.package.fromName(namespace);
            existingClasses = [namespaceMetadata.ClassList, meta.class.empty];
            existingClassNames = cellfun(@getSimpleParentName, {existingClasses.Name}, ...
                UniformOutput=false);
        end

        function methods = getOverridableConcreteMethods(mcls, useCustomMetaData)
            methods = arrayfun(@getAllOverridableConcreteMethods, mcls, UniformOutput=false);
            methods = [meta.method.empty(1,0), methods{:}];

            % Only consider one method for each unique name
            [~, uniqueIdx] = unique({methods.Name});
            methods = methods(uniqueIdx);

            function allMethods = getAllOverridableConcreteMethods(mcls)
                import matlab.mock.internal.MockContext;
                import matlab.mock.internal.MockSuperclassAnalyzer;

                allMethods = MockSuperclassAnalyzer.getAllVisibleSuperclassMethods(mcls);
                allMethods = allMethods.findobj("Sealed",false, "Static",false, "Abstract",false, ...
                    "-not","Name","subsref");

                if mcls <= ?handle
                    allMethods = allMethods.findobj("-not","Name","delete");
                end

                if mcls <= ?MException
                    allMethods = allMethods.findobj("-not","Name","BuiltinThrow");
                end

                isAccessible = true(size(allMethods));
                for idx = 1:numel(allMethods)
                    access = allMethods(idx).Access;
                    if iscell(access)
                        isAccessible(idx) = any(mcls <= [meta.class.empty, access{:}]);
                    end
                end
                allMethods = allMethods(isAccessible);

                customAttributeMask = MockSuperclassAnalyzer.findMembersWithNonDefaultCustomAttributes( ...
                    allMethods, MockContext.IgnoredMethodAttributes, useCustomMetaData);
                allMethods = toRow(allMethods(~customAttributeMask));
            end
        end

        function allMethods = getAllVisibleSuperclassMethods(mcls)
            import matlab.unittest.internal.getSimpleParentName;

            allMethods = mcls.MethodList.findobj("-not","Access","private", ...
                "-not","Name",getSimpleParentName(mcls.Name));
        end

        function [mask, customAttributes] = findMembersWithNonDefaultCustomAttributes(members, ignoredAttributes, useCustomMetaData)
            % Find members (properties, methods) with non-default values for custom
            % metadata attributes. Return a logical array of such members and a string
            % array indicating the first such custom attribute found for each true
            % element in the logical array.

            import matlab.mock.internal.MockContext;

            numMembers = numel(members);
            mask = false(1, numMembers);
            customAttributes = strings(1, numMembers);

            if ~useCustomMetaData
                % Superclasses do not use custom metadata. No analysis needed.
                return;
            end

            for idx = 1:numMembers
                thisMember = members(idx);
                thisMemberMetadata = metaclass(thisMember);
                memberProperties = thisMemberMetadata.PropertyList;
                memberPropertyNames = string({memberProperties.Name});

                allMemberAttributes = toRow(string(properties(thisMember)));
                for attribute = allMemberAttributes
                    if any(attribute == ignoredAttributes)
                        continue;
                    end

                    attributeMetadata = memberProperties(memberPropertyNames == attribute);

                    if ~attributeMetadata.HasDefault
                        % Allow members to use custom attributes without an explicit default
                        % value. Any conflicts will be checked at mock construction time in
                        % validate[Method|Property]Attributes.
                        continue;
                    end

                    if ~isequaln(attributeMetadata.DefaultValue, thisMember.(attribute))
                        mask(idx) = true;
                        customAttributes(idx) = attribute;
                        break;
                    end
                end
            end
        end
    end
end

function value = toRow(value)
value = reshape(value, 1, []);
end

% LocalWords:  mockable cls Overridable metaclasses lang noop mcls
