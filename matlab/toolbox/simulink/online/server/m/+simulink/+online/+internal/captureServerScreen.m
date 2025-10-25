function fileFullPath = captureServerScreen(varargin)
    % fileFullPath = simulink.online.internal.captureServerScreen(filename)
    % Utility to take a screenshot of the server-side MATLAB/Simulink on
    % the server-side for Simulink Online
    %    Example:
    %    -----------------------
    %    % create current server screenshot with random name fileFullPath
    %    fileFullPath = captureServerScreen;
    %
    %    % supply your own name
    %    myDir = captureServerScreen('/MATLAB Drive/tmp/capture1.png');

    if ~usejava('jvm') || java.awt.GraphicsEnvironment.isHeadless()
        warning('Screenshots are only supported when MATLAB is running with a JVM and with a display.');
        return
    end

    if nargin == 0
        tname = tempname(filesep);
        filename = [char(datetime('now','Format', 'uuuu-MM-dd''T''HH:mm:ss')),...
            '_', tname(2:10)];
    elseif nargin >= 1 && ischar(varargin{1})
        filename = varargin{1};
    else
        warning('Incorrect Usage');
    end

    fileFullPath = filename;
    if exist('/MATLAB Drive', 'dir') == 7 && ~startsWith(filename, '/MATLAB Drive/')
        % if MATLAB Drive exists but the input does not specify
        fileFullPath = fullfile(pwd, filename);
    elseif exist('/MATLAB Drive', 'dir') ~= 7
        % local file system, use tempdir
        fileFullPath = fullfile(tempdir, filename);
    end

    [d, ~, ex] = fileparts(fileFullPath);
    if exist(d, 'dir') ~= 7
        status = mkdir(d);
        assert(status, ['Cannot create dir at ' d]);
    end
    if isempty(ex)
        fileFullPath = strcat(fileFullPath, '.png');
    end
    size = java.awt.Toolkit.getDefaultToolkit.getScreenSize;
    screen = java.awt.Rectangle(0, 0, size.width, size.height);
    robot = java.awt.Robot;
    image = robot.createScreenCapture(screen);
    file = java.io.File(fileFullPath);
    javax.imageio.ImageIO.write(image, 'png', file);
end