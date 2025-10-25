function dlgs = findDDGByTag( tag )
alldlgs = DAStudio.ToolRoot.getOpenDialogs;
dlgs = alldlgs(arrayfun(@(a) strcmp(a.dialogTag,tag),alldlgs));
end

