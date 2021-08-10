function    [painSummary]  = painSummary_REDCap(PATIENTID)
% [redcap_datetimes,redcap_painscores]  = redcap_DL2_RCS(PATIENTID)
%
%  This will import redcap data for RCS patients using Prasad's
%  RedCap API Token for daily surveys
% 
% Took forever to write. 
% Prasad Shirvalkar Oct 9 2019
% Greg C Dec 4 2019 - Added CP1's Daily Pain for RCS, Added option to use
% it to get all the Pain Flucatuation Screening Data.
% Ashlyn S May 1 2020 - Updated RCS01 daily pain
% Update by Ashlyn 3/4/21 with updated API
%
% Adapted from redcap_DL2_RCS for RCS daily reporting data, which was
% adapted from redcap_DL2 for PCS reporting
%
% If you want to get the pain fluctuation data, use 'FLUCT' as the
% PATIENTID. varargout will output the names of the individuals who filled
% out the painscores.

tic 

% Uses REDCap API to fetch redcap pain data based off reportid and
% patientID
disp(['Getting RCS redcap pain data from internets for ' PATIENTID '....'])
 
SERVICE = 'https://redcap.ucsf.edu/api/';
%TOKEN = '581DB97DE99D44DAFD9833E058AE79AB';
TOKEN = '6968847584A81D488985F258537FE6BF'; %updated with tableau connection 3/3/21
 % Report ID determines which report set to load from. (Daily, Weekly, or Monthly)

switch PATIENTID
    
    case 'RCS01'
        PATIENT_ARM = 'rcs01_daily_arm_1';
        reportid = '73191';
    case 'RCS02'
        PATIENT_ARM = 'rcs02_daily_arm_7';
        reportid = '87050';
    case 'FLUCT'
        PATIENT_ARM = 'dbs_and_nondbs_pat_arm_23';
        reportid = '84060';
    case 'RCS01_STREAMING'
        PATIENT_ARM = 'streaming_arm_9';
        reportid = '95083';
    case 'RCS02_STREAMING'
        PATIENT_ARM = 'streaming_arm_5';
        reportid = '80139';
        
end


disp('************************');
disp('Download a file from a subject record');
disp('************************');
data = webwrite(...
SERVICE,...
'token', TOKEN, ...
'content', 'report',...
'report_id',reportid, ...
'format', 'csv',...
'type','flat',...
'rawOrLabelHeaders','raw',...
'exportCheckboxLabel','false',...
'exportSurveyFields','true',...
'returnformat','csv');


alltable = data;

% remove all the extraneous rows ('events' that are different)

keeprows = strcmp(alltable.redcap_event_name, PATIENT_ARM) & ...
                    (arrayfun(@(x) ~isempty(x),alltable.rcs_pain_vasnrs_timestamp) | ...
                    arrayfun(@(x) ~isempty(x),alltable.rcs01_mpq_timestamp));
        
clntable = alltable(keeprows,:);

% if ischar(clntable.cruel_punishing{1})
%      clntable.cruel_punishing = cellfun(@(x) str2double(x),clntable.cruel_punishing);
% end

% Moves redcap timestamps into designated VAS or MPQ segments. Then combines
% into consolidated timestamp structure.

redcap_timestamp.vasnrs =  datetime(clntable.rcs_pain_vasnrs_timestamp);
redcap_timestamp.mpq = datetime(clntable.rcs01_mpq_timestamp);
time_transfer = find(isnat(redcap_timestamp.vasnrs) & ~isnat(redcap_timestamp.mpq));
redcap_timestamp.alltimes = redcap_timestamp.vasnrs;

if ~isnat(redcap_timestamp.vasnrs) == isnat(redcap_timestamp.mpq)
    redcap_timestamp.alltimes(time_transfer) = redcap_timestamp.mpq(time_transfer);
else
    for t = time_transfer
        redcap_timestamp.alltimes(t) = redcap_timestamp.mpq(t);
    end
end

% Populate the new flavors of painscores downloaded from redcap
redcap_painscores.mayoNRS = (clntable.intensity_nrs);
redcap_painscores.painVAS = (clntable.intensity_vas);
redcap_painscores.unpleasantVAS = (clntable.unpleasantness_vas);
  
