function type = findType( tree )
%FINDTYPE given a a fileTree determines

%   Copyright 2009-2015 The MathWorks, Inc.


if isa(tree, 'char')
    tree = mtree(tree,'-file');
end

if ~isa(tree,'mtree')
    error(message('MATLAB:codetools:NotATree'));
end

if isnull(tree)
    type = internal.matlab.codetools.reports.matlabType.Script;
    return
end

if iskind(root(tree), 'ERR')
    % When there is syntax error, always return Unknown.
    type = internal.matlab.codetools.reports.matlabType.Unknown;
else
    mtreeFileType = tree.FileType;
    if mtreeFileType == mtree.Type.FunctionFile
        type = internal.matlab.codetools.reports.matlabType.Function;
    elseif mtreeFileType == mtree.Type.ClassDefinitionFile
        type = internal.matlab.codetools.reports.matlabType.Class;
    elseif mtreeFileType == mtree.Type.ScriptFile
        type = internal.matlab.codetools.reports.matlabType.Script;
    else
        type = internal.matlab.codetools.reports.matlabType.Unknown;
    end
end
end


