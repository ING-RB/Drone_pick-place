function result = hadoopLoader(query, varargin)

%HADOOPLOADER Loads Hadoop and related JARs on the dynamic class path.
%   HADOOPLOADER uses environment variables to search for Hadoop and
%   detect the Hadoop version. It loads required JAR files into the
%   MATLAB dynamic class path and throws errors if it could not complete
%   successfully.
%
%   To find Hadoop, the following environment variables are checked,
%   and the first environment variable found is used:
%      * MATLAB_HADOOP_INSTALL
%      * HADOOP_PREFIX
%      * HADOOP_HOME
%
%   If the loading of the Hadoop JARs is unsuccessful, subsequent calls
%   to this function retry the loading operation until it succeeds.
%
%   Once the JARs have been successfully loaded, subsequent calls to this
%   function never try to reload the JARs. You must quit the current
%   session of MATLAB to use a different version of Hadoop.
%
%   HADOOPLOADER('load') performs the same action as the no argument
%   version. This will attempt to load the Hadoop JARs onto the classpath.
%
%   TF = HADOOPLOADER('found') returns true if the Hadoop JARs were found
%   and false otherwise.
%
%   HVER = HADOOPLOADER('ver') returns the string containing the Hadoop
%   version found.
%
%   HVER = HADOOPLOADER('classpath') returns a cell array of paths that represent
%   the Hadoop classpath.
%
%   HADOOPLOADER(..., name1, value1, ...) allows the caller to override the
%   discovery with the following name value pairs:
%     * 'HadoopInstallFolder' -  The installation folder of Hadoop.
%     * 'HadoopVersion'       - The string representation of the version of Hadoop.
%     * 'HadoopClasspath'     - a cell array list of jar files or folders that
%                               represents the classpath for Hadoop.

%   Copyright 2018-2024 The MathWorks, Inc.

persistent isLoaded;
persistent hadoopVersion;
persistent hadoopClasspathEntries;
if isempty(isLoaded)
    isLoaded = false;
    hadoopVersion = '';
    hadoopClasspathEntries = {};
end

if nargin == 0
    if isLoaded
        return;
    end
    query = 'load';
end

% ensure we have a jvm
error(javachk('jvm',mfilename));

parameters = iParseParamInputs(varargin{:});

switch lower(query)
    case 'load'
        if isLoaded && ~parameters.Force
            return;
        end
        
        % MLOCK here
        mlock;
        
        if parameters.UseIsolatedClasspath
            % Use the isolated classpath. This is for environments where we
            % need to add Hadoop/HDFS JARs on top of MATLAB. As our
            % dependencies might clash with Hadoop's dependencies, this
            % strategy ensures that Hadoop classes see only Hadoop JARs,
            % even in cases where MATLAB has a clashing JAR on the static
            % classpath.
            [installFolder, versionString, majorVersionNumber, classpathEntries] = iDiscoverHadoopVersionAndClasspath(parameters);
            classpathEntries = [classpathEntries; ...
                iGetAdditionalClasspath(majorVersionNumber); ...
                parameters.AdditionalClasspath];

            isolatedClasspath = com.mathworks.storage.hdfsloader.IsolatedClasspathStrategy(classpathEntries);
            hdfsLoader = com.mathworks.storage.hdfsloader.HdfsLoaderProxy(isolatedClasspath);
            com.mathworks.storage.hdfsloader.GlobalHdfsLoader.set(hdfsLoader);
        else
            % Use MATLAB classpath instead. This is for environments where
            % Hadoop/HDFS JARs are already on the classpath (E.G. deployed
            % into Hadoop/Spark processes)
            installFolder = matlab.io.internal.vfs.hadoop.discoverHadoopInstallFolder();
            % No need to parse the version number.
            versionString = '';
            classpathEntries = parameters.AdditionalClasspath;

            if ~isempty(classpathEntries)
                % turn off warning for doubly specified JARs which can happen in deployed mode
                % when Hadoop is already on the classpath
                warnState = warning('off', 'MATLAB:javaclasspath:jarAlreadySpecified');
                warnCleanup = onCleanup(@()warning(warnState));
                javaaddpath(classpathEntries);
            end
            
            com.mathworks.storage.hdfsloader.GlobalHdfsLoader.set([]);
        end
        
        isLoaded = true;
        hadoopVersion = versionString;
        hadoopClasspathEntries = classpathEntries;
        
        % Make sure 'hadoop.home.dir' is set for Hadoop Shell tools.
        if ~isempty(installFolder)
            java.lang.System.setProperty('hadoop.home.dir', installFolder);
        end
        
    case 'isloaded'
        result = isLoaded;
        
    case 'ver'
        result = hadoopVersion;
        
    case 'classpath'
        result = hadoopClasspathEntries;
        
    otherwise
        if ~ischar(query)
            error(message('MATLAB:virtualfileio:hadooploader:invalidOptionType'));
        else
            error(message('MATLAB:virtualfileio:hadooploader:invalidOption', query));
        end
