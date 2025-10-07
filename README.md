# Voxel‑wise Cox Regression for Atlas Imaging (MATLAB)

This repository implements a voxel‑wise Cox proportional hazards regression pipeline in MATLAB, designed to map relationships between imaging-derived covariates and survival outcomes. The code accommodates large 3D imaging datasets by slicing into per-slice `.mat` files and supports optional parallelization (via `parfor`) under user control.

---

## Features

- Modular MATLAB functions with clear I/O and documentation  
- Slice-wise processing to avoid memory overload  
- Option to use `parfor` (Parallel Toolbox) or fallback to serial loops  
- Supports interaction terms in Cox model  
- Exports results as NIfTI images (beta maps, p-value maps, variance/covariance maps)  

---

## Repository Structure 

```
/ (root)
  ├── main_cox_atlas.m             ← main function
  ├── load_clinical_data.m         ← function that loads clinical data from csv
  ├── run_voxelwise_cox.m          ← function that runs the Cox model
  ├── save_nifti_maps.m            ← function that saves the outputs as nifti files
  ├── example_csvfile.csv          ← template csv file for clinical data  
  ├── flairmask_sample.nii.gz      ← template NIfTI for geometry
  ├── README.md
  └── (other scripts, utils, sample data)
```

---

## Prerequisites

- MATLAB (version with `coxphfit`)  
- Statistics and Machine Learning Toolbox  
- (Optional) Parallel Computing Toolbox  
- NIfTI I/O library for MATLAB: `load_untouch_nii` / `save_untouch_nii`  

---

## Preparing the data (before running the code):
- Tumor segmentations:
	  - Curate individual patient binary tumor segmentations as NIfTI files, 
	  - Register to the MNI space 1mm isotropic, 
	  - Store all segmentations in a dedicated datafolder
- Clinical information:
	  - Collect patient clinical information (age, MGMT status, tumor volume, treatment arm, and survival) 
	  - Store in a csv file 
	  - Make sure to use the appropriate headers in the csv columns (see the example file)

---

## Usage

1. Open MATLAB in the project folder (so paths resolve).  
2. Run the main function with parameters, for example:

   ```matlab
   csv_path = '/path/to/csv_with_clinical_data.csv';
   datafolder_name = '/path/to/folder_with_nifti_segmentations';
   finalfolder_name = 'Experiment32_Output_Folder';
   num_covariates = 6; or 5;
   interaction_var = 'tx'; (or 'flair_vol');
   load_data = 'yes';
   delete_data = 'yes';
   use_parallel = 'yes';

   main_cox_atlas(csv_path, datafolder_name, finalfolder_name, num_covariates, interaction_var, load_data, delete_data, use_parallel)
   ```

3. if load_data = 'yes', the code will ask for the segmentation_nifti naming convention (via the command window)
    e.g. AVAglio-flairmask_%04d.nii.gz

4. The pipeline proceeds:
   - Load clinical data  
   - (If enabled) Prepare slice `.mat` files  
   - Run voxel-wise Cox modeling (slice by slice)  
   - Save intermediate slice results  
   - Construct full-volume NIfTI maps  

---

## Interpretation of Outputs

The code is structured so that, in case of Interaction Variables, it will flip the order of the covariates so that the interaction (Covariate6) is always between Covariate4 and Covariate5.
     a) IF no interaction:                    Cov3 = flair_vol;   Cov4 = tx;          Cov5 = tumor presence 
     b) IF interaction with Tx:               Cov3 = flair_vol;   Cov4 = tx;          Cov5 = tumor presence;     Cov6 = Interaction tx*tumor
     c) IF interaction with flair_volume:     Cov3 = tx;          Cov4 = flair_vol;   Cov5 = tumor presence;     Cov6 = Interaction flair_volume*tumor

Therefore, the output Beta_map for Covariate4 may refer to Beta_map_Tx (a and b) or Beta_map_TumorVolume (c), depending on which Interaction Variable was chosen. 
The same nomenclature applies to p_value_maps and to variance_maps and covariance_maps.

---

## Function Descriptions & I/O

### `main_cox_atlas(csvfile_name, datafolder_name, finalfolder_name, num_covariates, interaction_var, load_data, delete_data, use_parallel)`

