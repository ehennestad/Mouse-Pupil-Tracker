function S = getDatasetParameters(appSettings)            
% Get some parameters from the full settings struct of the app

S = struct;
S.thetaEye = appSettings.Configuration.thetaEye;
S.initialCenterPos = appSettings.Configuration.centerPos;
S.eyeCornerCoordinates = appSettings.Configuration.eyeCoordinates;
S.imageSizeXY = appSettings.Configuration.imageSizeXY;

end