end


end

% Obtain the list of MathWorks classpath entries for a specific Hadoop version number.
function classPathEntries = iGetAdditionalClasspath(majorVersionNumber)
import matlab.internal.datatypes.warningWithoutTrace;

% Switch to decide which version of our jars to use.
if majorVersionNumber == 1
    serFolder = 'a1.2.1';
    effectiveVersionNumber = 1;
else
    if majorVersionNumber > 3
        warningWithoutTrace(message('MATLAB:virtualfileio:hadooploader:invalidHadoopVersion', majorVersionNumber));
    end
    serFolder = 'a2.2.0';
    effectiveVersionNumber = 2;
end

% find the io JARs
ioJar = {...
    fullfile( matlabroot, 'java', 'jar', 'storage', 'hdfs.2.jar');...
    fullfile(matlabroot, 'java', 'jar', 'storage', 'hdfsloaderthunk.jar');...
    };

% find the serializer JAR
if ~isdeployed
    tshJarDir = fullfile(matlabroot, 'toolbox', 'shared', 'hadoopserializer', 'jar');
else
    tshJarDir = fullfile(matlabroot, 'mcr', 'toolbox', 'shared', 'hadoopserializer', 'jar');
end

serJar = fullfile(tshJarDir, serFolder, computer('arch'), 'hadoopserializer.jar');
if ~exist(serJar, 'file')
    serJar = {fullfile(tshJarDir, serFolder, 'hadoopserializer.jar')};
end

% add the MxArrayWritable JAR
mxJar = fullfile(tshJarDir, serFolder, computer('arch'), 'MxArrayWritable.jar');
if ~exist(mxJar, 'file')
    mxJar = {fullfile(tshJarDir, serFolder, 'MxArrayWritable.jar')};
end

% update JAR files
classPathEntries = [ioJar; serJar; mxJar];

end

% Obtain the version and classpath via either the inputs or discover methods.
function [installFolder, versionString, majorVersionNumber, classpathEntries] = iDiscoverHadoopVersionAndClasspath(parameters)
installFolder = parameters.HadoopInstallFolder;
if isempty(parameters.HadoopInstallFolder) && (isempty(parameters.HadoopVersion) || isempty(parameters.HadoopClasspath))
    installFolder = matlab.io.internal.vfs.hadoop.discoverHadoopInstallFolder();
end

versionString = parameters.HadoopVersion;
if isempty(versionString)
    [versionString, majorVersionNumber] = matlab.io.internal.vfs.hadoop.discoverHadoopVersion(installFolder);
else
    majorVersionNumber = str2double(regexp(versionString, '^\d', 'match', 'once'));
end

classpathEntries = parameters.HadoopClasspath;
if isempty(classpathEntries)
    classpathEntries = matlab.io.internal.vfs.hadoop.discoverHadoopClasspath(installFolder, versionString, majorVersionNumber);
end
end

% Parse the inputs to hadoopLoader
function parameters = iParseParamInputs(varargin)
p = inputParser;
p.addParameter('HadoopInstallFolder', '');
p.addParameter('HadoopVersion', '');
p.addParameter('HadoopClasspath', {});
p.addParameter('AdditionalClasspath', {});
p.addParameter('Force', false);
p.addParameter('UseIsolatedClasspath', iDefaultToIsolatedClasspath());
p.parse(varargin{:});
parameters = p.Results;
end

function tf = iDefaultToIsolatedClasspath()
% Should we use the isolated classpath strategy by default?

% Outside of deployment, yes, as Hadoop JAR dependencies and MATLAB JAR
% dependencies can collide. If MATLAB was first, Hadoop will see different
% upstream JARs to the ones it was compiled against.
tf = true;
if isdeployed
    % If this is a deployed MATLAB running in a Hadoop/Spark process,
    % Hadoop JARs will be on the static classpath. This is the one case
    % where we can turn off isolated classpath, and indeed it is safer to
    % do so.
    try %#ok<TRYNC>
        [~] = com.mathworks.util.ClassLoaderBridge.findClass("org.apache.hadoop.conf.Configuration"); %#ok<JAPIMATHWORKS>
        tf = false;
    end
end
end
