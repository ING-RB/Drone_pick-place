function configData = bootstrap(inputData)

    configData = struct();

    if slonline.util.isSimulinkOnline
        % update client side keyboard layout information
        kbProxy = simulink.online.internal.keyboard.Controller.instance;
        kbProxy.updateClientSideKeyboardInfo(inputData.keyboardLayout, inputData.locale);

        % update cached client side browser size
        simulink.online.internal.WindowManager.getInstance().updateCachedBrowserSizeData(inputData.browserSize);

        % get screen size
        statusBarHeight = 50;
        screenSize = get(groot,'Screensize');
        configData.screenSize.width = screenSize(3);
        configData.screenSize.height = screenSize(4) - statusBarHeight;

        % get the diagnostic viewer names
        [configData.diagnosticViewerNames.dv, configData.diagnosticViewerNames.suppressions] = simulink.online.internal.getDVWindowNames();
    end
end

