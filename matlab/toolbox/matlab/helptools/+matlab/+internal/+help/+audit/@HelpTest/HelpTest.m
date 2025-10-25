classdef HelpTest
    %HelpTest Audit files for help text standard conformation
    %   HelpTest will audit the files in its workList and output an array
    %   of fileInformation objects.
    %   HelpTest Properties:
    %   results             - Array of fileInformation objects containing
    %                         test results
    %   currentTestSettings - List of tests used in the runTests method
    %   RecurseFolders      - Recursively check subfolders - default false
    %   RecursePackages     - Recursiely check package folders - default
    %                         true
    %   InspectClasses      - Recurisvely check class folders - default
    %                         true
    %   CheckInternal       - Checks files in +internal folders - default
    %                         true
    %
    %   Methods:
    %   HelpTest - sets RecurseFolder, RecursePackages, InspectClasses, and
    %              CheckInternal as name-value pairs, sets
    %              currentTestSettings, calls createWorkList
    %   testFileList - runs runTests on a list of files and stores results
    %   testFolders - runs runTests on list of folders and stores results
    %   runTests - runs all applicable tests set to true in
    %              currentTestSettings, unless user specifies a specific
    %              test as an input

    %   Copyright 2021 The MathWorks, Inc.

    properties
        Results             % Array of fileInformation objects containing test results
        CurrentTestSettings % Structure of tests used in the runTests method
        RecurseFolders      % Recursively check subfolders - default false
        RecursePackages     % Recursiely check package folders - default true
        InspectClasses      % Recurisvely check class folders - default true
        CheckInternal       % Checks files in +internal folders - default true
    end

    methods
        function obj = HelpTest(NameValueArgs)
            %HelpTest Construct an instance of this class
            %   Accepts Name-Value pairs:
            %      RecurseFolders    - (false) - Recursively check subfolders
            %      RecursePackages   - (true)  - Recursively check package
            %                                   folders
            %      InspectClasses    - (true)  - Recursively check class folders
            %      CheckInternal     - (true)  - Check files in +internal folders
            %      CheckCopyright    - (true) - Check copyright section
            %      CheckLines        - (true) - Check general features of help text
            %      CheckH1           - (true) - Check H1 line section
            %      CheckHref         - (true) - Check for no hardcoded links
            %      CheckSeeAlso      - (true) - Check see also section
            %      CheckNote         - (true) - Check note section

            arguments
                NameValueArgs.RecurseFolders  logical = false
                NameValueArgs.RecursePackages logical = true;
                NameValueArgs.InspectClasses  logical = true;
                NameValueArgs.CheckInternal   logical = true;
                NameValueArgs.CheckCopyright  logical = true;
                NameValueArgs.CheckLines      logical = true;
                NameValueArgs.CheckH1         logical = true;
                NameValueArgs.CheckHref       logical = true;
                NameValueArgs.CheckSeeAlso    logical = true;
                NameValueArgs.CheckNote       logical = true;
            end
            obj.RecurseFolders = NameValueArgs.RecurseFolders;
            obj.RecursePackages = NameValueArgs.RecursePackages;
            obj.InspectClasses = NameValueArgs.InspectClasses;
            obj.CheckInternal = NameValueArgs.CheckInternal;
            obj.CurrentTestSettings = rmfield(NameValueArgs, {'RecurseFolders', 'RecursePackages', 'InspectClasses', 'CheckInternal'});
        end
    end

    methods
        obj = testFileList(obj, fileList)
        obj = testFolders(obj, folders)
        obj = runTests(obj, file)
    end

end