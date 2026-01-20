#!/usr/bin/env python3
"""
Voxel-wise Combined P-Value Computation for Cox Regression Coefficients

This script computes voxel-wise p-values for the sum of two Cox regression
coefficients (e.g., a main effect and its interaction term) by:
- calculating the voxel-wise variance of the sum of coefficients 
(using the variance and covariance of the coefficients)
- calculating p from the sum of beta and its calculated variance
(following the procedure described by Rosner)

The method follows from the textbook approach to calculating p from beta and variance 
and is adapted here for voxel-wise neuroimaging analyses.

Author: Francesco Sanvito
Affiliation: UCLA Brain Tumor Imaging Laboratory (BTIL)
Last revised: 2026-01-15
"""

import argparse
import numpy as np
import nibabel as nib
from scipy.stats import t


# -------------------------------------------------------------------------
# I/O utilities
# -------------------------------------------------------------------------

def load_nifti(path):
    """Load a NIfTI file and return its data array."""
    return nib.load(path).get_fdata()


def save_nifti(data, output_path, reference_path):
    """
    Save a NIfTI image using the affine and header from a reference image.
    """
    ref_img = nib.load(reference_path)
    out_img = nib.Nifti1Image(data, ref_img.affine, ref_img.header)
    nib.save(out_img, output_path)


# -------------------------------------------------------------------------
# Core computation
# -------------------------------------------------------------------------

def compute_combined_pvalue(beta1, beta2, var1, var2, cov12, df):
    """
    Compute the voxel-wise p-value for the sum of two regression coefficients.

    Parameters
    ----------
    beta1, beta2 : ndarray
        Voxel-wise beta coefficient maps.
    var1, var2 : ndarray
        Voxel-wise variance maps of the coefficients.
    cov12 : ndarray
        Voxel-wise covariance map between the two coefficients.
    df : int
        Degrees of freedom (n - k - 1).

    Returns
    -------
    ndarray
        Voxel-wise two-sided p-value map.
    """
    var_sum = var1 + var2 + 2.0 * cov12  # variance of the (beta4+beta6) coefficient

    # Guard against invalid variance
    var_sum[var_sum <= 0] = np.nan

    se_sum = np.sqrt(var_sum)   # Standard Error of the sum of betas
    beta_sum = beta1 + beta2    # Sum of the betas
    t_stat = beta_sum / se_sum  # t statistic of the sum of betas

    # calculate p-value
    p_value_with_nans = 2.0 * (1.0 - t.cdf(np.abs(t_stat), df))     
    # *2 ensures two-tailed, and I checked it is consistent with the p values output from the matlab Cox model
    
    # Nan cleaning
    p_value_no_nans = np.nan_to_num(p_value_with_nans, nan=0)     
    # zeroes out any nan value, which in our experiment only maps outside the brain 
    # -- Reminder: check that these instances do not ever map inside the brain and are not falsely interpreted as p<0.05

    return p_value_no_nans


# -------------------------------------------------------------------------
# Main execution
# -------------------------------------------------------------------------

def main(args):
    df = args.n_obs - args.n_predictors - 1

    beta_4 = load_nifti(args.beta4)
    beta_6 = load_nifti(args.beta6)
    var_4 = load_nifti(args.var4)
    var_6 = load_nifti(args.var6)
    cov_46 = load_nifti(args.cov46)

    # Sanity check
    if not (beta_4.shape == beta_6.shape == var_4.shape ==
            var_6.shape == cov_46.shape):
        raise ValueError("Input NIfTI files must have identical dimensions.")

    p_map = compute_combined_pvalue(beta_4, beta_6, var_4, var_6, cov_46, df)

    save_nifti(p_map, args.output, args.beta4)


if __name__ == "__main__":
    parser = argparse.ArgumentParser( description="Compute voxel-wise p-values corresponding to the sum of beta coefficients of two variables (i.e., one variable and one interaction term).")

    parser.add_argument("--beta4", required=True,
                        help="NIfTI map of beta coefficient for one of the variables (e.g. beta4 for the 4th variable of the model)")
    parser.add_argument("--beta6", required=True,
                        help="NIfTI map of beta coefficient for the other variable, typically the interaction variable (e.g. beta6 for the 4th variable of the model)")
    parser.add_argument("--var4", required=True,
                        help="NIfTI map of variance of the beta coefficient for one of the variables (e.g. beta4 for the 4th variable of the model)")
    parser.add_argument("--var6", required=True,
                        help="NIfTI map of variance variance of the beta coefficient for the other variable, typically the interaction variable (e.g. beta6 for the 4th variable of the model)")
    parser.add_argument("--cov46", required=True,
                        help="NIfTI map of covariance of the beta coefficients for the two variables of interest, extracted from the covariance matrix of the cox model at each voxel")
    parser.add_argument("--n_obs", type=int, required=True,
                        help="Number of observations (subjects)")
    parser.add_argument("--n_predictors", type=int, required=True,
                        help="Number of predictors in the Cox model, including all covariates and interaction term and also including the intercept (e.g. 7 if the model has 5 covariates, the interaction term, and the intercept)")
    parser.add_argument("--output", required=True,
                        help="Output NIfTI path for the voxelwise combined p-values map")

    main(parser.parse_args())
