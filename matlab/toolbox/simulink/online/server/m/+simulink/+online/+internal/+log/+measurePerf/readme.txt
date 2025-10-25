######################### READ ME ###########################

1. Insert the action functions into the folder "actionFunctions"

(create the folder in local directory if there isn't one).

There are four types of action functions:

    (a) Action function: the function that control a series of designated operations
    in a model of simulink online. It's used as a tool to measure network delay.
    (b) Pre-action function: prep works you want to do before performing actions. 
    e.g. open the simulink online. "simulink.online.internal.start"
    (c) Exception action function: the exception needs to be performed when the 
    perfcounter didn't record the time information desired.
    (d) Post action function: what to cope with for the aftermath.

User can choose to fill with function information or not to. If there is no
action function inserted, measurePerf will automatically assign a doNothing
Function as placeholder.

2. Put the configuration file in the folder "configurations" 

(create the folder in local directory if there isn't one).

    The names in the fields of actionFunctions must be same as functions name in 
    the folder "actionFunctions" without extensions.

    (a) User shall not put special characters into fields of configuration.
    (b) Choices of testNames cannot be same.
    (c) In order to do series comparison, two tests need to set to the same action time.
    (d) Action Time. User can input estimated action time. 

    User needs to estimate an action time. It may vary over different regions and 
    current network conditions.

    Action time will be used to calculate the logTime ---> logTime = 2*actionTime.

    More info about the simulink.online.internal.log.perf:
    https://confluence.mathworks.com/pages/viewpage.action?spaceKey=SLOL&title=Simulink+Online+perf+data+log#SimulinkOnlineperfdatalog-RequirementsAnalysisChecklist

3. Use "start" to start job with argv to be the path of the configuration file.

command used in MATLAB window:
simulink.online.internal.log.measurePerf.start("xxx.json")

4. Don't minimize the model window while running the recorder!

5. The recorder will record the current UTC time. 

