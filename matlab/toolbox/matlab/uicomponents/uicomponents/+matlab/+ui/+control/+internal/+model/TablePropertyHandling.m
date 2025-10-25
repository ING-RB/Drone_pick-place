classdef (Hidden) TablePropertyHandling
    %TABLEPROPERTYHANDELING Summary of this class goes here
    %  This class will act as a shared code database for similar code
    %  between addStyle and scroll, along with other table functions
    
    
    methods (Static)
       function validComponent = isValidComponent(comp)
        % A UITable parented to a Java figure or an embedded morphable figure
        % (figure-based MATLAB Online web figure) is invalid.
        % Else (i.e. parented to a web figure or empty parent) it is valid.
        isTableComponent = isa(comp, 'matlab.ui.control.Table');
    
        % Returns the top-level Figure ancestor if one exists. Otherwise [].
        topLevelAncestor = ancestor(comp, 'figure', 'toplevel');
    
        isUIFigure = matlab.ui.internal.isUIFigure(topLevelAncestor);

        isMorphableFigure = false;
        if ~isempty(topLevelAncestor)
            isMorphableFigure = isWebFigureType(topLevelAncestor,'EmbeddedMorphableFigure');
        end

        validComponent = isTableComponent && ((isUIFigure && ~isMorphableFigure) || isempty(topLevelAncestor));
       end
       
    end
end

