function dlgs = findNormalDDGByTag( tag )
%findNormalDDGByTag Find standalone DDG dialog by its tag
    alldlgs = DAStudio.ToolRoot.getOpenDialogs;
    dlgs = alldlgs(arrayfun(@(a)locIsNormalDDGWithTag(a,tag), alldlgs));
end

function tf = locIsNormalDDGWithTag(dlg, tag)
    tf = strcmp(dlg.dialogTag, tag) && strcmp(dlg.dialogMode, 'Normal');
end