classdef OptionsForm
    %OPTIONSFORM class contains information about the Options Dialog to be
    %constructed.

    % Copyright 2020 The MathWorks, Inc.

    properties
        % The title of the Options Dialog box
        Title (1, 1) string

        % The message to be displayed in the Options Dialog box
        Message (1, 1) string

        % The options that users can select in the Options Dialog box, e.g.
        % "OK" and "Cancel"
        Options (1, :) string

        % The default option selected.
        DefaultOption (1, 1) string

        % The parent module property that gets notified when an option
        % (e.g."OK" or "Cancel") is selected. This will allow for the
        % parent module property to take an action based on the option
        % selected.
        OptionParentProperty (1, 1) string
    end

    %% Getters and Setters
    methods
        function obj = set.DefaultOption(obj, val)
            arguments
               obj
               val (1, 1) string
            end

            % If the default option is not one of the possible option
            % values provided - error.
            if ~ismember(val, obj.Options)
                listString = strjoin(obj.Options, ", "); %#ok<*MCSUP>
                throw(MException(message("transportapp:utilities:InvalidDefaultOption", ...
                    val, listString)));
            end
            obj.DefaultOption = val;
        end

        function obj = set.OptionParentProperty(obj, val)
           arguments
               obj
               val (1, 1) string
           end

           % The OptionParentProperty needs to be one of
           % possibleOptionParents defined in the dialog handler class.
           possibleOptionParents = ...
               matlabshared.transportapp.internal.utilities.dialog.Handler.SetObservableVariables;

           if ~ismember(val, possibleOptionParents)
               listString = strjoin(possibleOptionParents, ", ");
               throw(MException(message("transportapp:utilities:InvalidOptionParent", ...
                   val, listString)));
           end
           obj.OptionParentProperty = val;
        end
    end
end