% take the mcgill pain questionnaires
table_header = clntable.Properties.VariableNames;
mpq_start = find(contains(table_header,'rcs01_mpq_timestamp'))+1;
mpq_end = find(contains(table_header,'cruel_punishing'));

mpqhold = table2array(clntable(:,mpq_start:mpq_end));

redcap_painscores.MPQsum =  nansum((mpqhold),2);
redcap_painscores.MPQthrobbing = (clntable.throbbing);
redcap_painscores.MPQshooting = (clntable.shooting);
redcap_painscores.MPQstabbing = (clntable.stabbing);
redcap_painscores.MPQsharp = (clntable.sharp);
redcap_painscores.MPQcramping = (clntable.cramping);
redcap_painscores.MPQgnawing = (clntable.gnawing);
redcap_painscores.MPQhot_burning = (clntable.hot_burning);
redcap_painscores.MPQaching = (clntable.aching);
redcap_painscores.MPQheavy = (clntable.heavy);
redcap_painscores.MPQtender = (clntable.tender);
redcap_painscores.MPQsplitting = (clntable.splitting);
redcap_painscores.MPQtiring = (clntable.tiring_exhausting);
redcap_painscores.MPQsickening = (clntable.sickening);
redcap_painscores.MPQfearful = (clntable.fearful);
redcap_painscores.MPQcruel = (clntable.cruel_punishing);


    if redcap_painscores.MPQsum == 0 
        redcap_painscores.MPQsum = 'NaN';
    end
    
    if PATIENTID == 'RCS01'
        redcap_painscores.MPQsum(redcap_painscores.MPQsum == 0) = NaN;
    else 
        redcap_painscores.MPQsum = redcap_painscores.MPQsum;
    end

redcap_painscores = struct2table(redcap_painscores);
reportTime = struct2table(redcap_timestamp(:,1));
painSummary = [reportTime(:,1), redcap_painscores]
painSummary = table2timetable(painSummary);
%[redcap_timestamp.vasnrs, redcap_painscores.mayoNRS, redcap_painscores.painVAS, redcap_painscores.unpleasantVAS, redcap_painscores.MPQsum]


% %plot 
% figure
% subplot 311
% %plot(redcap_timestamp.vasnrs,smooth((redcap_painscores.mayoNRS)), 'LineWidth', 1.5, 'color', 'k'); hold on;
% plot(redcap_timestamp.vasnrs,(redcap_painscores.mayoNRS*10), '.', 'MarkerSize', 15, 'color','b'); hold on;
% plot(redcap_timestamp.vasnrs,redcap_painscores.painVAS, '.', 'MarkerSize', 15, 'color','r'); hold on;
% plot(redcap_timestamp.vasnrs,redcap_painscores.MPQsum, '.', 'MarkerSize', 15, 'color','g'); hold off;
% ylabel('NRS, VAS, MPQ')
% title([PATIENTID ' Home Pain Reporting'])

% z = 1;
% VASmean = mean(painSummary.painVAS(z:end));
%     VASstd = std(painSummary.painVAS(z:end));
% NRSmean = mean(painSummary.mayoNRS(z:end));
%     NRSstd = std(painSummary.mayoNRS(z:end));
% MPQmean = mean(painSummary.MPQsum(z:end));
%     MPQstd = std(painSummary.MPQsum(z:end));


set(0,'defaultAxesFontSize',16)
x = datetime(painSummary.vasnrs); %341 % set x = start of dataset of interest
V = std(painSummary.painVAS,'omitnan');
M = std(painSummary.MPQsum,'omitnan');
figure
% subplot 311
% plot(redcap_timestamp.vasnrs(x:(end-1)),(redcap_painscores.mayoNRS(x:(end-1))), '.', 'MarkerSize', 25, 'color','b');
% ylabel('NRS (0-10)')
% ylim([0, 10])
% yticks([0 5 10])
% title([PATIENTID ' Pain Intensity NRS'])
subplot 211
fill([x(161) x(161) x(166) x(166)], [0 100 100 0], 'yellow', 'EdgeColor', 'yellow'); hold on;
fill([x(216) x(216) x(227) x(227)], [0 100 100 0], 'yellow', 'EdgeColor', 'yellow'); hold on;
plot(painSummary.vasnrs,painSummary.painVAS, '.', 'MarkerSize', 20, 'color','black'); hold off;
%plot(x,smooth(movmean(painSummary.painVAS, V,'Endpoints','fill')), 'LineWidth', 2); hold off;

