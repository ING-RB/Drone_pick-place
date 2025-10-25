function hasStatic = hasStaticMethod(className, methodName, args)
    arguments
        className (1,1) string
        methodName (1,1) string
        args.Access (1,1) string {mustBeMember(args.Access, ["private", "public", "protected", "any"])} = "public"
        args.SearchParentClasses (1,1) logical = true
    end
    % Returns true if class "className" has a method "methodName"
    % The method may have any access control, it will still be considered present

%   Copyright 2022 The MathWorks, Inc.
    
    hasStatic = false;
    metaCls = meta.class.fromName(className);
    if isempty(metaCls) || isempty(metaCls.MethodList)
        return;
    end
    staticIdxs = cell2mat({metaCls.MethodList.Static});
    staticMethods = metaCls.MethodList(staticIdxs);
    if isempty(staticMethods)
        return;
    end

    if args.Access ~= "any"
        accessIdxs = strcmp({staticMethods.Access}, args.Access);
        staticMethods = staticMethods(accessIdxs);
        if isempty(staticMethods)
            return;
        end
    end

    if (~args.SearchParentClasses)
        definingClasses = {staticMethods.DefiningClass};
        definingClassNames = cellfun(@(definingClass) string(definingClass.Name), definingClasses, 'UniformOutput', true);
        nonInheritedMethodsIdxs = strcmp(definingClassNames, className);
        staticMethods = staticMethods(nonInheritedMethodsIdxs);
        if isempty(staticMethods)
            return;
        end
    end

    hasStatic = any(strcmp({staticMethods.Name}, methodName));
end
