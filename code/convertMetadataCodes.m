function [metaData] = convertMetadataCodes(subjectInfo)
%%
% Takes information from subjectInfo field of DeviceSettings and converts
% codes into human readable information
%
%%
% Subject ID
if isfield(subjectInfo,'ID')
    metaData.subjectID = subjectInfo.ID;
end

% Gender
if isfield(subjectInfo,'Sex')
    switch subjectInfo.Sex
        case 0
            metaData.patientGender = 'Undefined';
        case 1
            metaData.patientGender = 'Male';
        case 2
            metaData.patientGender = 'Female';
        case 3
            metaData.patientGender = 'Intersex';
    end
end

% Handedness
if isfield(subjectInfo,'Handedness')
    switch subjectInfo.Handedness
        case 0
            metaData.handedness = 'Undefined';
        case 1
            metaData.handedness = 'Right';
        case 2
            metaData.handedness = 'Left';
        case 3
            metaData.handedness = 'Ambidextrous';
    end
end

% Type of implanted lead
if isfield(subjectInfo,'ImplantedLeads')
    allLeads = subjectInfo.ImplantedLeads;
    leadTypes = {};
    for iLead = 1:length(allLeads)
        switch subjectInfo.ImplantedLeads(iLead)
            case 0
                leadTypes{iLead} = 'Undefined';
            case 1
                leadTypes{iLead} = 'Medtronic 3387';
            case 2
                leadTypes{iLead} = 'Medtronic 3389';
            case 3
                leadTypes{iLead} = 'Medtronic 3391';
            case 4
                leadTypes{iLead} = 'Medtronic Resume II strip';
            case 5
                leadTypes{iLead} = 'Other';
        end
    end
    metaData.implantedLeads = leadTypes';
end

% Type of extension
if isfield(subjectInfo,'Extensions')
    allExtensions = subjectInfo.Extensions;
    extensionTypes = {};
    for iExtension = 1:length(allExtensions)
        switch subjectInfo.Extensions(iExtension)
            case 0
                extensionTypes{iExtension} = 'Undefined';
            case 1
                extensionTypes{iExtension} = 'Eight contacts on INS side to a single 4-contact connector on the lead side';
            case 2
                extensionTypes{iExtension} = 'Eight contacts on the INS side, split to two 4-contact connectors on the lead side';
        end
    end
    metaData.extensions = extensionTypes';
end

% Lead locations
if isfield(subjectInfo,'LeadLocation')
    allLocations = subjectInfo.LeadLocation;
    leadLocations = {};
    for iLocation = 1:length(allLocations)
        switch subjectInfo.LeadLocation(iLocation)
            case 0
                leadLocations{iLocation} = 'Undefined';
            case 1
                leadLocations{iLocation} = 'Left hemisphere';
            case 2
                leadLocations{iLocation} = 'Right hemisphere';
        end
    end
    metaData.leadLocations = leadLocations';
end

% Lead targets
if isfield(subjectInfo,'LeadTargets')
    metaData.leadTargets = subjectInfo.LeadTargets;
end

% INS implant location
if isfield(subjectInfo,'InsImplantLocation')
    switch subjectInfo.InsImplantLocation
        case 0
            metaData.INSimplantLocation = 'Undefined';
        case 1
            metaData.INSimplantLocation = 'Left chest';
        case 2
            metaData.INSimplantLocation = 'Right chest';
        case 3
            metaData.INSimplantLocation = 'Left abdomen';
        case 4
            metaData.INSimplantLocation = 'Right abdomen';
        case 5
            metaData.INSimplantLocation = 'Left back';
        case 6
            metaData.INSimplantLocation = 'Right back';
        case 7
            metaData.INSimplantLocation = 'Left buttock';
        case 8
            metaData.INSimplantLocation = 'Right buttock';
        case 9
            metaData.INSimplantLocation = 'Other';
    end
end

% Stimulation program name(s)
if isfield(subjectInfo,'ProgramNames')
    metaData.stimProgramNames = subjectInfo.ProgramNames;
end

end