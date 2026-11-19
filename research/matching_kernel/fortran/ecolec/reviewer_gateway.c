#include "mex.h"
#include <limits.h>
#include <math.h>
#include <string.h>

extern void matching_f(int ni, int nm, int nh, int nl,
    const double *const inputs[], double *const outputs[], double rounds, double gamma);

void myriad_uniform(double *values, int n)
{
    mxArray *dims[2] = {mxCreateDoubleScalar(1), mxCreateDoubleScalar(n)};
    mxArray *draws = NULL;
    mexCallMATLAB(1, &draws, 2, dims, "rand");
    memcpy(values, mxGetPr(draws), n * sizeof(*values));
    mxDestroyArray(draws);
    mxDestroyArray(dims[0]);
    mxDestroyArray(dims[1]);
}

void myriad_sample(const int *suppliers, const double *weights, int n, int k, int *draws)
{
    mxArray *args[] = {mxCreateDoubleMatrix(1, n, mxREAL), mxCreateDoubleScalar(k),
                      mxCreateLogicalScalar(true), mxCreateDoubleMatrix(n, 1, mxREAL)};
    mxArray *result = NULL;
    double *population = mxGetPr(args[0]);
    for (int i = 0; i < n; i++) population[i] = suppliers[i];
    memcpy(mxGetPr(args[3]), weights, (size_t)n * sizeof(*weights));
    mexCallMATLAB(1, &result, 4, args, "randsample");
    const double *sample = mxGetPr(result);
    for (int i = 0; i < k; i++) draws[i] = (int)sample[i];
    for (int i = 0; i < 4; i++) mxDestroyArray(args[i]);
    mxDestroyArray(result);
}

double myriad_sum(const double *values, int n)
{
    mxArray *vector = mxCreateDoubleMatrix(1, n, mxREAL), *result = NULL;
    memcpy(mxGetPr(vector), values, (size_t)n * sizeof(*values));
    mexCallMATLAB(1, &result, 1, &vector, "sum");
    double total = mxGetScalar(result);
    mxDestroyArray(vector);
    mxDestroyArray(result);
    return total;
}

double myriad_power(double x, double gamma)
{
    return pow(x, gamma);
}

static void ids(const double *data, int n, int upper)
{
    for (int i = 0; i < n; i++)
        if (!isfinite(data[i]) || data[i] != floor(data[i]) || data[i] < 1 || data[i] > upper)
            mexErrMsgIdAndTxt("myriad:FortranInput", "Invalid country or sector ID.");
}

void mexFunction(int nlhs, mxArray *lhs[], int nrhs, const mxArray *rhs[])
{
    if (nrhs != 33 || nlhs != 17)
        mexErrMsgIdAndTxt("myriad:FortranInput", "Expected 33 inputs and 17 outputs.");
    const double *inputs[31];
    for (int i = 0; i < nrhs; i++)
        if (!mxIsDouble(rhs[i]) || mxIsSparse(rhs[i]) || mxIsComplex(rhs[i]))
            mexErrMsgIdAndTxt("myriad:FortranInput", "Inputs must be dense real doubles.");
    const int ni = (int)mxGetN(rhs[0]), nm = (int)mxGetN(rhs[5]);
    const int nh = (int)mxGetN(rhs[14]), nl = (int)mxGetN(rhs[20]);
    if (ni <= 0 || nm <= 0 || nh <= 0 || nl <= 0 ||
        (long long)ni + nm + nh + nl + 26 > INT_MAX || mxGetScalar(rhs[21]) != 26)
        mexErrMsgIdAndTxt("myriad:FortranInput", "Invalid model dimensions.");
    const mwSize sizes[] = {ni, ni, ni, ni, ni, nm, nm, nm, nm, 62*62*26, ni,
        62*26, ni, 62*26, nh, 62*26, nh, 62*26, 26, 62, nl, 1, ni, nh,
        27*26*62*62, 27*26*62, 27*26*62, 27*26*62, 27*26*62, 26*62, 1, 1, ni};
    for (int i = 0; i < nrhs; i++)
        if (mxGetNumberOfElements(rhs[i]) != sizes[i])
            mexErrMsgIdAndTxt("myriad:FortranInput", "Unexpected input dimensions.");
    for (int i = 0; i < 30; i++) inputs[i] = mxGetPr(rhs[i]);
    inputs[30] = mxGetPr(rhs[32]);
    ids(inputs[4], ni, 62);
    ids(inputs[8], nm, 62);
    ids(inputs[22], ni, 26);
    ids(inputs[23], nh, 26);
    const double rounds = mxGetScalar(rhs[30]), gamma = mxGetScalar(rhs[31]);
    if (!(rounds >= 0) || !isfinite(gamma))
        mexErrMsgIdAndTxt("myriad:FortranInput", "Invalid matching options.");

    double *outputs[22];
    const mwSize lengths[] = {ni, nm, ni, ni, ni, ni, nh, nh, nh, nh, 26, 26, 1, 1};
    const mwSize trade[] = {27, 27, 62};
    for (int i = 0; i < 16; i++) {
        lhs[i] = i < 14 ? mxCreateDoubleMatrix(1, lengths[i], mxREAL)
                        : mxCreateNumericArray(3, trade, mxDOUBLE_CLASS, mxREAL);
        outputs[i] = mxGetPr(lhs[i]);
    }
    const char *fields[] = {"intermediate", "investment", "final", "reconstruction", "sales_i", "sales_m"};
    lhs[16] = mxCreateStructMatrix(1, 1, 6, fields);
    for (int i = 0; i < 6; i++) {
        mxArray *field = mxCreateDoubleMatrix(i < 4 ? 27 : 1, i < 4 ? 27 : (i == 4 ? ni : nm), mxREAL);
        mxSetFieldByNumber(lhs[16], 0, i, field);
        outputs[16+i] = mxGetPr(field);
    }
    matching_f(ni, nm, nh, nl, inputs, outputs, rounds, gamma);
}
