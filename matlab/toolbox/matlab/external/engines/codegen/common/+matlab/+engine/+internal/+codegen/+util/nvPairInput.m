function cppconfig = nvPairInput(headerFile, nameValuePairs)
%nvPairInput A Helper function that validates hfile and name-value pair
%style input and outputs a matching config object

arguments
    headerFile (1,1) string
    nameValuePairs.Packages  (:,1) string = []
    nameValuePairs.Classes   (:,1) string = []
    nameValuePairs.Functions (:,1) string = []
    nameValuePairs.Verbose   (1,1) logical = 0
    nameValuePairs.LogFile   (1,1) string = ""
end

cppconfig = matlab.engine.typedinterface.CPPConfig();
cppconfig.HeaderFile = headerFile;
cppconfig.Packages = nameValuePairs.Packages;
cppconfig.Classes = nameValuePairs.Classes;
cppconfig.Functions = nameValuePairs.Functions;
cppconfig.Verbose = nameValuePairs.Verbose;
cppconfig.LogFile = nameValuePairs.LogFile;

end