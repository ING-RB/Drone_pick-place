function tf = isFunctionBasedBuildFile(tree)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2022-2024 The MathWorks, Inc.

arguments
    tree (1,1) mtree
end

tf = false;

if isnull(tree)
    return;
end

if tree.FileType ~= mtree.Type.FunctionFile
    return;
end

mainOutput = tree.root.Outs;
if mainOutput.isnull()
    return;
end

outputExpressions = tree.mtfind('SameID', mainOutput);
indices = outputExpressions.indices;

% Loop through the array, and check that buildplan was called and assigned
% to the main function output at some point
for idx = indices
    thisOutput = tree.select(idx);
    parent = thisOutput.Parent;
    % Only check for assignment operations
    if ~parent.iskind('EQUALS')
        continue;
    end
    
    expression = parent.Right;
    buildplanCall = mtfind(expression.Full, ...
        'Kind', 'CALL', ...
        'Left.Kind', 'ID', ...
        'Left.String', 'buildplan');

    if ~isnull(buildplanCall)
        tf = true;
        break;
    end
end

end

% LocalWords:  buildplan
