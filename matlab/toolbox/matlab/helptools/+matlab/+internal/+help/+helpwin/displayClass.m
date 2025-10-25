function ret = displayClass(classInfo)
ret = ~isempty(classInfo) && (classInfo.isClass || classInfo.isMethod || classInfo.isSimpleElement);
end
