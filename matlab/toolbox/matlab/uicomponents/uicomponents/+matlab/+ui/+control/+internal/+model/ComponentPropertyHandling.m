classdef (Hidden) ComponentPropertyHandling
    %COMPONENTPROPERTYHANDELING Summary of this class goes here
    %  This class will act as a shared code database for similar code
    %  between addStyle and scroll, along with other table functions
    
    
    methods (Static)
       function validComponent = isValidComponent(comp, type)
        % A UITable parented to a Java figure is invalid.
        % Else (i.e. parented to a web figure or empty parent) it is valid.
        isComponent = isa(comp, type);
    
        % Returns the top-level Figure ancestor if one exists. Otherwise [].
        topLevelAncestor = ancestor(comp, 'figure', 'toplevel');
    
        isUIFigure = matlab.ui.internal.isUIFigure(topLevelAncestor);
        validComponent = isComponent && (isUIFigure || isempty(topLevelAncestor));
       end
       
    end
end

