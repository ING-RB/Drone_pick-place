classdef (Sealed, Abstract, Hidden) DirtyPropertyStrategyFactory
    %DIRTYPROPERTYSTRATEGYFACTORY A factory class to create instances of
    % DirtyPropertyStrategy for use with AbstractController and subclasses.

    % Copyright 2019 The MathWorks, Inc.

    methods (Static)
        function strategy = getDirtyPropertyStrategy(model)

            if isprop(model, 'CodeAdapter') && ~isempty(model.CodeAdapter) && isvalid(model.CodeAdapter)
                % Do not create a new strategy.  Return the one from the
                % CodeAdapter.  This strategy mimics the update-time
                % strategy, and also fires events when properties are
                % marked dirty.
                strategy = model.CodeAdapter.DirtyPropertyStrategy;

            elseif isa(model, 'matlab.graphics.Graphics') && ~isprop(model, 'DesignTimeProperties')
                % Run-time Graphics objects will care about calls to
                % drawnow / doUpdate or the update traversal.  In cases
                % where we encounter a runtime Graphics object, use the
                % DirtyPropertyStrategy that defers until update time.
                strategy = appdesservices.internal.interfaces.model.UpdateTimeFlushDirtyPropertyStrategy(model);

            else
                % Default to ImmediateFlush - this is for any models that
                % are not Graphics objects, or are used in App Designer
                % (i.e. they have DesignTimeProperties).
                strategy = appdesservices.internal.interfaces.model.ImmediateFlushDirtyPropertyStrategy(model);
            end
        end
    end
end