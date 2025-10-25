function out = getContainedClassName (inp)
    % This returns the classname of the given class depending on the state
    % of the hyperlinks
    
    % Copyright 2017-2019 The MathWorks, Inc.
   
    if matlab.internal.display.isHot
        out = ['<a href="matlab:helpPopup ' class(inp) '" >' class(inp) '</a>'];
    else
        out = class(inp);
    end    
end
