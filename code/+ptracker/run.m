function run(videoRef, options)

    if isa(videoRef, 'char') && isfile(videoRef)
        imageStack = imviewer.stack.open(videoRef);
    elseif isa(videoRef, 'imviewer.ImageStack')
        imageStack = videoRef;
    end

    hTracker = ptracker.PupilTracker(imageStack, options);
    hTracker.run()
    
    pupilData = hTracker.PupilData;
            
    if options.Configuration.thetaEye ~= 0
        pupilData = ptracker.rotateResults(pupilData, options);
    end
    
    % Add options to pupildata
    pupilData.options = ptracker.getDatasetParameters(options);    
     
    savePath = options.RunTracker.SavePath;
    save(savePath, '-struct', 'pupilData')

end