non_nan_indices = isfinite(painSummary.painVAS) & isfinite(x);
date_num = datenum(x(non_nan_indices));
non_nan_pain_vas = painSummary.painVAS(non_nan_indices);

fit_params = polyfit(date_num,non_nan_pain_vas,1);
fit_vals = polyval(fit_params, date_num);

%plot(x(non_nan_indices),fit_vals, 'LineWidth', 1, 'color', 'cyan'); hold off;
%shadedErrorBar(x, mean(painSummary.painVAS), std(painSummary.painVAS), 'lineprops','b'); hold off;
ylabel('VAS (0-100)')
ylim([0 100])
yticks([0 50 100])
title([PATIENTID ' Pain Intensity VAS'])

subplot 212
fill([x(161) x(161) x(166) x(166)], [0 45 45 0], 'yellow', 'EdgeColor', 'yellow'); hold on;
fill([x(216) x(216) x(227) x(227)], [0 45 45 0], 'yellow', 'EdgeColor', 'yellow'); hold on;
plot(painSummary.vasnrs,painSummary.MPQsum, '.', 'MarkerSize', 20, 'color','black'); hold on;
plot(x,smooth(movmean(painSummary.MPQsum, M, 'Endpoints','fill')),'LineWidth', 2); hold off;

non_nan_indices = isfinite(painSummary.MPQsum) & isfinite(x);
date_num = datenum(x(non_nan_indices));
non_nan_pain_mpq = painSummary.MPQsum(non_nan_indices);

fit_params = polyfit(date_num,non_nan_pain_mpq,1);
fit_vals = polyval(fit_params, date_num);

%plot(x(non_nan_indices), fit_vals, 'LineWidth', 1, 'color', 'cyan'); hold off;

%shadedErrorBar(x, mean(painSummary.MPQsum), std(painSummary.MPQsum), 'lineprops','k'); hold off;
ylabel('MPQ Sum (0-45)')
ylim([0, 45])
yticks([0 15 30 45])
title([PATIENTID ' McGill Pain Questionnaire'])

% 
% figure
% subplot 211
% shadedErrorBar(x, mean(painSummary.painVAS), std(painSummary.painVAS), 'lineprops','b'); hold off;
% ylabel('VAS (0-100)')
% ylim([0 100])
% yticks([0 50 100])
% title([PATIENTID ' Pain Intensity VAS'])
% subplot 212
% shadedErrorBar(x, mean(painSummary.MPQsum), std(painSummary.MPQsum), 'lineprops','k'); hold off;
% ylabel('MPQ Sum (0-45)')
% ylim([0, 45])
% yticks([0 15 30 45])
% title([PATIENTID ' McGill Pain Questionnaire'])


% VASmean = mean(redcap_painscores.painVAS(x:end));
%     VASstd = std(redcap_painscores.painVAS(x:end));
% NRSmean = mean(redcap_painscores.mayoNRS(x:end));
%     NRSstd = std(redcap_painscores.mayoNRS(x:end));
% MPQmean = mean(redcap_painscores.MPQsum(x:end));
%     MPQstd = std(redcap_painscores.MPQsum(x:end));
% 
% figure
% shadedErrorBar(redcap_timestamp.vasnrs(x:end), VASmean, VASstd);
% hold on
% shadedErrorBar(redcap_timestamp.vasnrs(x:end),NRSmean, NRSstd);
% hold on
% shadedErrorBar(redcap_timestamp.vasnrs(x:end),MPQmean, MPQstd);
% %%
% figure
% gscatter(redcap_timestamp.vasnrs, mpqhold)




    


toc