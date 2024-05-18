function [peaks, locs] = findPupilMovements(pupilPosition, varargin)

if iscolumn(pupilPosition); pupilPosition=transpose(pupilPosition); end

opts = struct();
opts.dt = 1/30;
opts.deltaT = 1;
opts.threshStdDPupil = 5;
opts.windowSize = 33;
opts.quantileReset = 0.95; % what percentile considered a fast reset
opts.quantileClass = 0.95; % what percentile to be discretized

opts.removeConsecutive = true;
opts.maxFrequency = 5; % in seconds
opts.useFindpeaks = false;

opts = utility.parsenvpairs(opts, [], varargin{:});


dpupil = pupilPosition((opts.deltaT+1):end)-pupilPosition(1:end-opts.deltaT);
dpupil = horzcat( zeros(1, opts.deltaT) , dpupil / opts.deltaT );


% find st.d. without resets, mark resets as 3x std
idx = abs(dpupil) < quantile( abs(dpupil), opts.quantileReset ) ; 
stdDPupil = nanstd( dpupil( idx ) );
thresh = opts.threshStdDPupil * stdDPupil;
pupilResetIdx0 = abs(dpupil) > thresh;

% RemoveConsecutvive - Filter only the maximum change
pupilResetIdx = pupilResetIdx0;
if opts.removeConsecutive  
    %intv = round( removeConsecutiveWindow / session.dt / 2 );
    intv =  1 / opts.maxFrequency;
    intvbin = intv / opts.dt ;
    idxReset = find(pupilResetIdx0);
    for i=1:length(idxReset)
        idxstart = max( idxReset(i)- round(intvbin/2) ); 
        idxend   = min( idxReset(i)+ round(intvbin/2) ); 
        idxwindow = [ idxstart : idxend ];
        idxwindow(idxwindow < 1) = [];
        idxwindow(idxwindow > length(pupilResetIdx)) = [];
        [~, imax] = nanmax( abs(dpupil(idxwindow)) );   % find biggest displacement within interval
        pupilResetIdx( idxwindow ) = 0;
        pupilResetIdx( idxwindow(imax) ) = 1; 
    end
    %pupilResetIdx = diff([pupilResetIdx 0])==1;
end


% use matlab findpeaks
if opts.useFindpeaks
    intv =  1 / opts.maxFrequency;
    intvbin = intv / opts.dt ;
    [pks,locs] = findpeaks( abs(dpupil),'MinPeakDistance', intvbin, 'MinPeakHeight', thresh);
    pupilResetIdx = false(size(dpupil));
    pupilResetIdx(locs) = true;
end

locs = pupilResetIdx;
peaks = pupilPosition(pupilResetIdx);


end