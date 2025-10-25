function fwdDecString = fwdDecToString(fwdDecClasses)
%FWDDECTOSTRING Given the full package path of a class(es)
% return how it should be forward declared in CPP

%   Copyright 2020-2023 The MathWorks, Inc.

fwdDecString = "";

for i = 1:length(fwdDecClasses)
    
    fullpath = fwdDecClasses(i);
    pathparts = split(fullpath, "."); % split up the packages
    namespaceParts = pathparts(1:end-1);
    classEnd = pathparts(end);
    
    % if there is no package/namespace, just declare the class
    if(isempty(namespaceParts))
        fwdDecString = fwdDecString + "class " + classEnd + ";" + newline + newline;
    
    % else print the namespaces and then declare class within them
    else
        rootIndent = "";
        for k = 1:length(namespaceParts)
            rootIndent = repmat(['[oneIndent]'], 1, 1-k);
            fwdDecString = fwdDecString + ...
                rootIndent + "namespace " + namespaceParts(k) + " {" + newline;
        end
        rootIndent = repmat(['[oneIndent]'], 1, k);
        fwdDecString = fwdDecString + rootIndent + "class " + classEnd + ";" + newline;
        
        for k = length(namespaceParts):-1:1
             rootIndent = repmat(['[oneIndent]'], 1, 1-k);
              fwdDecString = fwdDecString + "}" + newline;
        end
        
        fwdDecString = fwdDecString + newline;
        
    end
    
end

end
    
%     TODO: Consider merging the namespace parts of the fwd declare where
%           possible instead of listing namespaces over and over in some cases.
