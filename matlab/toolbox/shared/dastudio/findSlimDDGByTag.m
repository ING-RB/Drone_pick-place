function dlgs = findSlimDDGByTag( tag )
%findSlimDDGByTag Find slim DDG dialog by its tag
    alldlgs = DAStudio.ToolRoot.getOpenDialogs;
    dlgs = alldlgs(arrayfun(@(a)locIsSlimDDGWithTag(a,tag), alldlgs));
end

function tf = locIsSlimDDGWithTag(dlg, tag)
    tf = strcmp(dlg.dialogTag, tag) && strcmp(dlg.dialogMode, 'Slim');
end
