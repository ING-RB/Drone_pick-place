function [nameSpaceOpen, nameSpaceClosure] = generateNamespace(functionNameFull)
    % generateNamspace Given the name of a class or function, generates the
    % C++ namespace opening and namespace closure
    % 
    % e.g. for input "ns1.ns2.myfunc", output will be
    % "namespace ns1 { namespace ns2 {" and "} }" respectively.
    % Note: above may not be exact formatting

    arguments (Input)
        functionNameFull (1,1) string  % Full name of the class or function in dot notation
    end

    arguments (Output)
        nameSpaceOpen (1,1) string     % Opening of namespace
        nameSpaceClosure (1,1) string  % Closing of namespace
    end


    % Specify the namespaces
    nameSpaceOpen = "";
    nameSpaceClosure = "" + newline;

    % Extract namespace from the package path in dot notation
    nsParts = split(functionNameFull, '.');
    for i = 1 : length(nsParts)-1
        nameSpaceOpen = nameSpaceOpen + "namespace " + ...
            nsParts(i) + " { ";
        nameSpaceClosure = nameSpaceClosure + "} ";
    end

    % Trim and format namespace of the function
    nameSpaceOpen = strip(nameSpaceOpen, 'right');
    nameSpaceOpen = nameSpaceOpen + newline;
    nameSpaceClosure = strip(nameSpaceClosure, 'right');
    nameSpaceClosure = nameSpaceClosure + newline;
end