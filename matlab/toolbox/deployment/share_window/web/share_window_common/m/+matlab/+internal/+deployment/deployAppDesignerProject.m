function deployAppDesignerProject(varargin)
    appPath = varargin{1};
    type = varargin{2};
    reqFiles = varargin{3};
    images = varargin{4};
    try
        [~, appDetails] = matlab.internal.deployment.getAppDetails(appPath);
        switch type
            case 'webapp'
                builder = compiler.internal.ui.WebAppAppDesignerScriptBuilder(appPath, reqFiles, images);
                script = builder.getBuildScript(appDetails);
                pkgWindow = compiler.internal.ui.WebAppPackageWindow(appPath, script);
            case 'standalone'
                builder = compiler.internal.ui.StandaloneAppDesignerScriptBuilder(appPath, reqFiles, images);
                script = builder.getBuildScript(appDetails);
                script = append(script, newline, builder.getPackageScript(appDetails));
                pkgWindow = compiler.internal.ui.StandalonePackageWindow(appPath, images, script);
            case 'matlabapp'
                builder = matlab.internal.deployment.MatlabAppDesignerScriptBuilder(appPath, reqFiles, images);
                script = builder.getPackageScript(appDetails);
                pkgWindow = matlab.internal.deployment.MatlabAppPackageWindow(appPath, script);
        end  
        pkgWindow.launch();
    catch ex
        matlab.internal.deployment.AppSharingUtils.handleCommonCompilerErrors(ex, char(varargin{1}));
    ends
end
