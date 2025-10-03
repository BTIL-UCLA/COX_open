# Voxel‑wise Cox Regression for Atlas Imaging (MATLAB)

This repository implements a voxel‑wise Cox proportional hazards regression pipeline in MATLAB, designed to map relationships between imaging-derived covariates and survival outcomes. The code accommodates large 3D imaging datasets by slicing into per-slice `.mat` files and supports optional parallelization (via `parfor`) under user control.

---

## Features

- Modular MATLAB functions with clear I/O and documentation  
- Interactive file selection for clinical CSV  
- Slice-wise processing to avoid memory overload  
- Option to use `parfor` (Parallel Toolbox) or fallback to serial loops  
- Supports interaction terms in Cox model  
- Exports results as NIfTI images (beta maps, p-value maps, variance/covariance maps)  

---

## Repository Structure (suggested)

```
/ (root)
  ├── main_cox_atlas.m
  ├── load_clinical_data.m
  ├── run_voxelwise_cox.m
  ├── save_nifti_maps.m
  ├── flairmask_sample.nii.gz     ← template NIfTI for geometry
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

## Usage

1. Open MATLAB in the project folder (so paths resolve).  
2. Run the main function with parameters, for example:

   ```matlab
   prefix = '/path/to/data/';
   output_name = 'Experiment32_Output';
   load_data = 'yes';
   delete_data = 'yes';
   use_parallel = 'yes';

   main_cox_atlas(prefix, output_name, load_data, delete_data, use_parallel)
   ```

3. On startup, the code will prompt you to pick the clinical CSV file via a file dialog.  
4. The pipeline proceeds:
   - Load clinical data  
   - (If enabled) Prepare slice `.mat` files  
   - Run voxel-wise Cox modeling (slice by slice)  
   - Save intermediate slice results  
   - Construct full-volume NIfTI maps  

---

## Function Descriptions & I/O

### `main_cox_atlas(prefix, finalfolder_name, load_data, delete_data, use_parallel)`

- **Inputs**  
  - `prefix` : root path to imaging & script resources  
  - `finalfolder_name` : name of output folder (created within prefix)  
  - `load_data` : `'yes'` or `'no'`, whether to regenerate slice files  
  - `delete_data` : `'yes'` or `'no'`, whether to remove existing slice files  
  - `use_parallel` : `'yes'` or `'no'` to toggle `parfor` usage  

- **Outputs / Effects**  
  - Creates output folder and log file  
  - Invokes submodules to load clinical data, slice preparation, voxel-wise fitting, and NIfTI saving  

---

### `load_clinical_data()`

- Prompts user with file selection dialog to pick the clinical CSV  
- Returns `patient_data` (matrix) and `num_pat`  
- The CSV is expected to include columns such as:  
  `PatientID, SiteID, Age, Status, OS, Volume, Tx, MGMT`  

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
 → choose CSV via dialog
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
- Use `use_parallel = 'yes'` only if Parallel Computing Toolbox is installed.  
- For debugging, try on a subset of slices or voxels first.  
- Inspect logs in the output folder to track progress or issues.  

---

## License & Citation

Please include appropriate licensing (e.g. MIT, BSD) and cite this code if used in your publications.
