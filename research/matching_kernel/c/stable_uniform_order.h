#ifndef STABLE_UNIFORM_ORDER_H
#define STABLE_UNIFORM_ORDER_H
#include <stdint.h>
/* Returns zero on allocation failure, allowing the original sort to run. */
int stable_uniform_order(const double *values, int32_t *indices, int n);
#endif
