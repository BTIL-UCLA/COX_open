# Cox Regression with Optional Parallelization in MATLAB

## Overview
This MATLAB code performs **voxel-wise Cox proportional hazards regression** on imaging-derived covariates.  
It supports both **serial execution** and **parallel execution** (`parfor`), depending on user choice.  

The primary goal is to generate beta coefficient maps, p-value maps, and (optionally) variance/covariance maps for models with or without an interaction term.  

---

## Features
- Voxel-level survival analysis using `coxphfit`.  
- Flexible covariate specification:
  - Age
  - MGMT status
  - Tumor volume (or treatment assignment, depending on the model)
  - Tumor presence
  - Optional interaction term (e.g., treatment × tumor presence).  
- Parallel processing support:
  - User is prompted at runtime whether to use MATLAB’s **Parallel Computing Toolbox**.  
- Outputs:
  - Beta coefficients (`par_b_temp`)
  - p-values (`par_p_map_temp`)
  - Variance/covariance terms if an interaction covariate is present (`par_var_covar_cov4_and_cov6`).  

---

## Inputs
- **age**: Vector of patient ages.  
- **MGMT**: Vector of MGMT methylation status.  
- **flair_vol**: Vector of FLAIR tumor volumes.  
- **tx**: Vector of treatment assignments.  
- **tumor_array**: Matrix of voxel-level tumor presence data (`nPatients × nVoxels`).  
- **T**: Vector of survival times.  
- **status**: Vector of censoring status (1 = event, 0 = censored).  
- **num_covariates**: Number of covariates (5 or 6 if including interaction).  
- **interaction_var**: String, `'flair_vol'` if swapping covariate roles.  
- **num_vox_thresh**: Number of voxels passing threshold for analysis.  

---

## Outputs
- **par_b_temp**: `num_vox_thresh × num_covariates` array of regression coefficients.  
- **par_p_map_temp**: `num_vox_thresh × num_covariates` array of p-values.  
- **par_var_covar_cov4_and_cov6** (if interaction is included): `num_vox_thresh × 3` array containing:  
  - Variance of covariate 4  
  - Variance of covariate 6  
  - Covariance of covariates 4 and 6  

---

## Usage
1. Ensure you have the **Statistics and Machine Learning Toolbox** and (if using parallel) the **Parallel Computing Toolbox**.  
2. Place your input variables in the workspace (`age`, `MGMT`, `flair_vol`, `tx`, `tumor_array`, `T`, `status`).  
3. Run the script.  
4. You will be prompted:  

