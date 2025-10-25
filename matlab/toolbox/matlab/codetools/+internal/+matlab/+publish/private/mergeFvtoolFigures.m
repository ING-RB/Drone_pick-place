function mergedFiguresList = mergeFvtoolFigures(figuresOriginal, flip)
% Merges the fvtool figures with the list of figures returned by allchild(0)
fvToolFigures = findobjinternal(0,'type','figure','Tag','filtervisualizationtool');

if ~isempty(fvToolFigures)
    % Proceed with the merge only if there are fvtool figures
    if flip
        fvToolFigures = flipud(fvToolFigures);
        mergedFiguresList = cat(1, figuresOriginal, fvToolFigures);
    else
        mergedFiguresList = cat(1, figuresOriginal, fvToolFigures);
    end
else
    % Return the original figures list if there are no fvtool figures 
    mergedFiguresList = figuresOriginal;
end
end

