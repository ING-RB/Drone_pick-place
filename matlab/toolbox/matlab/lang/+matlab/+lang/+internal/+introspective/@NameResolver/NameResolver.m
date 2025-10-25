classdef NameResolver < handle

    properties
        introspectiveContext (1,1) matlab.lang.internal.introspective.IntrospectiveContext;

        resolvedSymbol   (1,1) matlab.lang.internal.introspective.ResolvedSymbol;

        helpPath         = '';

        fixTypos         = false;
        findBuiltins     = true;
        findVariables    = true;

        malformed        = false;
        justChecking     = true;
        isPathQualified  = false;

        resolveOverqualified = true;

        lowerBeforeRef   = false;
    end

    properties (SetAccess = private)
        foundParentFolder (1,1) string = "";
    end

    properties (Dependent, SetAccess = private)
        regexpCaseOption;
    end

    methods
        function obj = NameResolver(topicInput, args)
            arguments
                topicInput                (1,1) string;
                args.QualifyingPath       (1,1) string  = "";
                args.JustChecking         (1,1) logical = true;
                args.FixTypos             (1,1) logical = false;
                args.ResolveOverqualified (1,1) logical = true;
                args.FindBuiltins         (1,1) logical = true;
                args.IntrospectiveContext (1,1) matlab.lang.internal.introspective.IntrospectiveContext = matlab.lang.internal.introspective.IntrospectiveContext;
            end
        
            obj.resolvedSymbol.topicInput = topicInput;
            obj.resetTopic;

            obj.helpPath             = args.QualifyingPath;
            obj.justChecking         = args.JustChecking;
            obj.fixTypos             = args.FixTypos;
            obj.resolveOverqualified = args.ResolveOverqualified;
            obj.findBuiltins         = args.FindBuiltins;
            obj.introspectiveContext = args.IntrospectiveContext;
        end

        function result = get.regexpCaseOption(obj)
            if obj.resolvedSymbol.isCaseSensitive
                result = 'matchcase';
            else
                result = 'ignorecase';
            end
        end

        executeResolve(obj, isCaseSensitive);
    end

    methods (Access=private)
        doResolve(obj, topic, resolveWorkspace);
        innerDoResolve(obj, topic);

        [referenceName, caseMatch, isUnderqualified] = referenceResolve(obj, topic);
        underqualifiedResolve(obj, topic);
        resolveWithTypos(obj);

        resolveExplicitPath(obj, topic);
        resolveImplicitPath(obj, topic);

        resolveUnaryClass(obj, className, elementName, elementSpecified);

        UDDClassInformation(obj, UDDParts);
        MCOSClassInformation(obj, topic, MCOSParts);

        resolvePackageInfo(obj, allPackageInfo, isExplicitPackage);
        [classMFile, className, packageName] = resolveClassMFile(obj, topic);

        function resetTopic(obj)
            obj.resolvedSymbol.classInfo  = [];
            obj.resolvedSymbol.whichTopic = '';
            obj.resolvedSymbol.resolvedTopic = obj.resolvedSymbol.topicInput;
        end

        function setBuiltinName(obj, name)
            obj.resolvedSymbol.resolvedTopic = name;
            obj.resolvedSymbol.isBuiltin = true;
        end
    end

    methods(Static)
        [isDocumented, packageID] = isDocumentedPackage(packageInfo, packageName);
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.
