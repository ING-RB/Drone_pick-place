% this example shows an exception handling method.
% restart the model.

function SLOperation(modelName)

    bdclose(modelName);
    open_system(modelName);
    simulink.online.internal.WindowManager.getInstance().maximize('modelName', modelName);

end