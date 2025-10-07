function save_nifti_maps(finalfolder_name, max_z, num_covariates)
% SAVE_NIFTI_MAPS - Save Cox regression results to NIfTI format
%
%   INPUTS:
%       finalfolder_name - (string) Name of the output directory
%       max_z            - (integer) Number of slices (z-dimension)
%       interactions     - (bool) True if interactions are present
%
%   OUTPUTS:
%       - Saves NIfTI images to finalfolder_name:
%           p_map_covariate3/4/5/6.nii.gz
%           Beta_map_covariate3/4/5/6.nii.gz
%           Var_map_covariate4.nii.gz
%           Var_map_covariate6.nii.gz
%           Covar_map_covariates_4_and_6.nii.gz
%
%   NOTES:
%       - This function reconstructs full 3D NIfTI volumes by stacking
%         per-slice .mat files created earlier in the pipeline.
%       - Variance/covariance maps are saved only if an interaction term
%         was modeled.

    % Load template
    template = load_untouch_nii('flairmask_sample.nii.gz');

    % Preallocate NIfTI structs
    p_map_Cov3 = template; 
    p_map_Cov4 = template;
    p_map_Cov5 = template; 
    
    Beta_Cov3 = template; 
    Beta_Cov4 = template;
    Beta_Cov5 = template; 

    if num_covariates == 6
        Beta_Cov6 = template;
        p_map_Cov6 = template;
        Var_Cov4 = template; 
        Var_Cov6 = template;
        Covar_46 = template;
    end

    % Loop through slices
    for s = 1:max_z
        disp(['Creating NIfTI, slice ' int2str(s)]);

        % Load p-map slice
        singleslice_p_map = load(sprintf([finalfolder_name '/p_map/p_mapslice_%03d.mat'], s));    
        p_map_Cov3.img(:,:,s) = singleslice_p_map.singleslice_p_map(:,:,3);
        p_map_Cov4.img(:,:,s) = singleslice_p_map.singleslice_p_map(:,:,4);
        p_map_Cov5.img(:,:,s) = singleslice_p_map.singleslice_p_map(:,:,5);
        
        % Load beta slice
        singleslice_b = load(sprintf([finalfolder_name '/b/bslice_%03d.mat'], s));    
        Beta_Cov3.img(:,:,s) = singleslice_b.singleslice_b(:,:,3);
        Beta_Cov4.img(:,:,s) = singleslice_b.singleslice_b(:,:,4);
        Beta_Cov5.img(:,:,s) = singleslice_b.singleslice_b(:,:,5);
        

        if num_covariates == 6
            p_map_Cov6.img(:,:,s) = singleslice_p_map.singleslice_p_map(:,:,6);
            Beta_Cov6.img(:,:,s) = singleslice_b.singleslice_b(:,:,6);
            % Load variance/covariance slice
            singleslice_vars = load(sprintf([finalfolder_name '/var_covar_cov4_and_cov6/varslice_%03d.mat'], s));    
            Var_Cov4.img(:,:,s) = singleslice_vars.singleslice_vars(:,:,1);
            Var_Cov6.img(:,:,s) = singleslice_vars.singleslice_vars(:,:,2);
            Covar_46.img(:,:,s) = singleslice_vars.singleslice_vars(:,:,3);
        end
    end

    experiment_name = strsplit(finalfolder_name,'/');
    experiment_name = experiment_name{end};
    % Save P maps
    save_untouch_nii(p_map_Cov3, fullfile(finalfolder_name, [experiment_name '_p_map_covariate3.nii.gz']));
    save_untouch_nii(p_map_Cov4, fullfile(finalfolder_name, [experiment_name '_p_map_covariate4.nii.gz']));
    save_untouch_nii(p_map_Cov5, fullfile(finalfolder_name, [experiment_name '_p_map_covariate5.nii.gz']));
    

    % Save Beta maps
    save_untouch_nii(Beta_Cov3, fullfile(finalfolder_name, [experiment_name '_Beta_map_covariate3.nii.gz']));
    save_untouch_nii(Beta_Cov4, fullfile(finalfolder_name, [experiment_name '_Beta_map_covariate4.nii.gz']));
    save_untouch_nii(Beta_Cov5, fullfile(finalfolder_name, [experiment_name '_Beta_map_covariate5.nii.gz']));
    
    
    if num_covariates == 6
        save_untouch_nii(p_map_Cov6, fullfile(finalfolder_name, [experiment_name '_p_map_covariate6.nii.gz']));
        save_untouch_nii(Beta_Cov6, fullfile(finalfolder_name, [experiment_name '_Beta_map_covariate6.nii.gz']));
        % Save Variance/Covariance (if interaction term exists)
        save_untouch_nii(Var_Cov4, fullfile(finalfolder_name, [experiment_name '_Var_map_covariate4.nii.gz']));
        save_untouch_nii(Var_Cov6, fullfile(finalfolder_name, [experiment_name '_Var_map_covariate6.nii.gz']));
        save_untouch_nii(Covar_46, fullfile(finalfolder_name, [experiment_name '_Covar_map_covariates_4_and_6.nii.gz']));
    end
    disp('Done!');
end



