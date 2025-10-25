function resolvePackageInfo(obj, allPackageInfo, isExplicitPackage)

    for i = 1:numel(allPackageInfo)

        packageInfo = allPackageInfo(i);
        packagePath = packageInfo.path;
        packageName = matlab.lang.internal.introspective.getPackageName(packagePath);

        [isDocumented, packageID] = obj.isDocumentedPackage(packageInfo, packageName);

        if isDocumented
            % Package
            if isExplicitPackage || ~obj.findBuiltins || contains(packageName, '.') || any(strcmp(vertcat(packageInfo.m), 'Contents.m'))
                obj.resolvedSymbol.classInfo = matlab.lang.internal.introspective.classInformation.package(packagePath, isExplicitPackage, isscalar(allPackageInfo));
            end
            return;
        elseif ischar(packageID) && ~isempty(regexp(packagePath, '.*[\\/]@\w*$', 'once'))
            % MCOS or OOPS Class
            obj.resolvedSymbol.classInfo = matlab.lang.internal.introspective.classInformation.fullConstructor([], '', packageName, packagePath, false, true, obj.justChecking);
            return;
        end
    end
end

%   Copyright 2013-2024 The MathWorks, Inc.
