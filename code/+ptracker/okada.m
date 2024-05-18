function IMout = okada(IMin, dim)
%okada Noise filtering using the okada filter
%   IMout = okada(IMin, dim) filters IM using the okada filter on the 
%   dimension specified by DIM
%   
%   Credit to:
%   Okada, M., Ishikawa, T., & Ikegaya, Y. (2016). A Computationally 
%   Efficient Filter for Reducing Shot Noise in Low S/N Data. PloS One
%   https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4909204/


IMout = single(IMin);

IMout = permute(IMout, [dim, setdiff(1:3, dim)]);

[imHeight, imWidth, nFrames] = size(IMout);

for j = 2:imHeight-1
    for i = 1:imWidth
        for t = 1:nFrames
            if (IMout(j,i,t) - IMout(j-1,i,t)) * (IMout(j,i,t) - IMout(j+1,i,t)) > 0
                IMout(j,i,t) = (IMout(j+1,i,t) + IMout(j-1,i,t)) ./ 2;
            end
        end
    end
    
end

% Permute back
if dim == 2
    IMout = permute(IMout, [dim, setdiff(1:3, dim)]);
elseif dim == 3
    IMout = permute(IMout, [2,3,1]);
end

IMout = cast(IMout, 'like', IMin);

end