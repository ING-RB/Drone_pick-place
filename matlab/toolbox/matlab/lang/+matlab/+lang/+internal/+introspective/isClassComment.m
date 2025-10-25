function [b, className, packageName] = isClassComment(whichComment)
    classSplit = regexp(whichComment, '^(?<package>[\w.]*)(?(package)\.)(?<class>\w*)\s*constructor$', 'names', 'once');
    b = ~isempty(classSplit);
    if b
        className   = classSplit.class;
        packageName = classSplit.package;
    else
        className   = '';
        packageName = '';
    end
end

%   Copyright 2022 The MathWorks, Inc.
