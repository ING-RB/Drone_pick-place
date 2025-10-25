function getClassDiagram(className)
    %GETCLASSDIAGRAM creates a class diagram using the Class Diagram Viewer
    % app. The class diagram will include its superclasses
    % This is an undocumented function and may be removed in a future release
    % Copyright 2023 The MathWorks, Inc.
    arguments
        className {mustBeNonempty, mustBeTextScalar}
    end
    mc = meta.class.fromName(className);
    if(isempty(mc))
        error('MATLAB:class:ClassNotFoundOnPath', message('MATLAB:class:ClassNotFoundOnPath', className).getString());
    end
    app = matlab.internal.classviewer();
    app.IsShowMixins = true;
    app.addClass(className);
    sc = superclasses(className);
    if(~isempty(sc))
        % If the class has superclasses, add them to the class diagram app
        elementsInfo = struct('toShowAll', true, 'elementsInfo', {['Class|' className]});
        app.addSuperclasses(elementsInfo);
    end
    names = app.getAllElementNames;
    for nm = names
        % Expand the properties section for all the classes in the app
        app.expandSection(nm, 'Properties', 1);
    end
end