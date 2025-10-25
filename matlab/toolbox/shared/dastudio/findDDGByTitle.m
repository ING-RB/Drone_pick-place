function dlgs = findDDGByTitle( title )
alldlgs = DAStudio.ToolRoot.getOpenDialogs;
dlgs = alldlgs(arrayfun(@(a) strcmp(a.getTitle,title),alldlgs));
end