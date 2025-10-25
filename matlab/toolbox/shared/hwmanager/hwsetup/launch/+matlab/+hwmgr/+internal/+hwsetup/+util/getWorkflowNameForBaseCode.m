function out = getWorkflowNameForBaseCode(baseCode)
%GETWORKFLOWNAMEFORBASECODE(BASECODE) accpets a basecode and returns the
% name of the Workflow class corresponding to the HW Setup Workflow for that
% particular base code.

% Copyright 2016 MathWorks Inc.

validateattributes(baseCode, {'char'}, {'nonempty'},...
    'getWorkflowForBaseCode', 'baseCode');
% Find all Workflow classes on path
allWorkflowNames = matlab.hwmgr.internal.hwsetup.util.getAllWorkflowClassesOnPath();
out = {};
% Filter the Workflow Name corresponding to baseCode
for i = 1:numel(allWorkflowNames)
    classInfo = meta.class.fromName(allWorkflowNames{i});
    allProperties = {classInfo.PropertyList.Name};
    idxb= strcmp(allProperties, 'BaseCode');
        if any(idxb) && strcmp(classInfo.PropertyList(idxb).DefaultValue, baseCode)
        out{end+1} = allWorkflowNames{i}; %#ok<AGROW>
        break
    end
end

end
