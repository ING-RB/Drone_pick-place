classdef XMLPlugin < matlab.unittest.plugins.TestRunnerPlugin & ...
                     matlab.unittest.internal.plugins.HasOutputStreamMixin
    % XMLPlugin - Plugin to produce test results in XML format
    %
    % The XMLPlugin allows one to configure the TestRunner to produce JUnit
    % style XML output. When the test output is produced using this format,
    % MATLAB Unit Test results can be integrated into other third party
    % systems that understand JUnit style XML. For example, using this
    % plugin MATLAB Unit tests can be integrated into continuous
    % integration systems like <a href="http://jenkins-ci.org/">Jenkins</a>TM or <a href="http://www.jetbrains.com/teamcity">TeamCity</a>(R).
    %
    %   XMLPlugin Methods:
    %       producingJUnitFormat - Construct a plugin that produces JUnit Style XML.
    %
    %   Examples:
    %       import matlab.unittest.TestRunner;
    %       import matlab.unittest.TestSuite;
    %       import matlab.unittest.plugins.XMLPlugin;
    %
    %       % Create a TestSuite array
    %       suite   = TestSuite.fromClass(?mynamespace.MyTestClass);
    %       % Create a test runner
    %       runner = TestRunner.withTextOutput;
    %
    %       % Add an XMLPlugin to the TestRunner
    %       xmlFile = 'MyXMLOutput.xml';
    %       plugin = XMLPlugin.producingJUnitFormat(xmlFile);
    %       runner.addPlugin(plugin);
    %
    %       result = runner.run(suite);
    %
    %       disp(fileread(xmlFile));

	% Copyright 2015-2023 The MathWorks, Inc. 
    
    methods(Hidden, Access=protected)
        function plugin = XMLPlugin(varargin)
            plugin = plugin@matlab.unittest.internal.plugins.HasOutputStreamMixin(varargin{:});
        end
    end
    
    methods(Static)
        function plugin = producingJUnitFormat(varargin)
            % producingJUnitFormat - Construct a plugin that produces JUnit Style XML Output.
            %   
            %   PLUGIN = XMLPlugin.producingJUnitFormat('XMLFILENAME') returns a plugin that
            %   produces JUnit style XML output. This output is printed to the file <XMLFILENAME>.
            %   Every time the suite is run with this plugin, the XML file is overwritten.
            %
            %   PLUGIN = XMLPlugin.producingJUnitFormat(...,'OutputDetail',OUTPUTDETAIL)
            %   creates a XMLPlugin that displays events with the amount of output
            %   detail specified by OUTPUTDETAIL. OUTPUTDETAIL is specified as a
            %   matlab.unittest.Verbosity enumeration object. By default, events are
            %   displayed at the Verbosity.Detailed level.
            %
            %   Examples:
            %       import matlab.unittest.plugins.XMLPlugin;
            %       import matlab.unittest.Verbosity;
            %
            %       % Create a XML plugin that sends XML Output to a file
            %       plugin = XMLPlugin.producingJUnitFormat('MyXMLFile.xml');
            %
            %       % Create a XML plugin that produces a concise amount of output detail
            %       plugin = XMLPlugin.producingJUnitFormat('MyXMLFile.xml', ...
            %           'OutputDetail',Verbosity.Concise);
            %
            %   See also:
            %       matlab.unittest.Verbosity
            
            plugin = matlab.unittest.plugins.xml.JUnitXMLOutputPlugin(varargin{:});
        end
    end
end


% LocalWords:  jenkins ci jetbrains teamcity mynamespace XMLFILENAME OUTPUTDETAIL
