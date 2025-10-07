function [patient_data, num_pat] = load_clinical_data(csvfile_name)
% LOAD_CLINICAL_DATA - Load patient demographics and clinical variables
%
%   INPUTS:
%       csvfile_name - (str) Path to csv file with the data or empty string to selectect it ''.
%                
%
%   OUTPUTS:
%       patient_data - (matrix) Patient-level data from CSV file:
%                      Columns: [PatientID, SiteID, Age, Status, OS, Volume, Tx, MGMT]
%                          PatientID   = Unique patient identifier
%                          SiteID      = Trial site ID
%                          Age         = Patient age (years)
%                          Status      = 1 if alive (censored), 0 if death observed
%                          OS          = Overall survival time (days)
%                          Volume      = Baseline tumor volume (ml)
%                          Tx          = Treatment arm (0/1)
%                          MGMT        = MGMT methylation status
%
%       num_pat     - (integer) Number of patients included after filtering
%
%   NOTES:
%       Excludes patients with missing OS (overall survival)

    % Open file dialog
    if isempty(csvfile_name)
        [file, path] = uigetfile('*.csv', 'Select the clinical CSV file',csvfile_name);
        if isequal(file,0)
            error('No file selected. Function aborted.');
        end
        filename = fullfile(path, file);
    else
        filename = csvfile_name;
    end

    % Load data
    % orig_data = csvread(filename);
    opts = detectImportOptions(filename, 'NumHeaderLines', 0);
    T = readtable(filename, opts);

    % Extract variables (assuming column names are standard)
    PatientID = T.PatientID;
    SiteID    = T.SiteID;
    Age       = T.Age;
    Status    = T.Status;
    OS        = T.OS;
    Volume    = T.Volume;
    Tx        = T.Tx;
    MGMT      = T.MGMT;

    % Combine into matrix
    patient_data = [PatientID, SiteID, Age, Status, OS, Volume, Tx, MGMT];

    % Remove rows with missing OS
    valid_idx = ~isnan(OS);
    patient_data = patient_data(valid_idx,:);
    num_pat = size(patient_data,1);    
    fprintf('Loaded %d patients.\n', num_pat);
end