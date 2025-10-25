classdef FileInformation < handle & matlab.mixin.Heterogeneous
    %

    % Copyright 2017-2021 The MathWorks, Inc.
   
    properties (SetAccess = private)
        NumLines
    end
    
    properties (Abstract,SetAccess =  private)
        MethodList matlab.unittest.internal.fileinformation.CodeSegmentInformation
    end

    properties (SetAccess =  private)
        ExecutableLines
    end
    
    properties (SetAccess = private, GetAccess = protected)
        FileTree
    end
    
    methods (Static)
        function info =  forFile(filename, executableLines)
            import matlab.unittest.internal.fileResolver;
            fullName = fileResolver(filename);   
            codeLines = matlab.internal.getCode(fullName);
            parseTree = mtree(codeLines);
            
            if (parseTree.FileType == mtree.Type.ClassDefinitionFile)
                info = matlab.unittest.internal.fileinformation.ClassFileInformation(parseTree);
            else
                info = matlab.unittest.internal.fileinformation.ProceduralFileInformation(parseTree);
            end
            info.NumLines = numel(splitlines(codeLines));
            info.ExecutableLines = executableLines;
        end
    end
    
    methods (Access = protected)
        function info = FileInformation(parseTree)
            info.FileTree = parseTree;            
        end
    end    
end
% LocalWords:  fileinformation codelines splitlines iskind DCALL mtfind lineno
% LocalWords:  PROTO fileinformation codelines splitlines iskind DCALL mtfind
% LocalWords:  lineno PROTO
