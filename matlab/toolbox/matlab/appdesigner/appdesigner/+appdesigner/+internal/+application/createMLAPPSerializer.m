function serializer = createMLAPPSerializer(destinationFullFileName, appModel)
    % CREATEMLAPPSERIALIZER Returns an instance of MLAPPSerializer configured
    % that will perform the proper steps to save the passed AppModel.  The
    % AppModel must still set the proper data on the serializer.  In other
    % words, this function knows how to save the AppModel, but not what to
    % save - the AppModel still decides what must be saved.

    % Copyright 2019 The MathWorks, Inc.
    serializer = appdesigner.internal.serialization.MLAPPSerializer(destinationFullFileName, appModel.UIFigure);

    if isempty(appModel.FullFileName) && isfile(destinationFullFileName)
        % Performing an initial save of the app model on top of an
        % existing file.  When this is the case, it is necessary to
        % initialize a new blank MLAPP file there, instead of
        % saving over the existing file.
        serializer.OverwriteTargetFile = true;
    end
end
