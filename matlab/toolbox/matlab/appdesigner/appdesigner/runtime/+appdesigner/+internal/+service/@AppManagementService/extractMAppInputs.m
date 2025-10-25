function [options, inputArgs] = extractMAppInputs(app, args)
    % plain-text app files expect an optional AppOptions final argument, if none was supplied
    % create it, and extract the app input arguments as well.

%   Copyright 2024 The MathWorks, Inc.

    if isempty(args) || ~isa(args{end}, 'appdesigner.internal.apprun.AppOptions')
        opts = appdesigner.internal.apprun.AppOptions();
        opts.Filepath = which(class(app));
        args{end+1} = opts;
    end

    if isscalar(args)
        inputArgs = {};
    else
        inputArgs = args(1:end-1);
    end

    options = args{end};
end
