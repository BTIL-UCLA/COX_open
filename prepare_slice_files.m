function prepare_slice_files(patient_data, datafolder_name, mask_name , finalfolder_name, delete_data, max_z)
% PREPARE_SLICE_FILES - Convert FLAIR masks into per-slice .mat files
%
%   INPUTS:
%       num_pat         - (integer) Number of patients included after filtering
%       patient_data     - (matrix) Patient-level clinical data (see load_clinical_data)
%       datafolder_name  - (string) Path to the trial data root directory
%       mask_name        - (string) Format of the file names (e.g. 'flairmask_%04d.nii.gz')
%       finalfolder_name - (string) Directory where slice files will be saved
%       delete_data  - (string) 'yes' or 'no'. Delete existing slice files if 'yes'
%       max_z        - (integer) Number of slices in z-dimension (e.g., 182)
%
%   OUTPUTS:
%       - Creates slice_###.mat files in the output folder.
%         Each .mat file contains:
%             var_data(:,:,p) = 2D tumor mask for patient p at slice ###
%
%   NOTES:
%       One .mat file per slice is generated to manage memory usage for 
%       large 3D image datasets.
% 
    num_pat = size(patient_data,1);

    % 1. Recursively delete all slice files
    if strcmp(delete_data,'yes')
        delete(fullfile(finalfolder_name, 'slice_*.mat'));
    end

    tic;
    % 2. Read in FLAIR masks and create 182 files,
    % one per slice (to avoid exceeding the RAM capacity)
    for i = 1:num_pat
        fprintf('Patient %d/%d ...\n', i, num_pat);

        fname = sprintf([datafolder_name '/' mask_name], patient_data(i,1));
        if ~exist(fname,'file')
            warning('File not found: %s', fname);
            continue;
        end

        tempstruct = load_untouch_nii(fname);
        fprintf(fname);
        disp(' > loaded');
        for current_s = 1:max_z
            %var_data = sprintf('pixel_%07d',current_p);
            filename = sprintf([finalfolder_name '/slice_%03d.mat'],current_s);
            if ~exist(filename,'file')
                var_data(:,:,1) = tempstruct.img(:,:,current_s);
                var_data(:,:,2) = zeros(size(tempstruct.img(:,:,current_s)));
                save(filename,'var_data','-v7.3');
                fclose('all');
            else
                try
                    m = matfile(filename,'Writable', true);
                    m.var_data(:,:,i) = tempstruct.img(:,:,current_s);
                catch
                    disp('Error: Using load/save');
                    load(filename);
                    var_data(:,:,i) = tempstruct.img(:,:,current_s);
                    save(filename,'var_data','-v7.3');
                    fclose('all');
                end % try end
            end
        end
    end
    fprintf('Slice preparation completed in %.2f minutes.\n', toc/60);
end