function BW = getBinarizedImage(IM, options)

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

    % Fill gaps in binary component.
    if options.TrackerOptions.imclose > 1
        n = round(options.TrackerOptions.imclose);
        BW = imclose(BW, strel('disk', n));
    end
end
