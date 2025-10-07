function main_cox_atlas(csvfile_name, datafolder_name, finalfolder_name, num_covariates, interaction_var, load_data, delete_data, use_parallel)
% MAIN_COX_ATLAS - Voxel-wise Cox proportional hazards modeling for atlas-based neuroimaging
%
%   This script performs voxel-wise survival analysis (Cox proportional hazards model) 
%   on preprocessed MRI FLAIR masks and clinical covariates, generating 
%   statistical maps (beta, p-value, variance/covariance) in NIfTI format.
%
%   INPUTS:
%       csvfile_name     - (str) Path to csv file with the data (e.g. '/PatientData/ClinicalData.csv')
%       datafolder_name  - (str) Path to the folder with segmentations (e.g. '/PatientData/Segmentations')
%       finalfolder_name - (str) Name for the output directory (e.g. '/PatientData/Cox_Maps_Results')
%       num_covariates   - (int) 5 or 6: Age, MGMT, Volume, Tx, TumorPresence, Interaction
%       interaction_var  - (str) if num_covariates ==6 then default intearction is 'tx', use 'flair_vol' to change; if num_covariates ==5 then this variable has no use
%       load_data        - (str)'yes' or 'no', whether to regenerate slice files
%       delete_data      - (str)'yes' or 'no', whether to delete old slice files
%       use_parallel     - (str)'yes' or 'no', use MATLAB Parallel toolbox if available
%
%   OUTPUTS:
%       Saves maps (p-values, betas, variance/covariance) as NIfTI files in finalfolder_name/
%             IF no interaction:                    Cov3 = flair_vol;   Cov4 = tx;          Cov5 = tumor presence 
%             IF interaction with Tx:               Cov3 = flair_vol;   Cov4 = tx;          Cov5 = tumor presence; Cov6 = Interaction tx*tumor
%             IF interaction with flair_volume:     Cov3 = tx;          Cov4 = flair_vol;   Cov5 = tumor presence; Cov6 = Interaction flair_volume*tumor
%
%       Saves logs in finalfolder_name/finalfolder_name_log.txt
%
%
%   Author: C. Raymond (UCLA), F. Sanvito (UCLA)
%   Original: April 24, 2018
%   Last revision: Oct 6, 2025

    % -------------------
    % INITIALIZATION
    % -------------------
    addpath(genpath(strrep(mfilename('fullpath'),mfilename,''))); % Add functions 
    if ~exist(finalfolder_name,'dir'), mkdir(finalfolder_name); end

    % Set constants
    threshold = 5;     % Minimum number of patients for voxel analysis
    max_x = 182; max_y = 218; max_z = 182;
    %num_covariates   Age, MGMT, Volume, Tx, TumorPresence, Interaction

    % Turn on diary logging
    log_file = fullfile(finalfolder_name, 'log.txt');
    if exist(log_file,'file'), delete(log_file); end
    diary(log_file);

    % -------------------
    % STEP 1: Load clinical data
    % -------------------
    [patient_data, num_pat] = load_clinical_data(csvfile_name);

    % -------------------
    % STEP 2: Prepare slice files if needed
    % -------------------
    if strcmp(load_data,'yes')
        mask_name = input('Provide the format of the flair mask file names (e.g. flairmask_%04d.nii.gz): ', 's');
        prepare_slice_files(patient_data, datafolder_name, mask_name, finalfolder_name, delete_data, max_z);
    end

    % -------------------
    % STEP 3: Run voxel-wise Cox regression
    % -------------------
    if num_covariates == 6
        [B, p_map, var_map] = run_voxelwise_cox(num_pat,patient_data, finalfolder_name, ...
                                               threshold, max_x, max_y, max_z, ...
                                               num_covariates, use_parallel, interaction_var);
    else
        [B, p_map] = run_voxelwise_cox(num_pat,patient_data, finalfolder_name, ...
                                               threshold, max_x, max_y, max_z, ...
                                               num_covariates, use_parallel, interaction_var);        
    end

    % -------------------
    % STEP 4: Construct NIfTI maps and save
    % -------------------
    save_nifti_maps(finalfolder_name, max_z, num_covariates);

    disp('All processing completed successfully.');
    diary off;
end



