function openFilterDiagram(diagramTag)
rootPath =  fullfile(matlabshared.sensors.getSensorRootDir,'+matlabshared','+sensors','+simulink','+internal');
switch diagramTag
    case  'lsm6ds3AccelFilter'
        imgPath= fullfile(rootPath,'lsm6ds3AccelFilter.png');
    case  'lsm6dslGyroFilter'
        imgPath= fullfile(rootPath,'lsm6dslGyroFilter.png');
end
imgPath = '';
X = imread(imgPath);
imshow(X,'border','tight');
end