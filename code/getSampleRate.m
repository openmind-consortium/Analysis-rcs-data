function sratesout = getSampleRate(srates)

%%
% Input: Vector of sample rates of each packet from RawDataTD.json
% (Vector of the 'SampleRate' column, after having imported json
% into Matlab table). Typical workflow is to call this function from
% createTimeDomainTable.m. 
%
% Output: sample rate in Hz
%%

if length(unique(srates)) > 1
    warning('you have non uniform sample rates in your data');
else
    sratenum = unique(srates);
    switch sratenum
        case 0
            srate = 250; % sample rate in Hz.
        case 1
            srate = 500;
        case 2
            srate = 1e3;
    end
end
% fprintf('out of %d packets:\n\t%d packets at 250Hz\n\t%d packets at 500Hz\n \t%d packets at 1000Hz\n',...
%     length(srates),...
%     sum((srates==0)),...
%     sum((srates==1)),...
%     sum((srates==2)));
% make sample rates numbers
sratesout = srates;
sratesout(srates==0) = 250;
sratesout(srates==1) = 500;
sratesout(srates==2) = 1000;


end

