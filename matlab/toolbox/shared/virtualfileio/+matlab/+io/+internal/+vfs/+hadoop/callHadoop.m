function [varargout] = callHadoop(hadoopInstallFolder, varargin)
%CALLHADOOP Helper function around calling Hadoop that ensures JAVA_HOME is set.
%
% Syntax:
%    [status, message] = callHadoop(hadoopInstallFolder, arguments)
%

%   Copyright 2018-2021 The MathWorks, Inc.

target = fullfile(hadoopInstallFolder, 'bin', 'hadoop');

if isempty(getenv('JAVA_HOME'))
    javaHome = char(java.lang.System.getProperty("java.home"));

    if ispc
        % For Windows, use the Windows shortname format and remove spaces
        % from the installation path.
        [~, javaHome] = system("for %A in (""" + javaHome + """) do @echo %~sA");
        javaHome = strip(javaHome);
        % For Windows, setting JAVA_HOME to '' is equivalent to unset.
        setenv('JAVA_HOME', char(javaHome));
        envCleanup = onCleanup(@()setenv('JAVA_HOME', ''));
    else
        % For Unix, we do everything using an intermediate script in case
        % JAVA_HOME was previously unset.
        varargin = [{javaHome, target}, varargin];
        target = fullfile(toolboxdir('shared'), 'virtualfileio', 'bin', 'callhadoop.sh');
    end
end

% This is required to prevent stdin corrupting the output (g1267942)
% and is recommended by the documentation for system on unix.
if ~ispc
    varargin = [varargin, {'< /dev/null'}];
end

cmd = strjoin([{sprintf('"%s"', target)}, varargin], ' ');
[varargout{1:nargout}] = system(cmd);
