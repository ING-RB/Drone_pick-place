function WriteToCSFile(fileContents, destinationFolder, fileName, indentChar, indentSize)
%WRITETODOTNETFILE write a string to a .cs file
arguments(Input)
    fileContents string
    destinationFolder (1,1) string
    fileName (1,1) string
    indentChar {mustBeText}
    indentSize int32 {mustBeReal}
end
    %create the target directory if it doesn't exist already
    if ~isfolder(destinationFolder)
        mkdir(destinationFolder);
    end
    file = fullfile(destinationFolder, fileName);
    file = file + ".cs";
    fid = fopen(file, 'w');
    includes = matlab.engine.internal.codegen.csharp.CSharpIncludes();
    fileContents = includes.string() + fileContents;

    fileContents = replace(fileContents,"[oneIndent]", repmat(indentChar, 1, indentSize));
    fileContents = replace(fileContents, "[FileName]", fileName+".cs");
    fprintf(fid, fileContents);
    fclose(fid);
end

