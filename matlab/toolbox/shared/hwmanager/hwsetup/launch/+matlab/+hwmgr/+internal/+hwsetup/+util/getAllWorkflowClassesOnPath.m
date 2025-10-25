function wNames = getAllWorkflowClassesOnPath()
% GETALLWORKFLOWCLASSESONPATH searches for all classes of type
% matlab.hwmgr.internal.hwsetup.Workflow inside package
% matlab.hwmgr.internal.hwsetup.register and returns the names of these
% classes asa cell array of strings

% Copyright 2016 MathWorks Inc.

metaObj = meta.package.fromName('matlab.hwmgr.internal.hwsetup.register');
wNames = {};
if isempty(metaObj)
    return
end

allClassesInPackage = metaObj.ClassList;
wNames = {};
for i = 1:numel(allClassesInPackage)
    superClassNames = superclasses(allClassesInPackage(i).Name);
    if any(ismember(superClassNames, 'matlab.hwmgr.internal.hwsetup.Workflow'))
        wNames{end+1} =   allClassesInPackage(i).Name; %#ok<AGROW>
    end
end

end
