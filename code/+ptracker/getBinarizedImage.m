function BW = getBinarizedImage(IM, options)

    % Store original image for contrast check
    IM_original = IM;
    
    % Calculate threshold based on percentile level
    prctLevel = options.TrackerOptions.threshold;
    T = prctile(IM(:), prctLevel);

    % Crop image if cropping is specified
    if ~isempty(options.Configuration.cropCoordinates)
        origSize = size(IM);
        rcc = options.Configuration.cropCoordinates;
        IM = IM(rcc(2):rcc(2)+rcc(4), rcc(1):rcc(1)+rcc(3));
    end
    
    
    % Threshold image:
    switch options.Configuration.pupilPolarity
        case 'dark'
            BW = IM<T;
        case 'bright'
            BW = IM>T;
    end

    % Expand image if it was cropped
    if ~isempty(options.Configuration.cropCoordinates)
        fullBW = false(origSize);
        fullBW(rcc(2):rcc(2)+rcc(4), rcc(1):rcc(1)+rcc(3)) = BW;
        BW = fullBW; clear fullBW
    end
    
    
    % Analyze / remove detected binary components:
    CC = bwconncomp(BW);

    if options.TrackerOptions.removeObjectsSmallerThan > 1

        areas = cellfun(@numel, CC.PixelIdxList);
        throw = areas < options.TrackerOptions.removeObjectsSmallerThan;
        BW(cat(1, CC.PixelIdxList{throw} )) = 0;

        CC.PixelIdxList = CC.PixelIdxList(~throw);
    end
    

    % Select component where the pupil center is contained:
    pupilCenter = round( options.Configuration.centerPos );
    
    % Check if pupil footprint is defined
    footprintCenter = options.Configuration.pupilFootprintCenter;
    footprintRadius = options.Configuration.pupilFootprintRadius;
    hasFootprint = ~any(isnan(footprintCenter)) && ~isnan(footprintRadius);
    
    if hasFootprint
        % Use footprint strategy: select component whose center of mass is within the footprint circle
        if ~isempty(CC.PixelIdxList)
            isMatch = false(1, numel(CC.PixelIdxList));
            
            for i = 1:numel(CC.PixelIdxList)
                [rows, cols] = ind2sub(size(BW), CC.PixelIdxList{i});
                com = [mean(cols), mean(rows)]; % center of mass [x, y]
                
                % Check if center of mass is within footprint circle
                dist = sqrt(sum((com - footprintCenter).^2));
                if dist <= footprintRadius
                    isMatch(i) = true;
                end
            end
            
            % If multiple components match, select the largest one
            if sum(isMatch) > 1
                areas = cellfun(@numel, CC.PixelIdxList(isMatch));
                [~, maxIdx] = max(areas);
                matchIndices = find(isMatch);
                isMatch(:) = false;
                isMatch(matchIndices(maxIdx)) = true;
            end
            
            BW(cat(1, CC.PixelIdxList{~isMatch} )) = 0;
        end
        
    elseif all(~isnan(pupilCenter))
        % Use original strategy: select component that contains the pupil center point
        IND = sub2ind(size(BW), pupilCenter(2), pupilCenter(1));
        isMatch = cellfun(@(c) ismember(IND,c), CC.PixelIdxList);
        BW(cat(1, CC.PixelIdxList{~isMatch} )) = 0;
    end

    % Check contrast to detect occlusion
    if options.TrackerOptions.minContrast > 0 && any(BW(:))
        % Calculate mean intensity in pupil region and surrounding area
        pupilMask = BW;
        
        % Create a dilated mask for the surrounding region
        se = strel('disk', round(5)); % 5 pixel border around pupil
        surroundMask = imdilate(pupilMask, se) & ~pupilMask;
        
        % If there's not enough surrounding region, skip contrast check
        if sum(surroundMask(:)) > 10
            % Use original uncropped image for contrast check
            meanPupil = mean(IM_original(pupilMask));
            meanSurround = mean(IM_original(surroundMask));
            
            % Calculate contrast ratio (normalized by surround to handle brightness changes)
            % For dark pupil: surround should be brighter
            % For bright pupil: surround should be darker
            switch options.Configuration.pupilPolarity
                case 'dark'
                    contrast = (meanSurround - meanPupil) / meanSurround;
                case 'bright'
                    contrast = (meanPupil - meanSurround) / meanPupil;
            end
            
            % If contrast is too low, reject detection (likely occluded)
            if contrast < options.TrackerOptions.minContrast
                BW(:) = false; % Clear the detection
            end
        end
    end

    % Fill gaps in binary component.
    if options.TrackerOptions.imclose > 1
        n = round(options.TrackerOptions.imclose);
        BW = imclose(BW, strel('disk', n));
    end
end