- **Inputs**  
  - `csvfile_name`     - (str) Path to csv file with the clinical data  (e.g. '/PatientData/SurvivalData.csv')
  - `datafolder_name`  - (str) Path to the segmentation nifti files (e.g. '/PatientData/Segmentations')
  - `finalfolder_name` - (str) Name for the output directory
  - `num_covariates`   - (int) `5` or `6`: Age, MGMT, Volume, Tx, TumorPresence, Interaction
  - `interaction_var`  - (str) if num_covariates ==6 then default intearction is 'tx', use 'flair_vol' to change; if num_covariates ==5 then this variable has no use
  - `load_data`        - (str)`'yes'` or `'no'`, whether to regenerate slice files
  - `delete_data`      - (str)`'yes'` or `'no'`, whether to delete old slice files
  - `use_parallel`     - (str)`'yes'` or `'no'`, use MATLAB Parallel toolbox if available

- **Outputs / Effects**  
  - Creates output folder and log file  
  - Invokes submodules to load clinical data, slice preparation, voxel-wise fitting, and NIfTI saving  

---

### `load_clinical_data()`

- Returns `patient_data` (matrix) and `num_pat`  
- The CSV is expected to include columns such as:  
  `PatientID, SiteID, Age, Status, OS, Volume, Tx, MGMT`  
  (see the template csv file)

---

### `run_voxelwise_cox(patient_data, outdir, threshold, max_x, max_y, max_z, num_covariates, use_parallel)`

- **Inputs**  
  - `patient_data` : clinical matrix  
  - `outdir` : output directory (where `slice_###.mat` are stored)  
  - `threshold` : minimal number of nonzero patients per voxel  
  - `max_x, max_y, max_z` : 3D volume dimensions  
  - `num_covariates` : e.g. `5` or `6` (if including interaction)  
  - `use_parallel` : `'yes'` or `'no'` for `parfor`  

- **Outputs / Effects**  
  - Saves per-slice files:
    - `b/bslice_###.mat` (beta maps per slice)  
    - `p_map/p_mapslice_###.mat` (p-value maps per slice)  
    - `var_covar_cov4_and_cov6/varslice_###.mat` (variance & covariance)  
  - Attempts to assemble full 4D arrays `B`, `p_map`, `var_map`:
    - If memory allows, returns them  
    - Otherwise returns empty arrays and relies on per-slice files  

---

### `save_nifti_maps(outdir, max_z, [B, p_map, var_map])`

- **Inputs**  
  - `outdir` : output directory containing slice result folders  
  - `max_z` : number of slices  
  - (Optional) `B, p_map, var_map` as 4D arrays  
    - If supplied, writes NIfTI directly from them  
    - Otherwise rebuilds volumes slice-by-slice from `.mat` files  

- **Outputs / Effects**  
  - Generates NIfTI images in `outdir`:
    - `p_map_covariate3.nii.gz` … `p_map_covariate6.nii.gz`  
    - `Beta_map_covariate3.nii.gz` … `Beta_map_covariate6.nii.gz`  
    - `Var_map_covariate4.nii.gz`, `Var_map_covariate6.nii.gz`,  
      `Covar_map_covariates_4_and_6.nii.gz`  

---

## Example Workflow

```text
[User runs main_cox_atlas]
 → (optional) delete and create slice files
 → slice-by-slice Cox regression
 → per-slice `.mat` files saved
 → reconstruct & export NIfTI volumes
```

You can visualize this as:

```
Clinical CSV & FLAIR masks
        ↓
   Slice preparation (.mat files)
        ↓
   Voxel-wise Cox fitting (per slice)
        ↓
   Save per-slice results (beta, p, varcov)
        ↓
   Reconstruct NIfTI volumes → Beta, P‑map, Variance/Covariance
```

---

## Tips & Considerations

- Make sure your template NIfTI (`flairmask_sample.nii.gz`) matches the spatial dimensions and orientation of your data.
- Make sure your template csv (`example_csvfile.csv`) matches the structure and header names of your data.
- Use `use_parallel = 'yes'` only if Parallel Computing Toolbox is installed.
- Remember the nomenclature convention for the output files (see Interpretation of Outputs, above) 
- For debugging, try on a subset of slices or voxels first.  
- Inspect logs in the output folder to track progress or issues.
- You may silence the Warnings by typing `warning off;` in the command window, before running the main function

---

## License & Citation

This project is licensed under the Apache License 2.0 — see the LICENSE file for details.

Please cite this code if used in your publications, as well as the original article:
    Sanvito F, Raymond C, Telesca D, Yao J, Abrey LE, Garcia J, Simmons B, Chinot O, Saran F, Nishikawa R, Henriksson R, Mason WP, Wick W, Cloughesy TF, Ellingson BM.
    "Framework for statistical parametric mapping of impact of tumor location, treatment arm, prognostic variables, and survival using a randomized phase 3 trial of newly diagnosed glioblastoma" 
